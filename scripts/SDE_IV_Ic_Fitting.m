clc;clear;close all;
%% ############### User Defined ###############
% Data file name
NegPosSweepFileName = 'SYM-2-IV-01.dat';
PosNegSweepFileName = 'SYM-2-IV.dat';

% Magnetic fields in Oersted (Oe)a
FieldH = {-12500; -12000; -11000; -10000; -9000; -8000; -7000; -6000; -5000; 
    -4000; -3000; -2000; -1000; -900; -800; -700; -600; -500; -400; -300; 
    -200; -100; 0; 100; 200; 300; 400; 500; 600; 700; 800; 900; 1000; 2000; 
    3000; 4000; 5000; 6000; 7000; 8000; 9000; 10000; 11000; 12000; 12500};

%% ############### Load & Save Data ###############
% Load Data and Preprocess
% For the sweep from negative to positive
NegPosOpts = detectImportOptions(NegPosSweepFileName, 'Delimiter', ',');
NegPosOpts.SelectedVariableNames = {NegPosOpts.VariableNames{3}, NegPosOpts.VariableNames{2}, NegPosOpts.VariableNames{1}};
NegPosSweepFileNamedata = readtable(NegPosSweepFileName, NegPosOpts);
NegPosSweepFileNamedata.Properties.VariableNames = {'VoltageV', 'CurrentA', 'dVdI'};

% For the sweep from positive to negative
PosNegOpts = detectImportOptions(PosNegSweepFileName, 'Delimiter', ',');
PosNegOpts.SelectedVariableNames = {PosNegOpts.VariableNames{3}, PosNegOpts.VariableNames{2}, PosNegOpts.VariableNames{1}};
PosNegSweepFileNamedata = readtable(PosNegSweepFileName, PosNegOpts);
PosNegSweepFileNamedata.Properties.VariableNames = {'VoltageV', 'CurrentA', 'dVdI'};

% mkdir new folders to store relevant results
newFolderName = datestr(datetime('now'), 'yyyymmddHHMMSS');
newFolderPath = fullfile(pwd, newFolderName);
newSubFolderNames = {'NegPosSweep', 'PosNegSweep', 'Log'};
createFoldersWithSubfolders(newFolderPath, newSubFolderNames);

saveFieldDataBySweep(NegPosSweepFileNamedata, FieldH, 'NegPosSweep', newFolderPath);
saveFieldDataBySweep(PosNegSweepFileNamedata, FieldH, 'PosNegSweep', newFolderPath);
disp('Data has been separated and saved according to magnetic fields.');

%% ############### Fit Process ###############
NegPosFitResults = fitDataBasedOnSweepMode("NegPosSweep", newFolderPath);
PosNegFitResults = fitDataBasedOnSweepMode("PosNegSweep", newFolderPath);

%% ############### Plotting ###############
figure(1);
hold on;
plot([NegPosFitResults.FieldH], [NegPosFitResults.Icp], 'b-o', 'LineWidth', 1.5, 'DisplayName', 'NegPos Sweep');
plot([PosNegFitResults.FieldH], abs([PosNegFitResults.Icm]), 'r--s', 'LineWidth', 1.5, 'DisplayName', 'PosNeg Sweep');
figure(2);
hold on;
plot([NegPosFitResults.FieldH], [NegPosFitResults.Icp] - abs([PosNegFitResults.Icm]), 'b-o', 'LineWidth', 1.5, 'DisplayName', 'NegPos Sweep');
%% ############### Relevant Functions ###############
function createFoldersWithSubfolders(mainFolderPath, subfolderNames)
    % Check if the folder exists and create it if it does not exist
    if ~exist(mainFolderPath, 'dir')
        mkdir(mainFolderPath);
        disp(['Main folder created: ', mainFolderPath]);
    else
        disp(['Main folder already exists: ', mainFolderPath]);
    end
    
    % Loop through all subfolder names
    for i = 1:length(subfolderNames)
        subfolderPath = fullfile(mainFolderPath, subfolderNames{i});
        % Check if the sub-folder exists and create it if it does not exist
        if ~exist(subfolderPath, 'dir')
            mkdir(subfolderPath);
            disp(['Subfolder created: ', subfolderPath]);
        else
            disp(['Subfolder already exists: ', subfolderPath]);
        end
    end
end

function saveFieldDataBySweep(data, FieldH, sweepMode, FolderPath)
    % Check if the passed sweepMode is valid
    validModes = {'NegPosSweep', 'PosNegSweep'};
    if ~ismember(sweepMode, validModes)
        error('Invalid sweep mode. Choose from ''NegPosSweep'', or ''PosNegSweep''.');
    end
    outputDir = FolderPath + "\" + sweepMode;

    % Define the number of data points per current sweep
    % This will depend on your specific experiment setup
    numPointsPerSweep = length(data.CurrentA) / length(FieldH);
    % Check if the division is exact
    if rem(length(data.CurrentA), length(FieldH)) ~= 0
        error('The number of data points is not evenly divisible by the number of fields.');
    end

    % Split data by magnetic fields and save to individual files
    for i = 1:length(FieldH)
        start_idx = (i-1) * numPointsPerSweep + 1;
        end_idx = i * numPointsPerSweep;
        
        currentSegment = data.CurrentA(start_idx:end_idx);
        voltageSegment = data.VoltageV(start_idx:end_idx);
        dVdISegment = data.dVdI(start_idx:end_idx);

        % Combine current, voltage, and dVdI into one matrix
        field_data = [currentSegment, voltageSegment, dVdISegment];
        
        % Create a filename for this magnetic field
        outputFileName = sprintf('Field_%dOe.txt', FieldH{i});
        outputPath = fullfile(outputDir, outputFileName);
        
        % Save the data to a file
        save(outputPath, 'field_data', '-ascii');
    end

    fprintf('Data saved in folder: %s\n', outputDir);
end

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
    % Iterate through all documents
    for i = 1:length(sortedFiles)
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
        
        % Initialize guesses
        initialGuessm = initializeGuess(xm, ym, "NEG");
        initialGuessp = initializeGuess(xp, yp, "POS");
        
        try
            fittedParamsp = lsqcurvefit(@(params, x) icpFit(params, x), initialGuessp, xp, yp);
            fittedParamsm = lsqcurvefit(@(params, x) icmFit(params, x), initialGuessm, xm, ym);
        catch
            disp('Curve fitting failed');
            fittedParamsp = [0, 0, 0];
            fittedParamsm = [0, 0, 0];
        end
        
        % Store the fitting results
        fitResults(i).fileName = fileName;
        fitResults(i).Icm = fittedParamsm(1);
        fitResults(i).Rnm = fittedParamsm(2);
        fitResults(i).Rsgm = fittedParamsm(3);
        fitResults(i).Icp = fittedParamsp(1);
        fitResults(i).Rnp = fittedParamsp(2);
        fitResults(i).Rsgp = fittedParamsp(3);
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

% Function to initialize guesses for fitting parameters
function initialGuess = initializeGuess(x, y, PorN)
    switch PorN
        case 'POS'
            RsgGuessFunc = polyfit(x(1:1000),y(1:1000),1);
            RsgGuess = RsgGuessFunc(1);
            RnGuessFunc = polyfit(x(end-1000:end),y(end-1000:end),1);
            RnGuess = RnGuessFunc(1);
            initialGuess = [0.7 * (x(1) + x(end)), RnGuess, RsgGuess];

        case 'NEG'
            RsgGuessFunc = polyfit(x(end-1000:end),y(end-1000:end),1);
            RsgGuess = RsgGuessFunc(1);
            RnGuessFunc = polyfit(x(1:1000),y(1:1000),1);
            RnGuess = RnGuessFunc(1);
            initialGuess = [0.7 * (x(1) + x(end)), RnGuess, RsgGuess];
        otherwise
            error('Unsupported PorN value');
    end
end

% Function to initialize guesses for fitting parameters
function y = icpFit(params, x)
    Ic = params(1);
    Rn = params(2);
    Rsg = params(3);
    
    y = zeros(size(x));
    y(x < Ic) = Rsg * x(x<Ic);
    y(x >= Ic) = Ic * Rn * sqrt(max((x(x>=Ic)/Ic).^2 - 1, 0)) + Rsg * x(x>=Ic);
end

function y = icmFit(params, x)
    Ic = params(1);
    Rn = params(2);
    Rsg = params(3);
    
    y = zeros(size(x));
    y(x > Ic) = Rsg * x(x>Ic);
    y(x <= Ic) = Ic * Rn * sqrt(max((x(x<=Ic)/Ic).^2 - 1, 0)) + Rsg * x(x<=Ic);
end