function [thdPct, mags, freqs] = computeTHD(x, fs, f0, maxHarmonic)
%COMPUTETHD FFT-based total harmonic distortion of a periodic waveform.
%   x          : time-domain samples (row or column vector), UNIFORMLY
%                sampled at fs [Hz]. Ideally pass an integer number of
%                fundamental cycles (e.g. exactly 10 cycles at f0=50Hz),
%                but a Hann window is applied so near-integer windows
%                still give a good estimate.
%   fs         : sample rate [Hz]
%   f0         : fundamental frequency [Hz] (e.g. 50)
%   maxHarmonic: highest harmonic order to include (default 40)
%
%   thdPct : THD in percent, standard definition
%            THD = sqrt(sum(H_2..H_max .^2)) / H_1 * 100
%   mags   : magnitude of each harmonic 1..maxHarmonic (mags(1)=fundamental)
%   freqs  : corresponding frequencies

if nargin < 4, maxHarmonic = 40; end
x = x(:);
Nsig = numel(x);

w = hann(Nsig, 'periodic');
xw = x .* w;
Xf = fft(xw);
Nfft = Nsig;
df = fs / Nfft;

% coherent-gain correction for the Hann window (~0.5 for periodic Hann)
cg = mean(w);

mags = zeros(1, maxHarmonic);
freqs = (1:maxHarmonic) * f0;
searchBinsHalfWidth = max(1, round((f0*0.4) / df));  % tolerance window around each harmonic

for h = 1:maxHarmonic
    targetBin = round(freqs(h)/df) + 1;   % +1 for 1-based indexing
    lo = max(1, targetBin - searchBinsHalfWidth);
    hi = min(floor(Nfft/2), targetBin + searchBinsHalfWidth);
    if lo > hi
        mags(h) = 0;
        continue;
    end
    [pk, idx] = max(abs(Xf(lo:hi)));
    mags(h) = 2 * pk / (Nsig * cg);   % single-sided amplitude
end

fundamental = mags(1);
if fundamental < eps
    thdPct = NaN;
else
    thdPct = 100 * sqrt(sum(mags(2:end).^2)) / fundamental;
end
end

function w = hann(N, sflag)
if nargin < 2, sflag = 'symmetric'; end
if strcmp(sflag, 'periodic')
    n = (0:N-1)';
    w = 0.5 - 0.5*cos(2*pi*n/N);
else
    n = (0:N-1)';
    w = 0.5 - 0.5*cos(2*pi*n/(N-1));
end
end
