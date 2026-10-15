function [params, opt] = trainLoop(stepFn, params, opt, X, y, epochs, batchSize, tag, predictFn, Xval, yval)
%TRAINLOOP Generic mini-batch training loop with best-checkpoint selection.
%   stepFn(params, opt, Xbatch, ybatch) -> [params, opt, loss]
%   If predictFn/Xval/yval are given, the parameters from the epoch with
%   the lowest validation MSE are returned instead of simply the last
%   epoch's parameters (early-stopping-style checkpointing, applied
%   identically to every trained controller for a fair comparison).
doVal = nargin >= 11 && ~isempty(Xval);
bestParams = params; bestValLoss = inf;
n = size(X, 1);
for ep = 1:epochs
    idx = randperm(n);
    Xs = X(idx, :); ys = y(idx);
    totLoss = 0; nb = 0;
    for i = 1:batchSize:n
        j = min(i+batchSize-1, n);
        if (j - i) < 3, continue; end
        [params, opt, loss] = stepFn(params, opt, Xs(i:j, :), ys(i:j));
        totLoss = totLoss + loss; nb = nb + 1;
    end
    trLoss = totLoss/max(nb,1);
    msg = sprintf('  [%s] epoch %3d  trainLoss=%.6f', tag, ep, trLoss);
    if doVal
        yhat = predictFn(params, Xval);
        valLoss = mean((yhat(:) - yval(:)).^2);
        msg = [msg sprintf('  valLoss=%.6f', valLoss)];
        if valLoss < bestValLoss
            bestValLoss = valLoss;
            bestParams = params;
            msg = [msg '  *'];
        end
    end
    if mod(ep,5)==0 || ep==epochs
        fprintf('%s\n', msg);
    end
end
if doVal
    params = bestParams;
    fprintf('  [%s] using best checkpoint, valLoss=%.6f\n', tag, bestValLoss);
end
end
