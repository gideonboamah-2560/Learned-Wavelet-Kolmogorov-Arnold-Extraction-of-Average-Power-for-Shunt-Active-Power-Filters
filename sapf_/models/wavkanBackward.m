function grads = wavkanBackward(params, cache, dY)
%WAVKANBACKWARD dY: (B x 1) upstream gradient dL/dy
X = cache.X; u = cache.u; psi_u = cache.psi_u; h = cache.h;
v = cache.v; psi_v = cache.psi_v;
[B, nIn] = size(X);
nHidden = size(params.a1, 2);

a2r = params.a2'; c2r = params.c2';

dpsiv = mexicanHatGrad(v);                     % (B,nHidden)
grads.c2 = reshape(mean(dY .* psi_v, 1), [nHidden, 1]);

dv = (dY .* c2r) .* dpsiv;                     % (B,nHidden)
grads.a2 = reshape(mean(dv .* (-v ./ a2r), 1), [nHidden, 1]);
grads.b2 = reshape(mean(dv .* (-1 ./ a2r), 1), [nHidden, 1]);
grads.bias = mean(dY);

dh = dv ./ a2r;                                % (B,nHidden)

a13 = reshape(params.a1, [1, nIn, nHidden]);
c13 = reshape(params.c1, [1, nIn, nHidden]);
dpsiu = mexicanHatGrad(u);                     % (B,nIn,nHidden)
g = reshape(dh, [B, 1, nHidden]);              % broadcast over nIn

grads.c1 = reshape(mean(g .* psi_u, 1), [nIn, nHidden]);
du = g .* c13 .* dpsiu;                        % (B,nIn,nHidden)
grads.a1 = reshape(mean(du .* (-u ./ a13), 1), [nIn, nHidden]);
grads.b1 = reshape(mean(du .* (-1 ./ a13), 1), [nIn, nHidden]);
end
