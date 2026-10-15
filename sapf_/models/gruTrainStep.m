function [params, opt, loss] = gruTrainStep(params, opt, X, yTrue, H)
[yPred, cache] = gruForward(params, X, H);
err = yPred - yTrue;
loss = mean(err.^2);
dY = 2 * err / numel(err);
grads = gruBackward(params, cache, dY, H);
[params, opt] = adamStep(params, grads, opt);
end
