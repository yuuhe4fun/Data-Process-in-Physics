clc;clear;close all;
%% ############### Load Data ###############
% Load Data and Preprocess
file_name = 'AHE_5K_sweep 5000Oe range.txt';
opts = detectImportOptions(file_name, 'Delimiter', ',', 'NumHeaderLines', 1);
opts.SelectedVariableNames = {opts.VariableNames{5}, opts.VariableNames{12}, opts.VariableNames{11}};
data = readtable(file_name, opts);
data.Properties.VariableNames = {'FieldH', 'CurrentA', 'VoltageV'};
data.RawResistanceXY = data.VoltageV;

%% ############### Process Data ###############
% Calculate the difference of FieldH to find the turning point from
%   pos-Sweep to neg-Sweep
dFieldH = diff(data.FieldH);
turningPoint = find(dFieldH < 0, 1, 'first') + 1;
% Assume that the pos-Sweep is the first segment to process
posIndex = 1:turningPoint - 1;
% Assume that the neg-Sweep is the second segment to process
negIndex = turningPoint:length(data.FieldH);
% Define the edges of the boxes
edges = (-5000:10:5000); 
% ReCalculate the box median (newFieldH)
newFieldH = 0.5 * (edges(1:end-1) + edges(2:end));

% Process pos-Sweep
[~, ~, posLoc] = histcounts(data.FieldH(posIndex), edges);
posResistance = data.VoltageV(posIndex);
posValidIdx = posLoc > 0;
%   defaultVal = NaN or 0
newPosResistance = accumarray(posLoc(posValidIdx), posResistance(posValidIdx), [numel(edges)-1, 1], @mean, NaN);
%   fill missing data using Piecewise Cubic Hermite Interpolating Polynomial
newPosResistance = fillmissing(newPosResistance, 'pchip');

% Process neg-Sweep
[~, ~, negLoc] = histcounts(data.FieldH(negIndex), edges);
negResistance = data.VoltageV(negIndex);
negValidIdx = negLoc > 0;
%   defaultVal = NaN or 0
newNegResistance = accumarray(negLoc(negValidIdx), negResistance(negValidIdx), [numel(edges)-1, 1], @mean, NaN);
%   fill missing data using Piecewise Cubic Hermite Interpolating Polynomial
newNegResistance = fillmissing(newNegResistance, 'pchip');

% Calculate anti-symmetric component for pos-Sweep & neg-Sweep
asymPosResistance = zeros(length(newFieldH),1);
asymNegResistance = zeros(length(newFieldH),1);
for posIndex = 1:length(newFieldH)
    negIndex = length(newFieldH) - posIndex + 1;
    asymPosResistance(posIndex) = (newPosResistance(posIndex) - newNegResistance(negIndex)) / 2;
    asymNegResistance(posIndex) = (newNegResistance(posIndex) - newPosResistance(negIndex)) / 2;
end

newData.newFieldH = [newFieldH, flip(newFieldH)];
newData.newResistance = [asymPosResistance; asymNegResistance];

%% ############### Plot Data ###############
figure(1);
hold on;
% Plot rawResistanceXY v.s. FieldH
plot(data.FieldH, data.RawResistanceXY, 'g-', 'LineWidth', 2, 'DisplayName', 'raw AHE');
% Plot pos-Sweep in red and neg-Sweep in blue
figure(2);
hold on;
plot(newFieldH, asymPosResistance, 'r-', 'LineWidth', 1, 'DisplayName', 'pos-Sweep');
plot(newFieldH, asymNegResistance, 'b-', 'LineWidth', 1, 'DisplayName', 'neg-Sweep');
% Add title and axis labels
legend('show','Location', 'best', 'Box', 'off');
xlabel('Field (Oe)');
ylabel('Resistance (\Omega)');
% Set the font size
set(gca, 'FontSize', 10, 'LineWidth', 1.5);
% Add Grid Lines
grid on;
% Export Graphics
% saveas(gcf, 'plot.png');