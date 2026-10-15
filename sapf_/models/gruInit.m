function [params, opt, H] = gruInit(nIn, hidden, seed)
%GRUINIT Small single-layer GRU reading the window one sample at a time,
%   linear readout from the final hidden state -> scalar p_bar estimate.
if nargin < 3, seed = 1; end
rng(seed);
H = hidden;
s = 0.3;
params.Wr = s*randn(1,H); params.Ur = s*randn(H,H); params.br = zeros(1,H);
params.Wz = s*randn(1,H); params.Uz = s*randn(H,H); params.bz = zeros(1,H);
params.Wn = s*randn(1,H); params.Un = s*randn(H,H); params.bn = zeros(1,H);
params.Wo = s*randn(H,1); params.bo = 0;

opt = adamInit(params, 0.01);
end
