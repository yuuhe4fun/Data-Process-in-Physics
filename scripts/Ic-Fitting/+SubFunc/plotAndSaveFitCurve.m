function plotAndSaveFitCurve(data, fittedParams, fileName, sweepMode, folderPath)
    % Extract current and voltage data
    rowRangem = data(:,2) < 100 & data(:,1) < 0;
    rowRangep = data(:,2) < 100 & data(:,1) >= 0;
    
    % Create figure
    fig = figure('Visible', 'off');
    hold on;
    
    % Plot raw data
    plot(data(:,1), data(:,2), 'k.', 'MarkerSize', 1);

    % Generate fitting curves
    x_rangem = linspace(min(data(rowRangem,1)), 0, 1000);
    x_rangep = linspace(0, max(data(rowRangep,1)), 1000);

    % Plot fitting curves
    % plot(x_rangem, icmFit([fittedParams.Icm, fittedParams.Rnm, fittedParams.Rsgm], x_rangem), 'r-', 'LineWidth', 1.5);
    % plot(x_rangep, icpFit([fittedParams.Icp, fittedParams.Rnp, fittedParams.Rsgp], x_rangep), 'r-', 'LineWidth', 1.5);
    
    % Extract field value from filename
    pattern = 'Field_(-?\d+)Oe';
    matches = regexp(fileName, pattern, 'tokens');
    field_value = str2double(matches{1});
    
    % Add labels and title
    xlabel('Current (A)');
    ylabel('Voltage (V)');
    title(['I-V Curve at ' num2str(field_value) ' Oe']);
    grid on;
    
    % Save the figure
    [~, name, ~] = fileparts(fileName);
    savePath = fullfile(folderPath, sweepMode, [name '.svg']);
    saveas(fig, savePath, 'svg');
    close(fig);
end