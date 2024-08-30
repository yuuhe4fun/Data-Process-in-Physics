clc;clear;close all;
%% ############### User Defined ###############
% Data file name
file_name = 'SDE-2.dat';

% Magnetic fields in Oersted (Oe)a
FieldH = {12500; 12000; 11000; 10000; 9000; 8000; 7000; 6000; 5000; 4000; 3000; 2000; 1000; 0; -1000; -2000; -3000; -4000; -3000; -2000; -1000; 0; 1000; 2000; 3000; 4000};

% Current step in Amperes (A)
IStep = 1E-6;

% Initial guesses [Ic, Rn]
initialGuess = [1, 10];

%% ############### Load Data ###############
% Load Data and Preprocess
opts = detectImportOptions(file_name, 'Delimiter', ',');
opts.SelectedVariableNames = {opts.VariableNames{1}, opts.VariableNames{2}, opts.VariableNames{3}};
data = readtable(file_name, opts);
data.Properties.VariableNames = {'VoltageV', 'CurrentA', 'dVdI'};

%% ############### Load & Save Data ###############
% Define the number of data points per current sweep
% This will depend on your specific experiment setup
numPointsPerSweep = length(data.CurrentA) / length(FieldH);
% Check if the division is exact
if rem(length(data.CurrentA), length(FieldH)) ~= 0
    error('The number of data poinzts is not evenly divisible by the number of fields.');
end
% Split data by magnetic fields and save to individual files
for i = 1:length(FieldH)
    start_idx = (i-1) * numPointsPerSweep + 1;
    end_idx = i * numPointsPerSweep;
    
    currentSegment = data.CurrentA(start_idx:end_idx);
    voltageSegment = data.VoltageV(start_idx:end_idx);
    dVdISegment = data.dVdI(start_idx:end_idx);
    % Combine current and voltage into one matrix
    field_data = [currentSegment, voltageSegment, dVdISegment];
    
    % Create a filename for this magnetic field
    outputFileName = sprintf('Field_%dOe_%d.txt', FieldH{i}, i);
    % Save the data to a file
    save(outputFileName, 'field_data', '-ascii');
end
disp('Data has been separated and saved according to magnetic fields.');

%% ############### Fit Process ###############
% Get all files in the current directory that match the 
%   format 'Field_*Oe_*.txt'.
files = dir('Field_*Oe_*.txt');

% Extract and sort the serial number in the file name
fileOrder = zeros(length(files), 1);
for i = 1:length(files)
    % Extracting serial numbers from filenames using regular expressions
    pattern = 'Field_(-?\d+)Oe_(\d+).txt';
    matches = regexp(files(i).name, pattern, 'tokens');
    if ~isempty(matches)
        % Convert serial numbers to numbers and store
        fileOrder(i) = str2double(matches{1}{2});
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
    data = load(fileName);
    
    % Specify the range of data rows to be fitted, e.g. from row 1000 to row
    %   1601
    V_threshold = 1E-4; % Setting the voltage threshold, e.g. 0.1 V
    rowRangem = intersect(find(data(:,1) < 0 & abs(data(:,3)) > V_threshold), 1:800); % to fit the Ic-
    rowRangep = intersect(find(data(:,1) > 0 & abs(data(:,3)) > V_threshold), 801:1601); % to fit the Ic+

    xm = data(rowRangem, 3);
    ym = data(rowRangem, 1);
    xp = data(rowRangep, 3);
    yp = data(rowRangep, 1);

    % Define the fitted model, f(x) = (Ic^2 + (x/Rn)^2)^0.5
    fitModelm = @(params, x) -sqrt(params(1)^2 + (x/params(2)).^2);
    fitModelp = @(params, x) sqrt(params(1)^2 + (x/params(2)).^2);
    % Fitting the data using non-linear least squareq
    options = optimoptions('lsqcurvefit', 'Display', 'off');
    fittedParamsm = lsqcurvefit(fitModelm, initialGuess, smooth(xm), smooth(ym), [], [], options);
    fittedParamsp = lsqcurvefit(fitModelp, initialGuess, smooth(xp), smooth(yp), [], [], options);
    
    % Store the fitting results
    fitResults(i).fileName = fileName;
    fitResults(i).Icm = fittedParamsm(1);
    fitResults(i).Rnm = fittedParamsm(2);
    fitResults(i).Icp = fittedParamsp(1);
    fitResults(i).Rnp = fittedParamsp(2);
    fitResults(i).deltaIc = abs(fitResults(i).Icp) - abs(fitResults(i).Icm);
    
    % Extracting magnetic field values using regular expressions
    pattern = 'Field_(-?\d+)Oe';
    matches = regexp(fileName, pattern, 'tokens');
    
    % The extracted values are a nested array of cells that need to be unwrapped
    if ~isempty(matches)
        magnetic_field = str2double(matches{1}{1});
    else
        error('Magnetic field value not found');
    end

    % output result
    fitResults(i).FieldH = magnetic_field;
end

% Show fit results
for i = 1:length(fitResults)
    fprintf('File: %s\n', fitResults(i).fileName);
    fprintf('Icm: %.10f, Rnp: %.10f\n', fitResults(i).Icm, fitResults(i).Rnm);
    fprintf('Icp: %.10f, Rnp: %.10f\n\n', fitResults(i).Icp, fitResults(i).Rnp);
end
% Open the file to write the result
outputFile = 'fit_results.txt';
fid = fopen(outputFile, 'w');
% Check if the file was opened successfully
if fid == -1
    error('Cannot open output file for writing: %s', outputFile);
end
% Write results to file
for i = 1:length(fitResults)
    if isempty(fitResults(i).fileName)
        continue; % Skip files with no data
    end
    fprintf(fid, 'File: %s\n', fitResults(i).fileName);
    fprintf(fid, 'Icm: %.10f, Rnm: %.10f\n', fitResults(i).Icm, fitResults(i).Rnm);
    fprintf(fid, 'Icp: %.10f, Rnp: %.10f\n\n', fitResults(i).Icp, fitResults(i).Rnp);
end
fclose(fid);

fprintf('Fitting results saved to %s\n', outputFile);

%% ############### Plotting ###############
% Extract FieldH values
fieldHValues = [fitResults.FieldH];

% Extract Icm values
IcmValues = [fitResults.Icm];
IcpValues = [fitResults.Icp];
deltaIc = [fitResults.deltaIc];

% Plot the data
figure;
%plot(fieldHValues, IcmValues, '-o');
plot(fieldHValues, deltaIc, '-o');
xlabel('Magnetic Field (Oe)');
ylabel('Icp (A)');
title('Magnetic Field vs Ic');
grid on;