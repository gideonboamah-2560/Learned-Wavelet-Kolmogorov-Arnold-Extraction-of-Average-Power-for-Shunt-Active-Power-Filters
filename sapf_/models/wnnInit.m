function [params, fixed, opt] = wnnInit(nIn, nHidden, seed)
%WNNINIT Fixed-wavelet WNN (Zhang & Benveniste wavelon):
%   z_k = x . v_k                (trainable input weights v)
%   h_k = psi((z_k - b_k)/a_k)   (a_k, b_k FIXED, not trained)
%   y   = h . w + w0             (trainable output weights w)
if nargin < 3, seed = 0; end
rng(seed);
base = repmat([1.0 2.0 4.0], 1, ceil(nHidden/3));
fixed.a = base(1:nHidden);
fixed.b = linspace(-2.0, 2.0, nHidden);

params.v  = 0.15 * randn(nIn, nHidden);
params.w  = 0.15 * randn(nHidden, 1);
params.w0 = 0;

opt = adamInit(params, 0.02);
end
