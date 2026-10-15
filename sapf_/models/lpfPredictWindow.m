function y = lpfPredictWindow(X, b, a, warmupLen)
%LPFPREDICTWINDOW Causal biquad filtering of each row of X independently,
%   with a steady-state warm-up (repeat first sample) so the filter isn't
%   starting from zero state. Returns the filtered value at the LAST
%   sample of each window (B x 1), matching the other controllers' output.
if nargin < 4, warmupLen = 50; end
[Bn, N] = size(X);
y = zeros(Bn, 1);
for i = 1:Bn
    xi = X(i, :);
    seq = [repmat(xi(1), 1, warmupLen), xi];
    yi = filter(b, a, seq);
    y(i) = yi(end);
end
end
