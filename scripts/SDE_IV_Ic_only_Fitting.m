clc;clear;close all;
%% ############### Load Data & Fit Process ###############
% Get all files in the current directory that match the 
%   format 'Field_*Oe.txt'.
files = dir('*.txt');

% Extract and sort the serial number in the file name
fileOrder = zeros(length(files), 1);
for i = 1:length(files)
    % Extracting serial numbers from filenames using regular expressions
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

% Initialise the structure that stores the fitting results
fitResults = struct();

% Iterate through all documents
for i = 1:length(sortedFiles)
    % Read file name
    fileName = sortedFiles(i).name;
    % Read file data
    data = readmatrix(fileName);
    
    % Specify the range of data rows to be fitted
    rowRangem = data(:,2) < 100 & data(:,1) < 0; % to fit the Ic-
    rowRangep = data(:,2) < 100 & data(:,1) >= 0; % to fit the Ic+

    xm = data(rowRangem, 1);
    ym = data(rowRangem, 2);
    initialGuessm = [0.5*(xm(1)+xm(end)), 10, 0.33];
    xp = data(rowRangep, 1);
    yp = data(rowRangep, 2);
    initialGuessp = [0.5*(xp(1)+xp(end)), 10, 0.33];

    % Fitting with lsqcurvefit
    options = optimoptions('lsqcurvefit', 'Display', 'iter');
    
    % Fitting Icm data
    try
        fittedParamsm = lsqcurvefit(@(params, x) icmFit(params, x), initialGuessm, xm, ym, [], [], options);
    catch
        disp('Curve fitting failed for Icm');
        fittedParamsm = [0, 0, 0];
    end
    % Fitting Icp data
    try
        fittedParamsp = lsqcurvefit(@(params, x) icpFit(params, x), initialGuessp, xp, yp, [], [], options);
    catch
        disp('Curve fitting failed for Icp');
        fittedParamsp = [0, 0, 0];
    end
    
    % Store the fitting results
    fitResults(i).fileName = fileName;
    fitResults(i).Icm = fittedParamsm(1);
    fitResults(i).Rnm = fittedParamsm(2);
    fitResults(i).Rsgm = fittedParamsm(3);
    fitResults(i).Icp = fittedParamsp(1);
    fitResults(i).Rnp = fittedParamsp(2);
    fitResults(i).Rsgp = fittedParamsp(3);
    fitResults(i).deltaIc = abs(fitResults(i).Icp) - abs(fitResults(i).Icm);
    
    % Extracting magnetic field values using regular expressions
    pattern = '(-?\d+)';
    matches = regexp(fileName, pattern, 'tokens');
    
    % The extracted values are a nested array of cells that need to be unwrapped
    if ~isempty(matches)
        magnetic_field = str2double(matches{1}{1});
    else
        error('Magnetic field value not found');
    end

    % output result
    fitResults(i).FieldH = magnetic_field;
    
    figure;
    plot(xm, ym, '--cyan',...
                            'LineWidth',2);
    hold on;
    plot(xp, yp, '--cyan',...
                            'LineWidth',2);
    hold on;
    plot(xm(xm > fitResults(i).Icm), fitResults(i).Rsgm * xm(xm>fitResults(i).Icm), 'red');
    hold on;
    plot(xm(xm <= fitResults(i).Icm), fitResults(i).Icm * fitResults(i).Rnm * sqrt(max((xm(xm<=fitResults(i).Icm)/fitResults(i).Icm).^2 - 1, 0)) + fitResults(i).Rsgm * xm(xm<=fitResults(i).Icm), 'red');
    hold on;
    plot(xp(xp < fitResults(i).Icp), fitResults(i).Rsgp * xp(xp<fitResults(i).Icp), 'blue');
    hold on;
    plot(xp(xp >= fitResults(i).Icp), fitResults(i).Icp * fitResults(i).Rnp * sqrt(max((xp(xp>=fitResults(i).Icp)/fitResults(i).Icp).^2 - 1, 0)) + fitResults(i).Rsgp * xp(xp>=fitResults(i).Icp), 'blue');
    
    
end

% % Show fit results
% for i = 1:length(fitResults)
%     fprintf('File: %s\n', fitResults(i).fileName);
%     fprintf('Icm: %.10f, Rnm: %.10f\n', fitResults(i).Icm, fitResults(i).Rnm);
%     fprintf('Icp: %.10f, Rnp: %.10f\n\n', fitResults(i).Icp, fitResults(i).Rnp);
% end
% 
% % Open the file to write the result
% outputFile = 'fit_results.txt';
% fid = fopen(outputFile, 'w');
% % Check if the file was opened successfully
% if fid == -1
%     error('Cannot open output file for writing: %s', outputFile);
% end
% % Write results to file
% for i = 1:length(fitResults)
%     if isempty(fitResults(i).fileName)
%         continue; % Skip files with no data
%     end
%     fprintf(fid, 'File: %s\n', fitResults(i).fileName);
%     fprintf(fid, 'Icm: %.10f, Rnm: %.10f\n', fitResults(i).Icm, fitResults(i).Rnm);
%     fprintf(fid, 'Icp: %.10f, Rnp: %.10f\n\n', fitResults(i).Icp, fitResults(i).Rnp);
% end
% fclose(fid);
% 
% fprintf('Fitting results saved to %s\n', outputFile);

%% ############### Plotting ###############
% Extract FieldH values
fieldHValues = [fitResults.FieldH];

% Extract Icm values
IcmValues = [fitResults.Icm];
IcpValues = [fitResults.Icp];
deltaIc = [fitResults.deltaIc];

% Plot the data
figure;
plot(fieldHValues, abs(IcmValues), '-o');
hold on;
plot(fieldHValues, IcpValues, '-o');
xlabel('Magnetic Field (Oe)');
ylabel('Ic (A)');
title('Magnetic Field vs Ic');

figure;
plot(fieldHValues, deltaIc, '-o');
xlabel('Magnetic Field (Oe)');
ylabel('deltaIc (A)');
title('Magnetic Field vs Ic');
grid on;

%% ############### Function ###############
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