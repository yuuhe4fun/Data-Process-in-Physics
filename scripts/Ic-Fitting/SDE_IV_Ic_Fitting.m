clc;clear;close all;
if exist('log.txt', 'file') 
    delete('log.txt');
end
diary('log.txt');
%% ############### User Defined ###############
% Data file name
NegPosSweepFileName = 'NbNotch-1-IV-0p4Tc-1.dat';
PosNegSweepFileName = 'NbNotch-1-IV-0p4Tc-2.dat';

% Magnetic fields in Oersted (Oe)a
FieldH = {-200; -100; 0; 100; 200; 300; 400; 500; 600; 700; 800; 900;
    1000; 2000; 3000; 4000; 5000; 6000; 7000; 8000; 9000; 10000; 11000; 12000};

% set up whether use the current folder
UseExistingFolder = true;  % true or false

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

if UseExistingFolder
    % use the existing folder
    newFolderPath = uigetdir(pwd, 'Select Existing Folder');
    if newFolderPath == 0
        error('No folder selected. Program terminated.');
    end
    disp(['Using existing folder: ', newFolderPath]);
else
    % mkdir new folders to store relevant results
    newFolderName = datestr(datetime('now'), 'yyyymmddHHMMSS');
    newFolderPath = fullfile(pwd, newFolderName);
    newSubFolderNames = {'NegPosSweep', 'PosNegSweep', 'Log'};
    SubFunc.createFoldersWithSubfolders(newFolderPath, newSubFolderNames);
    disp(['New folder created: ', newFolderPath]);
    
    SubFunc.saveFieldDataBySweep(NegPosSweepFileNamedata, FieldH, 'NegPosSweep', newFolderPath);
    SubFunc.saveFieldDataBySweep(PosNegSweepFileNamedata, FieldH, 'PosNegSweep', newFolderPath);
    disp('Data has been separated and saved according to magnetic fields.');
end

%% ############### Fit Process ###############
% NegPosFitResults = SubFunc.fitDataBasedOnSweepMode("NegPosSweep", newFolderPath);
% PosNegFitResults = SubFunc.fitDataBasedOnSweepMode("PosNegSweep", newFolderPath);

%% ############### Contour Plot Process ###############
NegPosConPlot = SubFunc.contourPlot("NegPosSweep", newFolderPath);
PosNegConPlot = SubFunc.contourPlot("PosNegSweep", newFolderPath);
% SubFunc.voltageStep("NegPosSweep", newFolderPath);
% SubFunc.voltageStep("PosNegSweep", newFolderPath);

%% ############### Plotting ###############
% figure(1);
% hold on;
% plot([NegPosFitResults.FieldH], [NegPosFitResults.Icp], 'b-o', 'LineWidth', 1.5, 'DisplayName', 'NegPos Sweep');
% plot([PosNegFitResults.FieldH], abs([PosNegFitResults.Icm]), 'r--s', 'LineWidth', 1.5, 'DisplayName', 'PosNeg Sweep');
% figure(2);
% hold on;
% plot([NegPosFitResults.FieldH], [NegPosFitResults.Icp] - abs([PosNegFitResults.Icm]), 'b-o', 'LineWidth', 1.5, 'DisplayName', 'NegPos Sweep');

%% ############### diary off ###############
diary off;