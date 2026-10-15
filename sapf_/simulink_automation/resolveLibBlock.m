function blockPath = resolveLibBlock(blockName, extraLibs)
%RESOLVELIBBLOCK Find a Specialized Power Systems (or base Simulink)
%   library block by its NAME rather than a hardcoded full path, since
%   full library paths have shifted across MATLAB releases (the
%   underlying system has been called both 'powerlib' and 'sps_lib' at
%   different times) but block NAMES are stable.
%
%   In MATLAB R2021a both names below should resolve (sps_lib is what
%   recent MathWorks documentation/answers use when scripting; powerlib
%   is the long-standing backward-compatible alias). This tries both.
%
%   Example: resolveLibBlock('Three-Phase Source')
%            resolveLibBlock('Universal Bridge')
%            resolveLibBlock('PWM Generator (2-Level)')

candidates = {'sps_lib', 'powerlib'};
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

error('resolveLibBlock:notFound', [ ...
    'Could not auto-locate library block "%s" under sps_lib/powerlib.\n' ...
    'Open the Simulink Library Browser, search for "%s", hover over it to\n' ...
    'read its exact path, then either (a) drag it into your model by hand,\n' ...
    'or (b) call resolveLibBlock(''%s'', {''<the library you found>''}).'], ...
    blockName, blockName, blockName);
end
