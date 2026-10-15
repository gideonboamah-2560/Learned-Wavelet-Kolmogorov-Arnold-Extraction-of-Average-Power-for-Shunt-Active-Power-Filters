function [pbar, state] = adalineStepGeneric(p, state, harmonics, mu, dt)
%ADALINESTEPGENERIC Fourier-basis adaptive linear neuron (Widrow-Hoff LMS),
%   the dominant real SAPF harmonic-extraction technique in the
%   literature. state = [w(1:nW), t] where w(1) is the DC weight (the
%   p_bar estimate) and t is elapsed time (needed for phase-continuous
%   reference sinusoids). NOT pretrained -- state should be initialized
%   to zeros(1,nW+1), a true cold start, matching how these are deployed
%   in the cited papers.
nH = numel(harmonics);
nW = 1 + 2*nH;
w = state(1:nW);
t = state(nW+1);

r = zeros(1, nW);
r(1) = 1.0;
for i = 1:nH
    ang = 2*pi*harmonics(i)*t;
    r(2*i)   = cos(ang);
    r(2*i+1) = sin(ang);
end
p_hat = w * r';
err = p - p_hat;
w = w + mu * err * r / nW;

pbar = w(1);
state = [w, t + dt];
end
