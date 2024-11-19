function fitResults = fitDataBasedOnSweepMode(sweepMode, FolderPath)
    % Get all files in the current directory that match the 
    %   format 'Field_*Oe.txt'.
    files = dir(fullfile(FolderPath, sweepMode, '*.txt'));
    % Extract and sort the serial number in the file name
    fileOrder = zeros(length(files), 1);
    for i = 1:length(files)
        % Extracting serial numbers from filenames using regular expressions
        % disp(['Processing files: ', files(i).name]);
        pattern = 'Field_(-?\d+)Oe.txt';
        matches = regexp(files(i).name, pattern, 'tokens');
        if ~isempty(matches)
            % Convert serial numbers to numbers and store
            fileOrder(i) = str2double(matches{1});
        else
            error('Serial number in filename not found');
        end
    end
    % Sort by serial number of extraction
    [~, sortedIdx] = sort(fileOrder);
    sortedFiles = files(sortedIdx);
    % Initialize the structure that stores the fitting results
    fitResults = struct();
    % Define transition width threshold for dy_dx
    transitionThreshold = 300; % Adjust this threshold as needed
    windowSize = 1e-5; % Define a threshold for width
    
    % Iterate through all documents
    for i = 1:length(sortedFiles)
        flagm = 0;
        flagp = 0;
        % Read file name
        fileName = sortedFiles(i).name;
        % Read file data
        data = readmatrix(fullfile(FolderPath, sweepMode, fileName));
        
        % Specify the range of data rows to be fitted
        rowRangem = data(:,2) < 100 & data(:,1) < 0; % to fit the Icm
        rowRangep = data(:,2) < 100 & data(:,1) >= 0; % to fit the Icp
        
        % Extract current and voltage data
        xm = data(rowRangem, 1);
        ym = data(rowRangem, 2);
        xp = data(rowRangep, 1);
        yp = data(rowRangep, 2);
        
        % Calculate dy_dx for determining transition width
        dy_dx_m = gradient(ym) ./ gradient(xm);
        dy_dx_p = gradient(yp) ./ gradient(xp);
        
        % Find transition regions based on threshold
        transitionIndices_m = find(abs(dy_dx_m) > transitionThreshold);
        transitionIndices_p = find(abs(dy_dx_p) > transitionThreshold);

        % Calculate transition width as the range of current in the transition region
        if ~isempty(transitionIndices_m)
            transitionWidth_m = abs(max(xm(transitionIndices_m)) - min(xm(transitionIndices_m)));
        else
            transitionWidth_m = inf;
        end
        
        if ~isempty(transitionIndices_p)
            transitionWidth_p = abs(max(xp(transitionIndices_p)) - min(xp(transitionIndices_p)));
        else
            transitionWidth_p = inf;
        end
        
        if any(abs(dy_dx_m) > 500, 'all')
            flagm = 1;
        end
        
        if  any(abs(dy_dx_p) > 500, 'all')
            flagp = 1;
        end
        
        fitResults(i).fileName = fileName;
        % If transition width is below the threshold, calculate average current instead of fitting
        if flagm == 1
            fprintf('Transition width too small for %s (Neg part): %.4f, calculating average current\n', fileName, transitionWidth_m);
            avgCurrent_m = mean(xm(transitionIndices_m));
            fitResults(i).Icm = avgCurrent_m;
            fitResults(i).Rnm = NaN;
            fitResults(i).Rsgm = NaN;
        else
            % Perform fitting if transition width is large enough
            initialGuessm = SubFunc.initializeGuess(xm, ym, "NEG");
            try
                fittedParamsm = lsqcurvefit(@(params, x) SubFunc.fitCurrent(params, x, "NEG"), initialGuessm, xm, ym);
                fitResults(i).Icm = fittedParamsm(1);
                fitResults(i).Rnm = fittedParamsm(2);
                fitResults(i).Rsgm = fittedParamsm(3);
            catch
                disp('Curve fitting failed for Neg part');
                fitResults(i).Icm = NaN;
                fitResults(i).Rnm = NaN;
                fitResults(i).Rsgm = NaN;
            end
        end
        
        if flagp == 1
            fprintf('Transition width too small for %s (Pos part): %.4f, calculating average current\n', fileName, transitionWidth_p);
            avgCurrent_p = mean(xp(transitionIndices_p));
            fitResults(i).Icp = avgCurrent_p;
            fitResults(i).Rnp = NaN;
            fitResults(i).Rsgp = NaN;
        else
            % Perform fitting if transition width is large enough
            initialGuessp = SubFunc.initializeGuess(xp, yp, "POS");
            try
                fittedParamsp = lsqcurvefit(@(params, x) SubFunc.fitCurrent(params, x, "POS"), initialGuessp, xp, yp);
                fitResults(i).Icp = fittedParamsp(1);
                fitResults(i).Rnp = fittedParamsp(2);
                fitResults(i).Rsgp = fittedParamsp(3);
            catch
                disp('Curve fitting failed for Pos part');
                fitResults(i).Icp = NaN;
                fitResults(i).Rnp = NaN;
                fitResults(i).Rsgp = NaN;
            end
        end
        
        % Store the fitting results
        fitResults(i).fileName = fileName;
        
        % Plot and save the fitting curve
        SubFunc.plotAndSaveFitCurve(data, fitResults(i), fileName, sweepMode, FolderPath);
        
        % The extracted values are a nested array of cells that need to be unwrapped
        pattern = 'Field_(-?\d+)Oe.txt';
        matches = regexp(fileName, pattern, 'tokens');
        if ~isempty(matches)
            magnetic_field = str2double(matches{1});
        else
            error('Magnetic field value not found');
        end
        % output result
        fitResults(i).FieldH = magnetic_field;
    end
    
    % save the fitting results according to the sweepMode
    fitResultsToSave = struct2table(fitResults);
    if strcmp(sweepMode, 'NegPosSweep')
        % ic = icp, ir = icm
        fitResultsToSave.Properties.VariableNames = ["File Name", "Ir", "Rr", "Rrsg", "Ic", "Rc", "Rcsg", "Magnetic Field"];
        fileName = FolderPath + "\Log\" + "NegPosSweep.txt";
        writetable(fitResultsToSave, fileName, 'Delimiter', '\t');
    elseif strcmp(sweepMode, 'PosNegSweep')
        % ic = icm, ir = icp
        fitResultsToSave.Properties.VariableNames = ["File Name", "Ic", "Rc", "Rcsg", "Ir", "Rr", "Rrsg", "Magnetic Field"];
        fileName = FolderPath + "\Log\" + "PosNegSweep.txt";
        writetable(fitResultsToSave, fileName, 'Delimiter', '\t');
    else
        error('Invalid sweepMode. Use "NegPosSweep" or "PosNegSweep".');
    end
end