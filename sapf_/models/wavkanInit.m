function [params, opt] = wavkanInit(nIn, nHidden, seed)
%WAVKANINIT Two-layer wavelet Kolmogorov-Arnold network.
%   Layer 1 (nIn -> nHidden): h_k = sum_j c1(j,k)*psi((x_j-b1(j,k))/a1(j,k))
%   Layer 2 (nHidden -> 1)  : y   = sum_k c2(k)*psi((h_k-b2(k))/a2(k)) + bias
%   UNLIKE FixedWNN, a1,b1,a2,b2 (scale & translation) are ALL trainable.
if nargin < 3, seed = 2; end
rng(seed);

params.a1 = 0.8 + 0.6*rand(nIn, nHidden);
params.b1 = 0.5 * randn(nIn, nHidden);
params.c1 = 0.2 * randn(nIn, nHidden);

params.a2 = 0.8 + 0.6*rand(nHidden, 1);
params.b2 = 0.5 * randn(nHidden, 1);
params.c2 = 0.5 * randn(nHidden, 1);
params.bias = 0;

opt = adamInit(params, 0.005);
end
