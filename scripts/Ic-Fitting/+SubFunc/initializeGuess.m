function initialGuess = initializeGuess(x, y, PorN)
    % Calculate the derivative of voltage (y) with respect to current (x)
    dy_dx = gradient(y) ./ gradient(x);  % Numerical derivative

    % Find the index of the maximum absolute derivative (most sharply changed position)
    [~, sharpChangeIdx] = max(abs(dy_dx));

    % If no sharp change is found, use the average of the current
    if isempty(sharpChangeIdx)
        IcGuess = 0.5 * (x(1) + x(end)); % Default guess if no sharp change
    else
        IcGuess = x(sharpChangeIdx); % Use current value at the sharp change index
    end

    switch PorN
        case 'POS'
            RsgGuessFunc = polyfit(x(1:100),y(1:100),1);
            RsgGuess = RsgGuessFunc(1);
            RnGuessFunc = polyfit(x(end-500:end),y(end-500:end),1);
            RnGuess = RnGuessFunc(1);
            initialGuess = [IcGuess, RnGuess, RsgGuess];

        case 'NEG'
            RsgGuessFunc = polyfit(x(end-100:end),y(end-100:end),1);
            RsgGuess = RsgGuessFunc(1);
            RnGuessFunc = polyfit(x(1:500),y(1:500),1);
            RnGuess = RnGuessFunc(1);
            initialGuess = [IcGuess, RnGuess, RsgGuess];
        otherwise
            error('Unsupported PorN value');
    end
end