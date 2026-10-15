function [i, di] = loadProfileEval(t, p)
%LOADPROFILEEVAL Vectorized 3-phase load current + exact time-derivative.
%   6-pulse-rectifier harmonic profile with optional load step and
%   supraharmonic burst; returns the exact analytic derivative.
%   p fields (all optional except I1_0): I1_1, step_t, step_tau,
%   supra_on, supra_f, supra_amp_frac, supra_t0, supra_t1.
F0 = 50; w0 = 2*pi*F0;
PHASE = [0, -2*pi/3, 2*pi/3];
n = numel(t);

if ~isfield(p,'I1_1') || isempty(p.I1_1), p.I1_1 = p.I1_0; end
if ~isfield(p,'step_t'), p.step_t = []; end
if ~isfield(p,'step_tau'), p.step_tau = 2e-3; end
if ~isfield(p,'supra_on'), p.supra_on = false; end
if ~isfield(p,'supra_f'), p.supra_f = 5000; end
if ~isfield(p,'supra_amp_frac'), p.supra_amp_frac = 0.08; end
if ~isfield(p,'supra_t0'), p.supra_t0 = 0; end
if ~isfield(p,'supra_t1'), p.supra_t1 = 1e9; end

if isempty(p.step_t)
    I1 = repmat(p.I1_0, n, 1); dI1 = zeros(n,1);
else
    x = (t - p.step_t) / p.step_tau;
    xin = min(max(x,0),1);
    I1 = p.I1_0 + (p.I1_1 - p.I1_0) * (3*xin.^2 - 2*xin.^3);
    g = 6*xin.*(1-xin) / p.step_tau;
    g(x < 0 | x > 1) = 0;
    dI1 = (p.I1_1 - p.I1_0) * g;
end

% 6-pulse rectifier characteristic harmonics: [order, fraction, sequence]
harmonics = [5 0.17 -1; 7 0.11 1; 11 0.045 -1; 13 0.03 1];

i = zeros(n,3); di = zeros(n,3);
for kph = 1:3
    ph = PHASE(kph);
    ang = w0*t - ph;
    i(:,kph)  = i(:,kph)  + I1.*cos(ang);
    di(:,kph) = di(:,kph) + dI1.*cos(ang) - I1*w0.*sin(ang);
    for hh = 1:size(harmonics,1)
        h = harmonics(hh,1); frac = harmonics(hh,2); seq = harmonics(hh,3);
        a = seq*h*w0*t - ph;
        amp = frac*I1; damp = frac*dI1;
        i(:,kph)  = i(:,kph)  + amp.*cos(a);
        di(:,kph) = di(:,kph) + damp.*cos(a) - amp*seq*h*w0.*sin(a);
    end
    if p.supra_on
        ws = 2*pi*p.supra_f;
        mask = (t >= p.supra_t0) & (t <= p.supra_t1);
        a = ws*t - ph;
        supAmp = p.supra_amp_frac * p.I1_0;
        i(:,kph)  = i(:,kph)  + mask.*(supAmp*cos(a));
        di(:,kph) = di(:,kph) + mask.*(-supAmp*ws*sin(a));
    end
end
end
