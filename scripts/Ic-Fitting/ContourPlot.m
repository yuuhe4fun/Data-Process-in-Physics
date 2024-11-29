clc;clear;close all;
folderPath = "D:\Beihang_University\Guang Yang's Group\0_WORKSPACE\002_SCRIPTS\Ic-Fitting\20241031203238\NegPosSweep";
files = dir(fullfile(folderPath, 'Field_*.txt'));
figure;
hold on;
colorMap = jet(256);
colormap(colorMap);

for i = 1:length(files)
    fileName = files(i).name;
    % Extract the magnetic field value in the file name as the Y axis
    pattern = 'Field_(-?\d+)Oe.txt';
    matches = regexp(fileName, pattern, 'tokens');
    if isempty(matches)
        continue;
    end

    % Read magnetic field value
    fieldH = str2double(matches{1}{1});

    % Read file data
    filePath = fullfile(folderPath, fileName);
    data = load(filePath);
    VoltageV = data(:, 2);
    dVdI = data(:, 3);
    dIdV = 1 ./ dVdI;

    % Interpolate missing dIdV values
    if any(isnan(dIdV))
        xq = linspace(min(VoltageV), max(VoltageV), length(VoltageV));
        dIdV = interp1(VoltageV(~isnan(dIdV)), dIdV(~isnan(dIdV)), xq, 'linear', 'extrap');
        VoltageV = xq; % Update VoltageV to match the interpolated length
    end

    % Normalize dIdV values ​​to color range
    norm_dIdV = (dIdV - min(dIdV)) / (max(dIdV) - min(dIdV));
    colorIdx = round(norm_dIdV * 255) + 1; % Convert to index
    colorIdx = max(1, min(colorIdx, 256)); % Ensure that the index is within the valid range

    % Draw each point, the color changes with dIdV
    for j = 1:length(VoltageV)
        plot(VoltageV(j), fieldH, 'o', 'MarkerFaceColor', colorMap(colorIdx(j), :), ...
             'MarkerEdgeColor', 'none', 'MarkerSize', 6);
    end
end

colorbar; % Show color bar
ylabel('Magnetic Field (Oe)');
xlabel('Voltage (V)');
title('Field-Voltage Plot with dIdV as Color');
hold off;