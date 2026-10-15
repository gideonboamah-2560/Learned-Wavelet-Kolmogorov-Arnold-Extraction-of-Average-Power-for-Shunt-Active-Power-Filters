function [y, cache] = gruForward(params, X, H)
%GRUFORWARD X: (B x N) window, processed one timestep at a time.
[B, N] = size(X);
h = zeros(B, H);
steps = cell(N, 1);
for t = 1:N
    x_t = X(:, t);                                   % (B,1)
    r = sigmoid(x_t*params.Wr + h*params.Ur + params.br);
    z = sigmoid(x_t*params.Wz + h*params.Uz + params.bz);
    Un_h = h * params.Un;
    n_pre = x_t*params.Wn + r.*Un_h + params.bn;
    n = tanh(n_pre);
    h_prev = h;
    h = (1 - z).*n + z.*h_prev;
    steps{t} = struct('x_t', x_t, 'h_prev', h_prev, 'r', r, 'z', z, 'n', n, 'Un_h', Un_h);
end
y = h * params.Wo + params.bo;
cache.steps = steps; cache.h_T = h;
end

function s = sigmoid(x)
s = 1 ./ (1 + exp(-x));
end
