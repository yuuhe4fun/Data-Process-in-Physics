clc;clear;close all;
%% ############### User Defined ###############
% Data file name
file_name = 'test-1.txt.dat';
% Magnetic fields in Oersted (Oe)
FieldH = {10000; 9000; 8000; 7000; 6000; 5000; 4000; 3000; 2000; 1000; 0; -1000};
% Current step in Amperes (A)
IStep = 1E-6;

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
    error('The number of data points is not evenly divisible by the number of fields.');
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
    outputFileName = sprintf('Field_%dOe.txt', FieldH{i});
    % Save the data to a file
    save(outputFileName, 'field_data', '-ascii');
end
disp('Data has been separated and saved according to magnetic fields.');