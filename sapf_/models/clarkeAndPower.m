function [vAlpha, vBeta, iAlpha, iBeta, p, q] = clarkeAndPower(vA, vB, vC, iLA, iLB, iLC)
%CLARKEANDPOWER Amplitude-invariant Clarke transform + instantaneous power.
%   Identical math to the inline version embedded in each generated
%   simulink/ctrl_*.m file (see scripts/exportControllerCode.m); kept here
%   as a standalone file so the multi-seed verification harness uses
%   exactly the same computation without duplicating it by hand.
vAlpha = (2/3)*(vA - 0.5*vB - 0.5*vC);
vBeta  = (2/3)*(sqrt(3)/2)*(vB - vC);
iAlpha = (2/3)*(iLA - 0.5*iLB - 0.5*iLC);
iBeta  = (2/3)*(sqrt(3)/2)*(iLB - iLC);
p = vAlpha*iAlpha + vBeta*iBeta;
q = vAlpha*iBeta  - vBeta*iAlpha;
end
