% checkHarnessConsistency.m
% Reproduces the consistency claim in the manuscript: the study harness
% (runClosedLoopGeneric) and the deployed MATLAB-Function-block controller
% (simulink/ctrl_wavkan.m, trained weights embedded) give the same closed-loop
% result. Read-only use of the approved project.
run(fullfile(fileparts(mfilename('fullpath')),'setupExtPaths.m'));
S = load(fullfile(FROZEN_ROOT,'results','trainedControllers.mat'));
p.I1_0 = 20.0;
a = runClosedLoopMATLAB(@ctrl_wavkan, p, 0.05, false);
b = runClosedLoopGeneric(@(pp,st) wavkanStepGeneric(pp,st,S.wkP), zeros(1,32), p, 0.05, false);
printf('max |source-current difference| = %.3e A\n', max(abs(a.i_s(:)-b.i_s(:))));
printf('max |DC-link voltage difference| = %.3e V\n', max(abs(a.vdc(:)-b.vdc(:))));
