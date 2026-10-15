function out = runClosedLoopGeneric(extractFn, stateInit, loadParams, T, weakGrid, wcHz)
%RUNCLOSEDLOOPGENERIC Closed-loop SAPF simulation for the multi-seed
%   verification study. extractFn: [pbar, newState] = extractFn(p, state).
%   Uses the SAME clarkeAndPower.m / dcRegAndInvClarke.m as the generated
%   Simulink controllers (models/), so this tests the identical reference-
%   generation algorithm, just without regenerating a ctrl_*.m file for
%   every one of the (4 seeds x 3 learned models) combinations.

if nargin < 6, wcHz = 1500.0; end

F0 = 50; VM = 230*sqrt(2);
if weakGrid, Rs = 0.1; Ls = 2.0e-3; else, Rs = 0.1; Ls = 0.1e-3; end
Lf = 3e-3; Rf = 0.05; Cdc = 2000e-6; VdcRef = 800.0;

DT = 5e-6; TsCur = 50e-6; TsRef = 100e-6;
curDecim = round(TsCur/DT); refDecim = round(TsRef/DT);
PHASE = [0, -2*pi/3, 2*pi/3];
Ltot = Lf + Ls;
KpI = 2*pi*wcHz*Lf; KiI = 2*pi*wcHz*Rf;

n = round(T/DT);
t = (0:n-1)' * DT;
vs = VM * cos(2*pi*F0*t - PHASE);
[iL, diL] = loadProfileEval(t, loadParams);

ic = [0 0 0]; Vdc = VdcRef; integ = [0 0 0];
m = [0 0 0]; icRef = [0 0 0]; dicPrev = [0 0 0];
dcInt = 0; state = stateInit;

logEvery = 2; nlog = floor(n/logEvery);
Lis = zeros(nlog,3); Lvdc = zeros(nlog,1);

for k = 1:n
    vsk = vs(k,:); iLk = iL(k,:); diLk = diL(k,:);
    if mod(k-1, curDecim) == 0
        vpcc = vsk - Rs*(iLk-ic) - Ls*(diLk-dicPrev);
        if mod(k-1, refDecim) == 0
            [vAlpha,vBeta,~,~,p,q] = clarkeAndPower(vpcc(1),vpcc(2),vpcc(3), iLk(1),iLk(2),iLk(3));
            [pbar, state] = extractFn(p, state);
            [a1,a2,a3,dcInt] = dcRegAndInvClarke(p, q, pbar, Vdc, VdcRef, TsRef, dcInt, vAlpha, vBeta);
            icRef = [a1,a2,a3];
        end
        e = icRef - ic;
        half = Vdc/2;
        vUnsat = KpI*e + integ + vpcc;
        vCmd = min(max(vUnsat, -0.98*half), 0.98*half);
        sat = (vCmd ~= vUnsat);
        integ = integ + (~sat) .* (KiI*e*TsCur);
        m = vCmd / half;
    end
    vinv = m * Vdc / 2;
    dic = (vinv - vsk - (Rf+Rs)*ic + Rs*iLk + Ls*diLk) / Ltot;
    ic = ic + DT*dic;
    dicPrev = dic;
    Vdc = max(Vdc - DT*sum(m.*ic)/(2*Cdc), 50);

    if mod(k-1, logEvery) == 0
        j = floor((k-1)/logEvery) + 1;
        if j <= nlog
            Lis(j,:) = iLk - ic; Lvdc(j) = Vdc;
        end
    end
end

tl = t(1:logEvery:end); tl = tl(1:nlog);
out.t = tl; out.i_s = Lis; out.vdc = Lvdc; out.dt = DT*logEvery;
end
