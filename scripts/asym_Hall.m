function [newData] = asym_Hall(data, edges)
    % Calculate the difference of FieldH to find the turning point from
    %   pos-Sweep to neg-Sweep
    dFieldH = diff(data.FieldH);
    turningPoint = find(dFieldH < 0, 1, 'first') + 1;
    
    % Assume that the pos-Sweep is the first segment to process
    posIndex = 1:turningPoint - 1;
    % Assume that the neg-Sweep is the second segment to process
    negIndex = turningPoint:length(data.FieldH);
    
    % Define the edges of the boxes
    if nargin < 2 || isempty(edges)
        edges = (-8000:10:8000); 
    end
    
    % ReCalculate the box median (newFieldH)
    newFieldH = 0.5 * (edges(1:end-1) + edges(2:end));

    % Process pos-Sweep
    [~, ~, posLoc] = histcounts(data.FieldH(posIndex), edges);
    posResistance = data.VoltageV(posIndex) ./ data.CurrentA(posIndex);
    posValidIdx = posLoc > 0;
    % defaultVal = NaN or 0
    newPosResistance = accumarray(posLoc(posValidIdx), posResistance(posValidIdx), [numel(edges)-1, 1], @mean, NaN);
    % fill missing data using Piecewise Cubic Hermite Interpolating Polynomial
    newPosResistance = fillmissing(newPosResistance, 'pchip');

    % Process neg-Sweep
    [~, ~, negLoc] = histcounts(data.FieldH(negIndex), edges);
    negResistance = data.VoltageV(negIndex) ./ data.CurrentA(negIndex);
    negValidIdx = negLoc > 0;
    % defaultVal = NaN or 0
    newNegResistance = accumarray(negLoc(negValidIdx), negResistance(negValidIdx), [numel(edges)-1, 1], @mean, NaN);
    % fill missing data using Piecewise Cubic Hermite Interpolating Polynomial
    newNegResistance = fillmissing(newNegResistance, 'pchip');

    % Calculate anti-symmetric component for pos-Sweep & neg-Sweep
    asymPosResistance = zeros(length(newFieldH), 1);
    asymNegResistance = zeros(length(newFieldH), 1);
    for posIndex = 1:length(newFieldH)
        negIndex = length(newFieldH) - posIndex + 1;
        asymPosResistance(posIndex) = (newPosResistance(posIndex) - newNegResistance(negIndex)) / 2;
        asymNegResistance(posIndex) = (newNegResistance(posIndex) - newPosResistance(negIndex)) / 2;
    end
    
    newData.newFieldH = [newFieldH, flip(newFieldH)];
    newData.newResistance = [asymPosResistance; asymNegResistance];
end
