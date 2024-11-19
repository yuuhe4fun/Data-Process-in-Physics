function y = fitCurrent(params, x, direction)

    % 提取参数
    Ic = params(1);
    Rn = params(2);
    Rsg = params(3);

    % 初始化输出数组
    y = zeros(size(x));

    % 根据方向进行处理
    if strcmp(direction, 'pos')  % 正方向（icpFit）
        y(x < Ic) = Rsg * x(x < Ic);
        y(x >= Ic) = Ic * Rn * sqrt(max((x(x >= Ic) / Ic).^2 - 1, 0)) + Rsg * x(x >= Ic);
    elseif strcmp(direction, 'neg')  % 负方向（icmFit）
        y(x > Ic) = Rsg * x(x > Ic);
        y(x <= Ic) = Ic * Rn * sqrt(max((x(x <= Ic) / Ic).^2 - 1, 0)) + Rsg * x(x <= Ic);
    else
        error('Invalid direction. Use ''pos'' or ''neg''.');
    end
end
