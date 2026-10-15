function [params, opt, loss] = wnnTrainStep(params, fixed, opt, X, yTrue)
[yPred, cache] = wnnForward(params, fixed, X);
err = yPred - yTrue;
loss = mean(err.^2);
dY = 2 * err / numel(err);
grads = wnnBackward(params, fixed, cache, dY);
[params, opt] = adamStep(params, grads, opt);
end
