function [X, y] = genDataset(nScenarios, T, windowN, stride, seed)
%GENDATASET Build (X,y) regression pairs for the p_bar extraction task.
%   Each scenario is a synthetic p(t)-like signal made of:
%     - a slowly varying true level p_bar (with a random step, to test
%       transient response),
%     - harmonic ripple at 300/600/900/1200 Hz (from 5th/7th/11th/13th
%       load-current harmonics beating against the fundamental voltage),
%     - a "supraharmonic" burst at a random 2-9 kHz frequency (EV
%       charger / PV inverter emissions), on for a random sub-interval,
%     - small measurement noise.
%   X: (nSamples x windowN) past-window regressors
%   y: (nSamples x 1) true p_bar at the last sample of each window

if nargin < 1, nScenarios = 70; end
if nargin < 2, T = 0.6; end
if nargin < 3, windowN = 32; end
if nargin < 4, stride = 6; end
if nargin < 5, seed = 1; end

fsCtrl = 10000.0;
dt = 1.0 / fsCtrl;
rng(seed);

Xc = {}; yc = {};
for s = 1:nScenarios
    n = round(T * fsCtrl);
    t = (0:n-1) * dt;

    P0 = 1000 + 4000 * rand();
    pTrue = P0 * ones(1, n);
    if rand() < 0.6
        stepT = 0.15 + (T - 0.30) * rand();
        stepIdx = round(stepT * fsCtrl);
        P1 = P0 * (0.4 + 1.4 * rand());
        pTrue(stepIdx:end) = P1;
    end

    ripple = zeros(1, n);
    % 6-pulse-rectifier characteristic harmonics (5,7,11,13,...) produce
    % instantaneous-power ripple at the 6th/12th/18th/24th harmonic of the
    % fundamental: 300/600/900/1200 Hz at 50 Hz. (An earlier version used
    % 100/200/300/400 Hz, which was physically wrong.)
    fr = [300 600 900 1200];
    for k = 1:numel(fr)
        amp = P0 * 0.12 * rand();
        phase = 2*pi*rand();
        ripple = ripple + amp * sin(2*pi*fr(k)*t + phase);
    end

    supra = zeros(1, n);
    if rand() < 0.8
        fS = 2000 + 7000*rand();
        ampS = P0 * (0.02 + 0.13*rand());
        phaseS = 2*pi*rand();
        startT = 0.6*T*rand();
        durT = rand() * (T - startT - 0.05) + 0.05;
        i0 = max(1, round(startT*fsCtrl));
        i1 = min(n, round((startT+durT)*fsCtrl));
        idx = i0:i1;
        supra(idx) = ampS * sin(2*pi*fS*t(idx) + phaseS);
    end

    noise = P0 * 0.005 * randn(1, n);
    p = pTrue + ripple + supra + noise;

    for idx = (windowN+1):stride:n
        Xc{end+1} = p(idx-windowN:idx-1); %#ok<AGROW>
        yc{end+1} = pTrue(idx-1); %#ok<AGROW>
    end
end

X = cell2mat(Xc');
y = cell2mat(yc)';
end
