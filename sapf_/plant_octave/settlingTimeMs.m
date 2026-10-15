function settleMs = settlingTimeMs(errSig, t, stepT, dt, finalAmp)
%SETTLINGTIMEMS Time from stepT until the 5ms moving-RMS envelope of
%   errSig first stays within (steady-state error + 3% of finalAmp).
cyc5ms = max(1, round(0.005/dt));
n = numel(errSig);
sq = errSig.^2;
c = cumsum([0; sq(:)]);
env = nan(n,1);
idx = cyc5ms:n;
env(idx) = sqrt((c(idx+1) - c(idx-cyc5ms+1)) / cyc5ms);

idx0 = find(t >= stepT, 1, 'first');
ssErr = sqrt(mean(errSig(max(1,n-2000):n).^2));
thr = ssErr + 0.03*finalAmp;

afterIdx = (idx0:n)';
bad = afterIdx(env(afterIdx) > thr);
if isempty(bad)
    settleMs = 0.0;
else
    settleMs = 1000 * (t(bad(end)) - stepT);
end
end
