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
