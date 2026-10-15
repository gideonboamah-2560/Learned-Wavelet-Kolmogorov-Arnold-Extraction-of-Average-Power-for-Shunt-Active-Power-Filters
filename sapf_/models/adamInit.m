function opt = adamInit(params, lr)
%ADAMINIT Create Adam optimizer state matching every field of params.
if nargin < 2, lr = 0.01; end
opt.lr = lr; opt.b1 = 0.9; opt.b2 = 0.999; opt.eps = 1e-8; opt.t = 0;
fn = fieldnames(params);
for i = 1:numel(fn)
    opt.m.(fn{i}) = zeros(size(params.(fn{i})));
    opt.v.(fn{i}) = zeros(size(params.(fn{i})));
end
end
