function rosmatlab_RemoveClassPath()
% ROSMATLAB_REMOVECLASSPATH removes ROS Java and ROS MATLAB jar files from
%   the Java class path. Note that google-collect.jar will be restored to
%   the Java class path.

% Remove existing paths to ROS Java jars from classpath.txt
fileName = [matlabroot,filesep,'toolbox',filesep,'local',filesep,'classpath.txt'];
fid = fopen(fileName,'r');
allPaths = fscanf(fid,'%c');
fclose(fid);
cleanPaths = regexprep(allPaths,'\n# ROS-MATLAB-START.+# ROS-MATLAB-END','');

% Add a new line at the end if one deos not exist
if cleanPaths(end) ~= sprintf('\n')
    cleanPaths = [cleanPaths,sprintf('\n')];
end

% Comment out the path to google-collect.jar because it is replaced
cleanPaths = regexprep(cleanPaths,'\n#+(.+\/google-collect\.jar)','\n$1','ignorecase','dotexceptnewline');

fid = fopen(fileName, 'w');
fwrite(fid, cleanPaths);
fclose(fid);