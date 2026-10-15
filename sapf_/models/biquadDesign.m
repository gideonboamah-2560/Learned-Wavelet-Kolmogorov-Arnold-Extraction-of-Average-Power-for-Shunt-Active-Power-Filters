function [b, a] = biquadDesign(fc, fs)
%BIQUADDESIGN 2nd-order Butterworth-Q (Q=0.7071) low-pass biquad.
%   Classical p-q theory extraction stage. No Signal Processing Toolbox
%   required (RBJ audio-EQ-cookbook formulas).
Q = 1/sqrt(2);
w0 = 2*pi*fc/fs;
alphaQ = sin(w0) / (2*Q);
cosw0 = cos(w0);

b0 = (1 - cosw0)/2; b1 = 1 - cosw0; b2 = (1 - cosw0)/2;
a0 = 1 + alphaQ;     a1 = -2*cosw0;  a2 = 1 - alphaQ;

b = [b0 b1 b2] / a0;
a = [1  a1/a0  a2/a0];
end
