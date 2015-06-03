function rosmatlab_AddClassPath()
% ROSMATLAB_ADDCLASSPATH adds ROS Java and ROS MATLAB jar files to the Java
%   class path. Note that google-collect.jar will be eliminated from the
%   Java class path since it is replaced by guava-<x>.jar.

% Get a list of all jar files
currentDir = fileparts(mfilename('fullpath'));
jarDir = [currentDir,filesep,'jars'];
cd(jarDir);
jars = dir('*.jar');
jarFiles = {};
for i = 1:numel(jars)
    jarFiles{end+1} = [jarDir,filesep,jars(i).name];
end
cd(currentDir);

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

% Add paths to all jars to classpath.txt
cleanPaths = sprintf([cleanPaths,'%s'],'# ROS-MATLAB-START\n');
for i = 1:numel(jarFiles) 
    cleanPaths = sprintf([cleanPaths,'%s'],[strrep(jarFiles{i},'\','/'),'\n']);
end
cleanPaths = sprintf([cleanPaths,'%s'],'# ROS-MATLAB-END');

% Comment out the path to dnsjava-<x>.jar because it creates conflicts
% cleanPaths = regexprep(cleanPaths,'\n((?!#).+\/dnsjava.*\.jar)','\n#$1','ignorecase','dotexceptnewline');

% Comment out the path to google-collect.jar because it is replaced
cleanPaths = regexprep(cleanPaths,'\n((?!#).+\/google-collect\.jar)','\n#$1','ignorecase','dotexceptnewline');

fid = fopen(fileName, 'w');
fwrite(fid, cleanPaths);
fclose(fid);