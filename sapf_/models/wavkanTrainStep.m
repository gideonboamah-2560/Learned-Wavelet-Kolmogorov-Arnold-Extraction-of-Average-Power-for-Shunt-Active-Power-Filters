function [params, opt, loss] = wavkanTrainStep(params, opt, X, yTrue)
[yPred, cache] = wavkanForward(params, X);
err = yPred - yTrue;
loss = mean(err.^2);
dY = 2 * err / numel(err);
grads = wavkanBackward(params, cache, dY);
[params, opt] = adamStep(params, grads, opt);

aMin = 0.15; aMax = 8.0;
params.a1 = min(max(params.a1, aMin), aMax);
params.a2 = min(max(params.a2, aMin), aMax);
end
