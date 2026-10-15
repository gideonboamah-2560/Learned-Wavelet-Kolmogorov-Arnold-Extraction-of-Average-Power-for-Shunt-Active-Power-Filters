function grads = wnnBackward(params, fixed, cache, dY)
%WNNBACKWARD dY: (B x 1) upstream gradient dL/dy
X = cache.X; u = cache.u; h = cache.h;
B = size(X, 1);

grads.w  = (h' * dY) / B;
grads.w0 = sum(dY) / B;

dh = dY * params.w';              % (B,K)
du = dh .* mexicanHatGrad(u);
dz = du ./ fixed.a;
grads.v = (X' * dz) / B;
end
