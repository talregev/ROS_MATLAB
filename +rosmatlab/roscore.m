classdef roscore < handle
    % ROSCORE Launch a ROS Master on the specified port on localhost.
    %   roscore(port) creates an instance of org.ros.RosCore and starts the
    %   master on localhost:port. If no port is specified, a default port
    %   of 11311 is used.
    %
    %   Example: rosmatlab.roscore(11311) lauches ROS Master on
    %   http://localhost:11311.
    
    properties (SetAccess = private)
        RosMasterUri = '';
        RosMaster = [];
    end
    
    methods (Access = private)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % isNodeRunningOnMaster                                           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function match = isNodeRunningOnMaster(core,node)
            % ROSCORE.COMPAREURI Determine if the master URI of a node
            % matches the URI of the master.
            %   When instantiating a node, the master URI can be composed
            %   from one of the following:
            %   (1) Hostname and port
            %   (2) Hostname with domain name and port
            %   (3) IP address and port
            localHost = regexp(char(java.net.InetAddress.getLocalHost()),'/','split');
            hostName = ['http://',lower(localHost{1})];
            hostAddress = ['http://',localHost{2}];
            port = regexp(core.RosMasterUri,':\d+','match','once');
            nodeMasterUri = lower(char(node.Node.getMasterUri()));
            % If nodeMasterUri contains either hostName, hostAddress, or
            % "localhost", then it is a match if it also contains port.
            if (~isempty(strfind(nodeMasterUri,hostName)) || ...
                ~isempty(strfind(nodeMasterUri,hostAddress)) || ...
                ~isempty(strfind(nodeMasterUri,'http://localhost'))) && ...
                ~isempty(strfind(nodeMasterUri,port))
                match = true;
            % Definitely a match as well if nodeMasterUri and
            % core.RosMasterUri are the same.
            elseif strcmp(nodeMasterUri,lower(core.RosMasterUri))
                match = true;
            else
                match = false;
            end
        end
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % core                                                            %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function core = roscore(varargin)
            try
                if nargin == 2
                    port = varargin{2};
                    host = varargin{1};
                elseif nargin == 1
                    port = varargin{1};
                elseif nargin == 0
                    port = 11311;
                else
                    error('Incorrect use of the constructor for rosmatlab.roscore.')
                end
                if nargin == 2
                    rosMaster = org.ros.RosCore.newPublic(host,port);
                else
                    rosMaster = org.ros.RosCore.newPublic(port);
                end
                rosMaster.start();
                rosMaster.awaitStart();
            catch exception
                socketError = 'org\.ros\.exception\.RosRuntimeException:.+: JVM_Bind';
                [match,~] = regexp(exception.message,socketError,'match','tokens','once','dotexceptnewline');
                if ~isempty(match)
                    error(['ROS Master is already running on port ',num2str(port),'.']);
                else
                    rethrow(exception);
                end
            end
            core.RosMasterUri = char(rosMaster.getUri());
            core.RosMaster = rosMaster;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % start                                                           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function start(core)
            % ROSCORE.START Start the master.
            %   roscore.start() invokes both the start and awaitStart
            %   methods of the master. To call the start method of the
            %   master only, use roscore.RosMaster.start() instead.
            try
                core.RosMaster.start();
                core.RosMaster.awaitStart();
            catch exception
                error('ROS Master is already running.');
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % shutdown                                                        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function shutdown(core)
            % ROSCORE.SHUTDOWN Shutdown the master.
            %   roscore.shutdown() invokes the shutdown method of the
            %   master.
            core.RosMaster.shutdown();
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % delete                                                          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function delete(core)            
            if ~isempty(core.RosMaster)
                % Must find all nodes in the caller workspace that run on
                % the master before shutting it down. Otherwise an
                % uncatchable Java error can occur when an attempt is made
                % to shut down each node if the master is no longer
                % running.
                try
                    variables = evalin('caller','whos');
                    for i = 1:numel(variables)
                        if strcmp(variables(i).class,'rosmatlab.node')
                            if core.isNodeRunningOnMaster(evalin('caller',variables(i).name))
                                evalin('caller',['clear(''',variables(i).name,''')']);
                                disp(['The rosmatlab.node object "',variables(i).name,'" has been deleted because it is connected to a master that is being deleted.'])
                            end
                        end
                    end
                catch exception
                end
                disp(['Shutting down ROS Master on ',core.RosMasterUri,'.']);
                core.RosMaster.shutdown();
                core.RosMaster = [];
            end
            if ~isempty(core.RosMasterUri)
                core.RosMasterUri = '';
            end
        end
    end
    
end

