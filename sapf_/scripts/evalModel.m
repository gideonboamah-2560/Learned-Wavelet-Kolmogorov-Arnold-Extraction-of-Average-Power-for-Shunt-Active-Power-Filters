function [rmse, mae] = evalModel(name, predictFn, X, y, scale)
%EVALMODEL Back-scale predictions to Watts and report RMSE/MAE.
yhat = predictFn(X);
yhat = yhat(:);
errW = (yhat - y(:)) .* scale(:);
rmse = sqrt(mean(errW.^2));
mae = mean(abs(errW));
fprintf('  %-10s  RMSE=%8.2f W   MAE=%8.2f W\n', name, rmse, mae);
end
