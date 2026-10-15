function [y, cache] = wavkanForward(params, X)
%WAVKANFORWARD X: (B x nIn) -> y: (B x 1)
[B, nIn] = size(X);
nHidden = size(params.a1, 2);

X3  = reshape(X, [B, nIn, 1]);
a13 = reshape(params.a1, [1, nIn, nHidden]);
b13 = reshape(params.b1, [1, nIn, nHidden]);
c13 = reshape(params.c1, [1, nIn, nHidden]);

u = (X3 - b13) ./ a13;                 % (B,nIn,nHidden)
psi_u = mexicanHat(u);
edge1 = c13 .* psi_u;
h = reshape(sum(edge1, 2), [B, nHidden]);   % (B,nHidden)

a2r = params.a2';  % (1,nHidden)
b2r = params.b2';
c2r = params.c2';

v = (h - b2r) ./ a2r;                  % (B,nHidden)
psi_v = mexicanHat(v);
y = sum(psi_v .* c2r, 2) + params.bias;   % (B,1)

cache.X = X; cache.u = u; cache.psi_u = psi_u; cache.h = h;
cache.v = v; cache.psi_v = psi_v;
end
