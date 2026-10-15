function [pbar, state] = wavkanStepGeneric(p, state, params)
%WAVKANSTEPGENERIC state is the sliding window buffer (1 x windowN).
state = [state(2:end), p];
scale = mean(abs(state)) + 1.0;
y = wavkanForward(params, state/scale);
pbar = y * scale;
end
