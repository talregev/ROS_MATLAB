function Status = rosmatlab_SetPath(Mode)
% ROSMATLAB_SETPATH adds/removes the psp directory to/from the path.

Root = fileparts(mfilename('fullpath'));

Path = ...
    {...
    Root,...
    fullfile(Root,'examples')...
    fullfile(Root,'example')...
    };

if((nargin == 0) || (Mode == 0))
    addpath(Path{:});
    rosmatlab_AddClassPath();
else
    rosmatlab_RemoveClassPath();
    rmpath(Path{:});    
end

Status = savepath;

rehash('toolboxreset');
rehash('toolboxcache');

end
