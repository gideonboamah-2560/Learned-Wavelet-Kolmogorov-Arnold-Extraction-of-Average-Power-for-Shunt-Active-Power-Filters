function blockPath = resolveLibBlockR2026a(blockName, extraLibs)
%RESOLVELIBBLOCKR2026A Find a native Simscape Electrical block by NAME.
%
%   R2026a removed the Specialized Power Systems library entirely, so
%   the R2021a-era resolveLibBlock.m (which tried 'sps_lib'/'powerlib')
%   will not find anything -- those libraries no longer exist, they are
%   not just renamed. This version searches the native Simscape Electrical
%   library tree instead.
%
%   IMPORTANT CAVEAT: I could not test this against a real R2026a
%   installation (no MATLAB/Simulink available in the environment this
%   was written in). The top-level library names below ('sm_lib' /
%   'ee_lib' / 'simscape' as candidates for the native Electrical tree)
%   are best-effort guesses based on documentation, NOT confirmed working
%   add_block/load_system arguments the way 'sps_lib' was confirmed for
%   the legacy library. If none of these load, open the Simulink Library
%   Browser, find Simscape > Electrical, right-click a block in it, and
%   use "Show block in Simulink Library Browser" or hover to find the
%   actual top-level system name, then pass it in extraLibs.
%
%   Example:
%       resolveLibBlockR2026a('Voltage Source (Three-Phase)')
%       resolveLibBlockR2026a('Controlled Current Source (Three-Phase)')
%       resolveLibBlockR2026a('Universal Bridge')

candidates = {'sm_lib', 'ee_lib', 'simscape', 'foundation_electrical'};
if nargin > 1 && ~isempty(extraLibs)
    candidates = [extraLibs, candidates];
end

for i = 1:numel(candidates)
    lib = candidates{i};
    try
        load_system(lib);
    catch
        continue
    end
    try
        hits = find_system(lib, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'Name', blockName);
    catch
        hits = {};
    end
    if ~isempty(hits)
        blockPath = hits{1};
        return
    end
end

error('resolveLibBlockR2026a:notFound', [ ...
    'Could not auto-locate native block "%s". This is expected -- the\n' ...
    'exact top-level library system name for native Simscape Electrical\n' ...
    'was not confirmed at the time this was written (R2026a is very\n' ...
    'recent). Open the Simulink Library Browser, navigate to\n' ...
    'Simscape > Electrical > ... , find "%s", and either:\n' ...
    '  (a) drag it into your model by hand, or\n' ...
    '  (b) right-click it -> Help, which will show the block''s help page\n' ...
    '      with its Library: line giving the exact path, then call\n' ...
    '      resolveLibBlockR2026a(''%s'', {''<that library>''}).'], ...
    blockName, blockName, blockName);
end
