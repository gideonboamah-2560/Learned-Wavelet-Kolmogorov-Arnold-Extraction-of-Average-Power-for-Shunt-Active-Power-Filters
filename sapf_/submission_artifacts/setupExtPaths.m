% setupExtPaths.m -- the extension reaches the APPROVED project READ-ONLY.
% It never writes inside sapf_matlab/. Run with run('setupExtPaths.m').
EXT_ROOT    = fileparts(mfilename('fullpath'));
FROZEN_ROOT = fullfile(EXT_ROOT, '..', 'sapf_matlab');
addpath(fullfile(FROZEN_ROOT,'plant_octave'));
addpath(fullfile(FROZEN_ROOT,'models'));
addpath(fullfile(FROZEN_ROOT,'scripts'));
addpath(fullfile(FROZEN_ROOT,'simulink_automation'));
addpath(fullfile(FROZEN_ROOT,'simulink'));
addpath(EXT_ROOT);
