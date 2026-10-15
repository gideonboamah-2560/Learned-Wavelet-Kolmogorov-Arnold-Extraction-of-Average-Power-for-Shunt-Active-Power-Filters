function [y, cache] = wnnForward(params, fixed, X)
%WNNFORWARD X: (B x nIn) -> y: (B x 1)
z = X * params.v;                          % (B,K)
u = (z - fixed.b) ./ fixed.a;              % broadcast over rows
h = mexicanHat(u);
y = h * params.w + params.w0;

cache.X = X; cache.u = u; cache.h = h;
end
