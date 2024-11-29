clc;clear;close all;
% Define the sweep mode: 'NegPosSweep' or 'PosNegSweep'
sweepMode = 'NegPosSweep'; % Set this to 'NegPosSweep' or 'PosNegSweep'

% Read data from the file
data = load('Field_12000Oe.txt');

% Extract the columns for current, voltage, and dV/dI
current = data(:, 1);
voltage = data(:, 2);
dVdI = data(:, 3);

% Apply sweep mode to select the region of interest
switch sweepMode
    case 'NegPosSweep'
        % Analyze current > 0 region
        region_idx = current > 0;
    case 'PosNegSweep'
        % Analyze current < 0 region
        region_idx = current < 0;
    otherwise
        error('Invalid sweepMode. Choose either ''NegPosSweep'' or ''PosNegSweep''.');
end

% Filter data based on selected region
current = current(region_idx);
voltage = voltage(region_idx);
dVdI = dVdI(region_idx);

% Calculate the derivative of voltage with respect to current to identify slope changes
dV = diff(voltage);
dI = diff(current);
slope = dV ./ dI;

% Calculate the difference in slope
slope_diff = abs(diff(slope));

% Automatically determine threshold based on slope_diff distribution
percentile_value = prctile(slope_diff, 95); % Use the 90th percentile as a threshold baseline
mean_slope_diff = mean(slope_diff);
std_slope_diff = std(slope_diff);

% Combine percentile and statistical approach for setting threshold
% The threshold is a combination of the 90th percentile and mean + factor * std
slope_threshold = max(percentile_value, mean_slope_diff + 3 * std_slope_diff);

step_points = find(slope_diff > slope_threshold);

% Identify voltage steps as regions between significant slope changes
step_regions = [];
for i = 1:length(step_points) - 1
    start_idx = step_points(i) + 1;
    end_idx = step_points(i + 1);
    if mean(abs(slope(start_idx:end_idx))) < slope_threshold / 2
        step_regions = [step_regions; start_idx, end_idx+1];
    end
end

% Plot the step regions on the original V-I characteristic curve
figure;
plot(current, voltage, 'b-', 'LineWidth', 1.5);
xlabel('Current (A)');
ylabel('Voltage (V)');
title('Voltage-Current Characteristic Curve with Step Regions Highlighted');
grid on;
hold on;

% Highlight the step regions
colors = lines(size(step_regions, 1)); % Use distinct colors for each step region
for i = 1:size(step_regions, 1)
    idx_range = step_regions(i, 1):step_regions(i, 2);
    plot(current(idx_range), voltage(idx_range), '-', 'LineWidth', 2, 'Color', colors(i, :));
end
legend('V-I Curve', 'Step Regions');

% Print the current ranges of the step regions
for i = 1:size(step_regions, 1)
    fprintf("Step region %d: Current range from %.6f A to %.6f A", i, current(step_regions(i, 1)), current(step_regions(i, 2)));
end
