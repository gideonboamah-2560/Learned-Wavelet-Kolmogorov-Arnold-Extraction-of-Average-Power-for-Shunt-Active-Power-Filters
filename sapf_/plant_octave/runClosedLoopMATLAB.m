function out = runClosedLoopMATLAB(ctrlFn, loadParams, T, weakGrid, wcHz)
%RUNCLOSEDLOOPMATLAB Closed-loop SAPF simulation entirely in Octave/MATLAB,
%   no Simulink required. Reduced-order plant (Rs/Ls/Lf/Rf/C/Vref),
%   inner current loop, and 5us/50us/100us plant/current/reference rates
%   as described in the manuscript; calls the real simulink/ctrl_*.m files.
%
%   ctrlFn: function handle matching ctrl_*.m signature:
%           [icA,icB,icC] = ctrlFn(vA,vB,vC,iLA,iLB,iLC,Vdc,VdcRef,Ts)
%   loadParams: struct passed to loadProfileEval (I1_0, step_t, ...)
%   weakGrid: true -> Ls=2mH, false -> Ls=0.1mH
%   wcHz: current-loop bandwidth (default 1500 Hz)

if nargin < 5, wcHz = 1500.0; end

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
vs = VM * cos(2*pi*F0*t - PHASE);           % n x 3
[iL, diL] = loadProfileEval(t, loadParams); % n x 3 each

ic = [0 0 0]; Vdc = VdcRef; integ = [0 0 0];
m = [0 0 0]; icRef = [0 0 0]; dicPrev = [0 0 0];

logEvery = 2; nlog = floor(n/logEvery);
Lis = zeros(nlog,3); Lic = zeros(nlog,3); Licref = zeros(nlog,3);
Lvdc = zeros(nlog,1);

for k = 1:n
    vsk = vs(k,:); iLk = iL(k,:); diLk = diL(k,:);
    if mod(k-1, curDecim) == 0
        vpcc = vsk - Rs*(iLk-ic) - Ls*(diLk-dicPrev);
        if mod(k-1, refDecim) == 0
            [a1,a2,a3] = ctrlFn(vpcc(1),vpcc(2),vpcc(3), iLk(1),iLk(2),iLk(3), Vdc, VdcRef, TsRef);
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
            Lis(j,:) = iLk - ic; Lic(j,:) = ic; Licref(j,:) = icRef; Lvdc(j) = Vdc;
        end
    end
end

tl = t(1:logEvery:end); tl = tl(1:nlog);
iLlog = iL(1:logEvery:end, :); iLlog = iLlog(1:nlog, :);

out.t = tl; out.i_s = Lis; out.i_c = Lic; out.ic_ref = Licref;
out.vdc = Lvdc; out.i_load = iLlog; out.dt = DT*logEvery;
end
