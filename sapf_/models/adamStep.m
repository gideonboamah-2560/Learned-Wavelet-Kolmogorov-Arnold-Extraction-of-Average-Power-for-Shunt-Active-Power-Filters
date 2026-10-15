function [params, opt] = adamStep(params, grads, opt)
%ADAMSTEP One Adam update over every field present in grads.
opt.t = opt.t + 1;
fn = fieldnames(grads);
for i = 1:numel(fn)
    k = fn{i};
    opt.m.(k) = opt.b1 * opt.m.(k) + (1 - opt.b1) * grads.(k);
    opt.v.(k) = opt.b2 * opt.v.(k) + (1 - opt.b2) * (grads.(k) .^ 2);
    mhat = opt.m.(k) / (1 - opt.b1^opt.t);
    vhat = opt.v.(k) / (1 - opt.b2^opt.t);
    params.(k) = params.(k) - opt.lr * mhat ./ (sqrt(vhat) + opt.eps);
end
end
