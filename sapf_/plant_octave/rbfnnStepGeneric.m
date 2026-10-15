function [pbar, state] = rbfnnStepGeneric(p, state, net)
state = [state(2:end), p];
scale = mean(abs(state)) + 1.0;
xn = state / scale;
phi = rbfnnBasis(xn, net.centers, net.sigma);
y = phi * net.w + net.bias;
pbar = y * scale;
end
