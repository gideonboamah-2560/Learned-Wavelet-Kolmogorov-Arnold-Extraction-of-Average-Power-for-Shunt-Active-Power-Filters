function [icRefA, icRefB, icRefC, dcInt] = dcRegAndInvClarke(p, q, pbar, Vdc, VdcRef, Ts, dcInt, vAlpha, vBeta)
%DCREGANDINVCLARKE DC-link PI regulation + full reactive-power compensation
%   + inverse Clarke transform. Same math (and same corrected qc sign) as
%   scripts/exportControllerCode.m's sharedSubfunctions(); kept standalone
%   here so the verification harness can't drift out of sync with the
%   Simulink-deployed controller code.
Kp_dc = 112.6; Ki_dc = 4043;   % wn=2*pi*8 rad/s, zeta=0.7, C=2000uF, Vref=800V
errDc = VdcRef - Vdc;
dcInt = dcInt + Ki_dc*errDc*Ts;
dP = Kp_dc*errDc + dcInt;

pc = p - pbar - dP;
qc = q;

denom = vAlpha^2 + vBeta^2 + 1e-6;
icAlpha = (vAlpha*pc - vBeta*qc) / denom;
icBeta  = (vBeta*pc + vAlpha*qc) / denom;

icRefA = icAlpha;
icRefB = -0.5*icAlpha + (sqrt(3)/2)*icBeta;
icRefC = -0.5*icAlpha - (sqrt(3)/2)*icBeta;
end
