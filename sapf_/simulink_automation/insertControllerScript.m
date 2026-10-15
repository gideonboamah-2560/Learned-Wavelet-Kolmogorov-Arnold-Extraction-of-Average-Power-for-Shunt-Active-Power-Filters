function insertControllerScript(modelName, blockPath, controllerFile)
%INSERTCONTROLLERSCRIPT Populate an existing MATLAB Function block with
%   the contents of one of simulink/ctrl_pq_pi.m, ctrl_fixed_wnn.m,
%   ctrl_gru.m, ctrl_wavkan.m -- so you don't have to copy-paste by hand
%   every time you switch controllers for a comparison run.
%
%   Usage (with your model open):
%       insertControllerScript('sapf_model', 'sapf_model/SAPF_Controller', ...
%                               'simulink/ctrl_wavkan.m')
%
%   This uses the documented Stateflow.EMChart programmatic interface for
%   MATLAB Function blocks (see MathWorks: "Configure MATLAB Function
%   Blocks Programmatically"). If the block doesn't exist yet, it is
%   created first at blockPath.
%
%   IMPORTANT: MATLAB Function block "Script" text must NOT include the
%   leading "function ..." signature line duplicated -- the Script
%   property expects the function body starting from "function ...".
%   Passing the whole file (as read by fileread) is exactly right, per
%   MathWorks' own documented example.

if ~bdIsLoaded(modelName)
    open_system(modelName);
end

if isempty(find_system(modelName, 'SearchDepth', 1, 'Name', localBlockName(blockPath)))
    add_block('simulink/User-Defined Functions/MATLAB Function', blockPath);
    fprintf('Created new MATLAB Function block at %s\n', blockPath);
end

chart = find(get_param(modelName, 'Object'), '-isa', 'Stateflow.EMChart', 'Path', blockPath);
if isempty(chart)
    error('insertControllerScript:noChart', ...
        'Could not find the Stateflow.EMChart object for %s. Is it really a MATLAB Function block?', blockPath);
end

chart.Script = fileread(controllerFile);
fprintf('Loaded %s into %s\n', controllerFile, blockPath);
end

function name = localBlockName(blockPath)
parts = strsplit(blockPath, '/');
name = parts{end};
end
