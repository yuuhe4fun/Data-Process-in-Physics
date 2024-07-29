clc;clear;close all;
%% ############### Load Data ###############
% Setting the folder path
parentFolder = 'D:/Beihang_University/Guang Yang''s Group/0_WORKSPACE/002_SCRIPTS/+400_+1800';
% Get a list of all subfolders in the current directory
subFolders = dir(parentFolder);
% Pre-allocated cell array
numFolders = 0;
for k = 1:length(subFolders)
    if subFolders(k).isdir && ~strcmp(subFolders(k).name, '.') && ~strcmp(subFolders(k).name, '..')
        numFolders = numFolders + 1;
    end
end

folderNames = cell(1, numFolders);
folderPaths = cell(1, numFolders);

% Fill in subfolder names and paths
folderIdx = 1;
for k = 1:length(subFolders)
    if subFolders(k).isdir && ~strcmp(subFolders(k).name, '.') && ~strcmp(subFolders(k).name, '..')
        folderNames{folderIdx} = subFolders(k).name;
        folderPaths{folderIdx} = fullfile(parentFolder, subFolders(k).name);
        folderIdx = folderIdx + 1;
    end
end

% Sort by subfolder name
[sortedNames, sortIdx] = sort(folderNames);
sortedPaths = folderPaths(sortIdx);

for k = 1:length(sortedPaths)
    subFolderPath = sortedPaths{k};
    dataFilePath = fullfile(subFolderPath, 'data.txt');
    
    if exist(dataFilePath, 'file')
        data = readtable(dataFilePath, 'Delimiter', '  ', 'ReadVariableNames', false);
        
        % Extract current and voltage data
        current = data.Var1;
        voltage = data.Var2;
        
        fprintf('Processing data from %s\n', sortedNames{k});
        % I-V Curve
        figure;
        plot(current, voltage);
        xlabel('Current');
        ylabel('Voltage');
        title(['I-V Curve for ', sortedNames{k}]);
    else
        fprintf('File %s does not exist.\n', dataFilePath);
    end
end