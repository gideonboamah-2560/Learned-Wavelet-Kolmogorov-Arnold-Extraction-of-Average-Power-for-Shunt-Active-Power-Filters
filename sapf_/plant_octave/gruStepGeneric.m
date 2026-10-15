function [pbar, state] = gruStepGeneric(p, state, params, H)
state = [state(2:end), p];
scale = mean(abs(state)) + 1.0;
y = gruForward(params, state/scale, H);
pbar = y * scale;
end
