clc;clear;close all;
%% ############### Load Data ###############
% Load Data and Preprocess
file_name = 'D5-AHE-PATTERN-4K.txt';
opts = detectImportOptions(file_name, 'Delimiter', '\t', 'NumHeaderLines', 1);
opts.SelectedVariableNames = {opts.VariableNames{4}, opts.VariableNames{6}, opts.VariableNames{8}};
data = readtable(file_name, opts);
data.Properties.VariableNames = {'FieldH', 'CurrentA', 'VoltageV'};
data.RawResistanceXY = data.VoltageV ./ data.CurrentA;

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
edges = (-8000:10:8000); 
% ReCalculate the box median (newFieldH)
newFieldH = 0.5 * (edges(1:end-1) + edges(2:end));

% Process pos-Sweep
[~, ~, posLoc] = histcounts(data.FieldH(posIndex), edges);
posResistance = data.VoltageV(posIndex) ./ data.CurrentA(posIndex);
posValidIdx = posLoc > 0;
%   defaultVal = NaN or 0
newPosResistance = accumarray(posLoc(posValidIdx), posResistance(posValidIdx), [numel(edges)-1, 1], @mean, NaN);
%   fill missing data using Piecewise Cubic Hermite Interpolating Polynomial
newPosResistance = fillmissing(newPosResistance, 'pchip');

% Process neg-Sweep
[~, ~, negLoc] = histcounts(data.FieldH(negIndex), edges);
negResistance = data.VoltageV(negIndex) ./ data.CurrentA(negIndex);
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

%% ############### Linear Fitting for Specified Range ###############
% Define the high-field linear range
linearRangeToFit = (newFieldH >= 7000);
fieldHToFit = newFieldH(linearRangeToFit);
asymResistanceToFit = asymPosResistance(linearRangeToFit);
% Perform linear fit constrained to pass through origin
slope = fieldHToFit' \ asymResistanceToFit; % This gives the slope
% Create the linear fit line over the entire field range
fitAsymPosResistance = slope .* newFieldH;
% Subtract the linear fit from the asymPosResistance
asymPosResistance = asymPosResistance' - fitAsymPosResistance;
asymNegResistance = asymNegResistance' - fitAsymPosResistance;

%% ############### Plot Data ###############
figure;
hold on;
% Plot rawResistanceXY v.s. FieldH
plot(data.FieldH, data.RawResistanceXY, 'g-', 'LineWidth', 2, 'DisplayName', 'raw AHE');
% Plot pos-Sweep in red and neg-Sweep in blue
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