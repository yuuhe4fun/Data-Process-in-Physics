function contourPlot = contourPlot(sweepMode, FolderPath)
    % Get all files in the specified directory that match the 
    % format 'Field_*Oe.txt'.
    files = dir(fullfile(FolderPath, sweepMode, '*.txt'));

    % Extract and sort the serial number in the file name
    numFiles = length(files);
    fileOrder = zeros(numFiles, 1);
    pattern = 'Field_(-?\d+)Oe.txt';
    for i = 1:numFiles
        % Extract serial numbers from filenames using regular expressions
        matches = regexp(files(i).name, pattern, 'tokens');
        if ~isempty(matches)
            % Convert serial numbers to numeric and store themgit 
            fileOrder(i) = str2double(matches{1});
        else
            error('Serial number in filename not found');
        end
    end

    % Sort files by the extracted serial numbers
    [~, sortedIdx] = sort(fileOrder);
    sortedFiles = files(sortedIdx);
    
    cutoff = 15;        % Number of points to cut off at the edges to remove edge effects
    
    % Preallocate data storage to improve memory efficiency
    maxDataLength = 0;
    for i = 1:numFiles
        data = readmatrix(fullfile(FolderPath, sweepMode, sortedFiles(i).name));
        maxDataLength = max(maxDataLength, length(data) - 2 * cutoff);
    end

    % Preallocate arrays to store all data
    all_Current = nan(numFiles * maxDataLength, 1);
    all_Field = nan(numFiles * maxDataLength, 1);
    all_dVdI = nan(numFiles * maxDataLength, 1);
    all_Voltage = nan(numFiles * maxDataLength, 1);

    % Initialize index for storing data
    idx = 1;

    % Iterate through all files
    for i = 1:numFiles
        % Read file name
        fileName = sortedFiles(i).name;
        % Read file data
        data = readmatrix(fullfile(FolderPath, sweepMode, fileName));
        
        % Assign data columns to variables
        Current = data(:, 1); % Current values
        Voltage = data(:, 2); % Voltage values
        dVdI = data(:, 3);    % Differential conductance
        
        % Remove the effects from the edges to avoid edge artifacts
        Current = Current(cutoff:end-cutoff);
        Voltage = Voltage(cutoff:end-cutoff);
        dVdI = dVdI(cutoff:end-cutoff);
        
        % Extract the magnetic field value from the filename
        matches = regexp(fileName, pattern, 'tokens');
        if ~isempty(matches)
            magnetic_field = str2double(matches{1});
        else
            error('Magnetic field value not found');
        end
        
        % Store data for plotting
        numPoints = length(Current);
        all_Current(idx:idx+numPoints-1) = Current;
        all_Field(idx:idx+numPoints-1) = magnetic_field * ones(numPoints, 1);
        all_dVdI(idx:idx+numPoints-1) = dVdI;
        all_Voltage(idx:idx+numPoints-1) = Voltage;
        idx = idx + numPoints;
    end
    
    % Remove unused preallocated space
    validIdx = ~isnan(all_Current);
    all_Current = all_Current(validIdx);
    all_Field = all_Field(validIdx);
    all_dVdI = all_dVdI(validIdx);
    all_Voltage = all_Voltage(validIdx);

    % Create a grid to interpolate and fill gaps for a smooth colormap
    unique_Field = unique(all_Field);
    unique_Current = unique(all_Current);
    [FieldGrid, CurrentGrid] = meshgrid(unique_Field, unique_Current);
    SmoothedGrid_dVdI = griddata(all_Field, all_Current, all_dVdI, FieldGrid, CurrentGrid, 'natural');
    SmoothedGrid_Voltage = griddata(all_Field, all_Current, all_Voltage, FieldGrid, CurrentGrid, 'natural');

    % Plot heatmap for dV/dI using pcolor for smooth continuous color blocks
    figure;
    % Set custom X and Y axis limits
    xlim([min(unique_Field), max(unique_Field)]);
    ylim([min(unique_Current), max(unique_Current)]);
    pcolor(FieldGrid, CurrentGrid, SmoothedGrid_dVdI);
    shading interp;
    colorbar;
    xlabel('Magnetic Field (H) (Oe)');
    ylabel('Current (A)');
    title(sprintf('dV/dI Smoothed Heatmap (%s)', sweepMode));
    outputFile = fullfile(FolderPath + "\Log\", sprintf('dVdI_Heatmap_%s.png', sweepMode));
    if exist(outputFile, 'file')
        delete(outputFile);
    end
    saveas(gcf, outputFile);

    % Plot heatmap for Voltage using pcolor for smooth continuous color blocks
    figure;
    % Set custom X and Y axis limits
    xlim([min(unique_Field), max(unique_Field)]);
    ylim([min(unique_Current), max(unique_Current)]);
    pcolor(FieldGrid, CurrentGrid, SmoothedGrid_Voltage);
    shading interp;
    colorbar;
    xlabel('Magnetic Field (H) (Oe)');
    xlabel('Magnetic Field (H) (Oe)');
    ylabel('Current (A)');
    title(sprintf('Voltage Heatmap (%s)', sweepMode));
    outputFile = fullfile(FolderPath + "\Log\", sprintf('Voltage_Heatmap_%s.png', sweepMode));
    if exist(outputFile, 'file')
        delete(outputFile);
    end
    saveas(gcf, outputFile);

    % Return figure handle
    contourPlot = gcf;
end
