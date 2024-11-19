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