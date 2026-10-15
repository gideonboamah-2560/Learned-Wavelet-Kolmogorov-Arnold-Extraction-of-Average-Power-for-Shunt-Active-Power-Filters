function [Xn, yn, scale] = normalizeWindow(X, y)
%NORMALIZEWINDOW Scale each window by its own mean absolute value so the
%   networks see O(1) inputs regardless of the absolute power level.
scale = mean(abs(X), 2) + 1.0;   % (B x 1)
Xn = X ./ scale;
if nargin > 1 && nargout > 1
    yn = y(:) ./ scale;
end
end
