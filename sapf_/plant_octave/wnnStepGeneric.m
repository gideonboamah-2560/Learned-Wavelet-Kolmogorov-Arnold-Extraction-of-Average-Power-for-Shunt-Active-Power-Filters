function [pbar, state] = wnnStepGeneric(p, state, params, fixed)
state = [state(2:end), p];
scale = mean(abs(state)) + 1.0;
y = wnnForward(params, fixed, state/scale);
pbar = y * scale;
end
