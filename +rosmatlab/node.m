classdef node < handle
    % NODE Launch a node on the specified ROS Master.
    %   node(nodeName,host,port,opts) creates an instance of
    %   org.ros.internal.node.DefaultNode named nodeName and starts the
    %   node on the ROS Master running on http://host:port. The second
    %   argument must be a string that contains either a hostname or an IP
    %   address. Alternatively, node(nodeName,uri) creates an instance of
    %   org.ros.internal.node.DefaultNode named nodeName and starts the
    %   node on the ROS Master running on uri. If not given host and port
    %   default to localhost and 11311, respectively. The argument opts is
    %   a series of option-value pairs as explained in the following:
    %
    %     safeMode - enables parsing of connection errors or warnings from
    %       master server. This option is useful when the status of the ROS
    %       Master is not known. This option also allows automatic removal
    %       of an obsolete node when it is replaced by the new node.
    %       However, the option does incur a delay of at least 20 seconds.
    %
    %     onShutdown - attaches a user defined function that executes when
    %       the node has started to shut down. The value must be a handle
    %       to a function with the following signature:
    %         function functionName(handle,event)
    %
    %     onShutdownComplete - attaches a user defined function that
    %       executes when the node has shut down. The value must be a
    %       handle to a function with the following signature:
    %         function functionName(handle,event)
    %
    %     rosIP - overwrites the IP address that is automatically
    %       determined for the local host. This option is useful for
    %       specifying the correct IP address when localhost is assigned
    %       with multiple IP addresses. If the node only communicates with
    %       other nodes on the local host, use this option to specify the
    %       loopback interface (127.0.0.1) for better performance. The
    %       value must be a string in dotted decimal notation.
    %
    %   Example: rosmatlab.node('MYNODE','localhost',11311) starts a node
    %   named MYNODE on ROS Master that is running on
    %   http://localhost:11311.
    %
    %   Example: rosmatlab.node('MYNODE','http://localhost:11311') starts a
    %   node named MYNODE on ROS Master that is running on
    %   http://localhost:11311.
    %
    %   Example: rosmatlab.node('MYNODE','localhost',[],'safeMode',true,)
    %   starts a node named MYNODE on ROS Master that is running on
    %   http://localhost:11311 with parsing of connection errors or
    %   warnings from master server enabled.
    %
    %   Example: rosmatlab.node('MYNODE',[],[],'onShutdownComplete',@onShutdownCompleteCallback)
    %   starts a node named MYNODE on ROS Master that is running on
    %   http://localhost:11311 with a listener that executes the
    %   onShutdownCompleteCallback function when the node has shut down.
    
    properties (SetAccess = private)
        NodeName = '';
        Node = [];
        OnErrorListener = [];
        OnShutdownListener = [];
        OnShutdownCompleteListener = [];
        OnStartListener = [];
        Publishers = [];
        Subscribers = [];
    end
    
    methods (Access = private)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % genMasterUri                                                    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function uri = genMasterUri(n,host,port)
            % NODE.GETMASTERURI Determine the master URI based on user
            % inputs.
            %   When instantiating a node, the master URI can be generated
            %   from one of the following:
            %   (1) Given hostname and port
            %   (2) Given URI
            %   (3) Given hostname and default port 11311
            %   (4) Default hostname localhost and given port
            %   (5) Environment variable ROS_MASTER_URI
            %   (6) Default hostname localhost and default port 11311
            if ~isempty(host) && ~isempty(port)
                % Both hostname and port are specified. Construct URI
                % using the given hostname and port.
                uri = ['http://',host,':',num2str(port)];
            elseif ~isempty(host) && isempty(port)
                % Either a URI is specified or only hostname is specified.
                % If host is not a URI, construct URI using the given
                % hostname and the default port.
                if ~isempty(strfind(host,'http://'))
                    uri = host;
                else
                    uri = ['http://',host,':11311'];
                end
            elseif isempty(host) && ~isempty(port)
                % Only port is specified. Construct URI using the default
                % hostname and the given port.
                uri = ['http://localhost:',num2str(port)];
            else
                % Neither hostname nor port is specified. Construct URI
                % using the environment variable ROS_MASTER_URI if it
                % exists. Otherwise, construct URI using the default
                % hostname and port.
                if ~isempty(getenv('ROS_MASTER_URI'))
                    uri = getenv('ROS_MASTER_URI');
                else
                    uri = 'http://localhost:11311';
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % interceptRosJavaError                                           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [match,tokens] = interceptRosJavaError(n,error,buffer)
            % INTERCEPTROSJAVAERROR Search for ROS Java error or anomaly.
            %   In some cases, when a match is found, tokens are returned
            %   to enable lookup of applicable objects. For example, if a
            %   slave has been replaced by a new one, the slave must be
            %   isolated for removal.
            [match,tokens] = regexp(buffer,error,'match','tokens','once','dotexceptnewline');
        end
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % node                                                            %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function n = node(nodeName,varargin)            
            try
                %% Reroute java.lang.System.err.
                originalStream = java.lang.System.err;
                outStream = java.io.PipedOutputStream();
            	inStream = java.io.PipedInputStream(outStream,8192);
                java.lang.System.setErr(java.io.PrintStream(outStream));
                % Reattempt if MATLAB connector failed to start.
                if ~isempty(lastwarn)
                    originalStream = java.lang.System.err;
                    outStream = java.io.PipedOutputStream();
                    inStream = java.io.PipedInputStream(outStream,8192);
                    java.lang.System.setErr(java.io.PrintStream(outStream));
                end
                %% Initialize all options.
                masterHost = '';
                masterPort = [];
                safeMode = false;
                onErrorCallbackHandle = [];
                onShutdownCallbackHandle = [];
                onShutdownCompleteCallbackHandle = [];
                onStartCallbackHandle = [];
                rosIP = '';
                %% Parse arguments and options.
                if nargin == 1
                elseif nargin == 2
                    masterHost = varargin{1};
                elseif nargin == 3
                    masterHost = varargin{1};
                    masterPort = varargin{2};
                elseif nargin >= 4
                    masterHost = varargin{1};
                    masterPort = varargin{2};
                    options = varargin(3:end);
                    numOptions = numel(options)/2;
                    for k = 1:numOptions
                        opt = options{2*k-1};
                        val = options{2*k};
                        if strcmpi(opt,'safeMode')&&islogical(val)
                            safeMode = val;
                        elseif strcmpi(opt,'onError')&&(isa(val,'function_handle')||isa(val,'cell'))
                            onErrorCallbackHandle = val;
                        elseif strcmpi(opt,'onShutdown')&&(isa(val,'function_handle')||isa(val,'cell'))
                            onShutdownCallbackHandle = val;
                        elseif strcmpi(opt,'onShutdownComplete')&&(isa(val,'function_handle')||isa(val,'cell'))
                            onShutdownCompleteCallbackHandle = val;
                        elseif strcmpi(opt,'onStart')&&(isa(val,'function_handle')||isa(val,'cell'))
                            onStartCallbackHandle = val;
                        elseif strcmpi(opt,'rosIP')&&isa(val,'char')
                            rosIP = val;
                        else
                            error('Incorrect option value pairs to the constructor for rosmatlab.node.')
                        end
                    end
                else
                    error('Incorrect use of the constructor for rosmatlab.node.')
                end
                uri = n.genMasterUri(masterHost,masterPort);
                rosMasterUri = java.net.URI(uri);
                if ~isempty(rosIP)
                    % IP overwrite for localhost is provided.
                    nodeHost = rosIP;
                else
                    % Use the following in the order of precedence:
                    % (1) Environment variable ROS_HOSTNAME
                    % (2) Environment variable ROS_IP
                    % (3) IP address of localhost
                    localHost = regexp(char(java.net.InetAddress.getLocalHost()),'/','split');
                    hostName = localHost{1};
                    hostAddress = localHost{2};
                    if ~isempty(getenv('ROS_HOSTNAME'))
                        nodeHost = getenv('ROS_HOSTNAME');
                        if ~strncmpi(nodeHost,hostName,min(numel(nodeHost),numel(hostName)))
                            warning('Environment variable ROS_HOSTNAME does not match localhost''s name');
                        end
                    elseif ~isempty(getenv('ROS_IP'))
                    	nodeHost = getenv('ROS_IP');
                        if ~strcmp(nodeHost,hostAddress)
                            warning('Environment variable ROS_IP does not match localhost''s IP address');
                        end
                    else
                        nodeHost = hostAddress;
                    end
                end
                %% Create a new node.
                nodeConfiguration = org.ros.node.NodeConfiguration.newPublic(nodeHost,rosMasterUri);
                nodeConfiguration.setNodeName(nodeName);
                nodeMainExecutor = org.ros.node.DefaultNodeMainExecutor.newDefault();
                nodeFactory = org.ros.node.DefaultNodeFactory(nodeMainExecutor.getScheduledExecutorService());
                nodeListener = com.mathworks.ros.node.MATLABNodeListener();
                nodeListeners = java.util.ArrayList();
                nodeListeners.add(nodeListener);
                % Note: An uncatchable Java error can occur if the master
                % is not running or a node already exists under the same
                % name. Parse ROS Java info so that an error can be
                % returned to MATLAB.
                defaultNode = nodeFactory.newNode(nodeConfiguration,nodeListeners);
                if safeMode
                    pause(15) %need to detect completion of registration
                else
                    pause(1) %need to detect completion of registration
                end
                %% Retrieve ROS Java info from java.lang.System.err.
                info = '';
                for i = 1:inStream.available()
                    info = [info,char(inStream.read())];
                end
                %% Check if the master has not been launched.
                % Error to be looked up in info. Note that "[", "]", "-",
                % and "." must be escaped in a regular expression.
                lookupError = '\[ERROR\] Registrar \- Exception caught while communicating with master\.';
                [detectedError,~] = n.interceptRosJavaError(lookupError,info);
                if ~isempty(detectedError)
                    % If the master has not been launched, shut down the
                    % invalid node and error out.
                    exceptionMessage = 'Failed to communicate with the master. Please verify that Ros Master has been launched on the specified URI.';
                    defaultNode.shutdown();
                    if safeMode
                        pause(5) %need to detect completion of unregistration
                    end
                    error(exceptionMessage);
                end
                %% Check if the node has replaced an existing one.
                % Error to be looked up in info. Note that "[", "]", "-",
                % and "." must be escaped in a regular expression.
                % The error message can appear in two ways depending on
                % whether or not the master is instantiated in the same
                % MATLAB session as the replaced node.
                % <If the master is instantiated in the same MATLAB session>
                lookupError = '\[WARN\] MasterServer \- Existing node .+ with slave URI (.+) will be shutdown\.';
                [detectedError,nodeUri] = n.interceptRosJavaError(lookupError,info);
                exceptionMessage = '';
                if ~isempty(detectedError)
                    % If the node has replaced an existing node, the
                    % existing node has been shut down automatically. The
                    % handle variable that points to the rosmatlab.node
                    % object may still exist in the caller workspace. Since
                    % the the node is no longer useful, it must be cleared.
                    variables = evalin('caller','whos');
                    for i = 1:numel(variables)
                        if strcmp(variables(i).class,'rosmatlab.node')
                            if strcmpi(char(evalin('caller',[variables(i).name,'.Node.getUri()'])),strtrim(nodeUri{1}))
                                % The existing node must be destroyed
                                % without shutdown operation to avoid
                                % confusing the master server.
                                evalin('caller',[variables(i).name,'.deleteWithoutShutdown()']);
                                evalin('caller',['clear(''',variables(i).name,''')']);
                                exceptionMessage = ['A node with node name ',char(defaultNode.getName()),' and URI ',strtrim(nodeUri{1}),...
                                    ' was found to be connected to the master when a new node with the same name is created. ',...
                                    'Because this node has been replaced by the new node, it has been shut down by the master. ',...
                                    'Note that the variable "',variables(i).name,'" has been deleted because it points to the replaced node.'];
                                if safeMode
                                    pause(5) %need to detect completion of unregistration
                                end
                                break
                            end                            
                        end                        
                    end
                    if ~isempty(exceptionMessage)
                        warning(exceptionMessage);
                    else
                        % The replaced node is not found. It could be
                        % created outside of this MATLAB session.
                        exceptionMessage = ['A node with node name ',char(defaultNode.getName()),' and URI ',strtrim(nodeUri{1}),...
                            ' was found to be connected to the master when a new node with the same name is created. ',...
                            'Because this node has been replaced by the new node, it has been shut down by the master. ',...
                            'An attempt to find the variable that points to the replaced node for automatic removal is NOT successful. ',...
                            'To avoid confusing the master server, please manually locate and delete the variable that points to the replaced node. ',...
                            'Note: You must first use the deleteWithoutShutdown method of the node to destroy it before clearing the variable.'];
                        warning(exceptionMessage);
                    end
                end
                % </If the master is instantiated in the same MATLAB session>
                % <If the master is NOT instantiated in the same MATLAB session>
                if isempty(exceptionMessage)
                    lookupError = '\[INFO\] SlaveXmlRpcEndpointImpl \-.+"Replaced by new slave"';
                    [detectedError,~] = n.interceptRosJavaError(lookupError,info);
                    if ~isempty(detectedError)
                        % If the node has replaced an existing node, the
                        % existing node has been shut down automatically.
                        % The handle variable that points to the
                        % rosmatlab.node object may still exist in the
                        % caller workspace. Since the the node is no longer
                        % useful, it must be cleared. Because the URI of
                        % the replaced node is not captured in the error
                        % message, it must be looked up by its node name.
                        variables = evalin('caller','whos');
                        for i = 1:numel(variables)
                            if strcmp(variables(i).class,'rosmatlab.node')
                                if strcmp(char(evalin('caller',[variables(i).name,'.Node.getName()'])),char(defaultNode.getName()))
                                    % The existing node must be destroyed
                                    % without shutdown operation to avoid
                                    % confusing the master server.
                                    evalin('caller',[variables(i).name,'.deleteWithoutShutdown()']);
                                    evalin('caller',['clear(''',variables(i).name,''')']);
                                    exceptionMessage = ['A node with node name ',char(defaultNode.getName()),...
                                        ' was found to be connected to the master when a new node with the same name is created. ',...
                                        'Because this node has been replaced by the new node, it has been shut down by the master. ',...
                                        'Note that the variable "',variables(i).name,'" has been deleted because it points to the replaced node.'];
                                    if safeMode
                                        pause(5) %need to detect completion of unregistration
                                    end
                                    break
                                end                            
                            end                        
                        end
                        if ~isempty(exceptionMessage)
                            warning(exceptionMessage);
                        else
                            % The replaced node is not found. It could be
                            % created outside of this MATLAB session.
                            exceptionMessage = ['A node with node name ',char(defaultNode.getName()),...
                                ' was found to be connected to the master when a new node with the same name is created. ',...
                                'Because this node has been replaced by the new node, it has been shut down by the master. ',...
                                'An attempt to find the variable that points to the replaced node for automatic removal is NOT successful. ',...
                                'To avoid confusing the master server, please manually locate and delete the variable that points to the replaced node. ',...
                                'Note: You must first use the deleteWithoutShutdown method of the node to destroy it before clearing the variable.'];
                            warning(exceptionMessage);
                        end
                    end
                end
                % </If the master is NOT instantiated in the same MATLAB session>
                %% Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
            catch exception
                %% Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
                rethrow(exception)
            end
            n.NodeName = char(defaultNode.getName());
            n.Node = defaultNode;
            % Add a listener to the onError callback of the default node
            % listener.
            n.OnErrorListener = rosmatlab.listener.bindListener(nodeListener,'onError',onErrorCallbackHandle);
            % Add a listener to the onShutdown callback of the default node
            % listener.
            n.OnShutdownListener = rosmatlab.listener.bindListener(nodeListener,'onShutdown',onShutdownCallbackHandle);
            % Add a listener to the onShutdownComplete callback of the
            % default node listener.
            n.OnShutdownCompleteListener = rosmatlab.listener.bindListener(nodeListener,'onShutdownComplete',onShutdownCompleteCallbackHandle);
            % Add a listener to the onStart callback of the default node
            % listener.
            n.OnStartListener = rosmatlab.listener.bindListener(nodeListener,'onStart',onStartCallbackHandle);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % newMessage                                                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function msg = newMessage(n,messageType)
            % NODE.NEWMESSAGE Create a new message of the specified type.
            %   node.newMessage(messageType) creates a new message of type
            %   messageType using the message factory of the node.
            %
            %   Example: node.newMessage('std_msgs/String') creates a new
            %   message of type std_msgs/String.
            try
                msg = n.Node.getTopicMessageFactory.newFromType(messageType);
            catch exception
                error(['Failed to create message of type ',messageType,'.'])
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setOnErrorListener                                              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function setOnErrorListener(n,callbackHandle)
            % NODE.SETONERRORLISTENER Set the default node
            % listener to execute the specified function when the node
            % experiences an unrecoverable error.
            %   node.setOnErrorListener(callbackHandle)
            %   attaches a user defined function to the onError callback
            %   for the default node listener of the node. The argument
            %   callbackHandle must be a function handle. The function must
            %   have the following signature:
            %
            %     function functionName(handle,event)
            %
            %   Example: node.setOnErrorListener(@functionName)
            %   attaches functionName to the onError callback for the
            %   default node listener of the node.
            %
            %   You can append additional arguments to the user defined
            %   function if necessary. Use a cell array to collect the
            %   function handle and the additional arguments when calling
            %   this method. For example, if the user define function has
            %   the following signature:
            %
            %     function functionName(handle,event,object)
            %
            %   use the following command to attach it:
            %
            %     node.setOnErrorListener({@functionName,object})
            n.OnErrorListener.Callback = callbackHandle;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setOnShutdownListener                                           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function setOnShutdownListener(n,callbackHandle)
            % NODE.SETONSHUTDOWNLISTENER Set the default node
            % listener to execute the specified function when the node has
            % started to shut down.
            %   node.setOnShutdownListener(callbackHandle)
            %   attaches a user defined function to the onShutdown callback
            %   for the default node listener of the node. The argument
            %   callbackHandle must be a function handle. The function must
            %   have the following signature:
            %
            %     function functionName(handle,event)
            %
            %   Example: node.setOnShutdownListener(@functionName)
            %   attaches functionName to the onShutdown callback for the
            %   default node listener of the node.
            %
            %   You can append additional arguments to the user defined
            %   function if necessary. Use a cell array to collect the
            %   function handle and the additional arguments when calling
            %   this method. For example, if the user define function has
            %   the following signature:
            %
            %     function functionName(handle,event,object)
            %
            %   use the following command to attach it:
            %
            %     node.setOnShutdownListener({@functionName,object})
            n.OnShutdownListener.Callback = callbackHandle;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setOnShutdownCompleteListener                                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function setOnShutdownCompleteListener(n,callbackHandle)
            % NODE.SETONSHUTDOWNCOMPLETELISTENER Set the default node
            % listener to execute the specified function when the node has
            % shut down.
            %   node.setOnShutdownCompleteListener(callbackHandle)
            %   attaches a user defined function to the onShutdownComplete
            %   callback for the default node listener of the node. The
            %   argument callbackHandle must be a function handle. The
            %   function must have the following signature:
            %
            %     function functionName(handle,event)
            %
            %   Example: node.setOnShutdownCompleteListener(@functionName)
            %   attaches functionName to the onShutdownComplete callback
            %   for the default node listener of the node.
            %
            %   You can append additional arguments to the user defined
            %   function if necessary. Use a cell array to collect the
            %   function handle and the additional arguments when calling
            %   this method. For example, if the user define function has
            %   the following signature:
            %
            %     function functionName(handle,event,object)
            %
            %   use the following command to attach it:
            %
            %     node.setOnShutdownCompleteListener({@functionName,object})
            n.OnShutdownCompleteListener.Callback = callbackHandle;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setOnStartListener                                              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function setOnStartListener(n,callbackHandle)
            % NODE.SETONSTARTLISTENER Set the default node
            % listener to execute the specified function when the node has
            % started and successfully connected to the master.
            %   node.setOnStartListener(callbackHandle)
            %   attaches a user defined function to the onStart callback
            %   for the default node listener of the node. The argument
            %   callbackHandle must be a function handle. The function must
            %   have the following signature:
            %
            %     function functionName(handle,event)
            %
            %   Example: node.setOnStartListener(@functionName)
            %   attaches functionName to the onStart callback for the
            %   default node listener of the node.
            %
            %   You can append additional arguments to the user defined
            %   function if necessary. Use a cell array to collect the
            %   function handle and the additional arguments when calling
            %   this method. For example, if the user define function has
            %   the following signature:
            %
            %     function functionName(handle,event,object)
            %
            %   use the following command to attach it:
            %
            %     node.setOnStartListener({@functionName,object})
            n.OnStartListener.Callback = callbackHandle;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % addPublisher                                                    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pub = addPublisher(n,topicName,topicMessageType)
            % NODE.ADDPUBLISHER Add a publisher to the specified topic to
            % the node.
            %   node.addpublisher(topicName,topicMessageType) adds a
            %   publisher to topic topicName for message type
            %   topicMessageType to the node.
            %
            %   Example: node.addpublisher('/talker','std_msgs/String')
            %   adds a publisher to the topic /talker that exchanges
            %   message of type std_msgs/String to node. Alternatively, use
            %   rosmatlab.publisher('/talker','std_msgs/String',node).
            try
                % Note: An uncatchable Java error can occur if the node is
                % not running or the topic is already defined under a
                % different message type. Parse ROS Java info so that an
                % error can be returned to MATLAB.
                %% Reroute java.lang.System.err.
                originalStream = java.lang.System.err;
                outStream = java.io.PipedOutputStream();
            	inStream = java.io.PipedInputStream(outStream,8192);
                java.lang.System.setErr(java.io.PrintStream(outStream));
                defaultPublisher = n.Node.newPublisher(topicName,topicMessageType);
                pause(1) %need to detect completion of registration
                %% Retrieve ROS Java info from java.lang.System.err.
                info = '';
                for i = 1:inStream.available()
                    info = [info,char(inStream.read())];
                end
                %% Check if the node has been shut down.
                % Error to be looked up in info. Note that "[", "]", "-",
                % and "." must be escaped in a regular expression.
                lookupError = '\[INFO\] DefaultPublisher \- Publisher registration failed:';
                [detectedError,~] = n.interceptRosJavaError(lookupError,info);
                if ~isempty(detectedError)
                    % If the node has been shut down, delete the obsolete
                    % node and error out.
                    exceptionMessage = ['Failed to register publisher to topic ',topicName,' for message type ',topicMessageType,' on node ',char(n.Node.getName()),...
                        ' because the node has been shut down. Please recreate the node before adding the publisher.'];
                    n.delete();
                    error(exceptionMessage);
                end
                %% Check if the topic has unexpected message type.
                % Error to be looked up in info. Note that "[", "]", "-",
                % and "." must be escaped in a regular expression.
                lookupError = 'org\.ros\.exception\.RosRuntimeException: java\.lang\.IllegalStateException: Unexpected message type (.+) \!= .+';
                [detectedError,existingType] = n.interceptRosJavaError(lookupError,info);
                if ~isempty(detectedError)
                    % if the topic has unexpected message type, shut down
                    % the invalid publisher and error out.
                    exceptionMessage = ['Failed to register publisher to topic ',topicName,' for message type ',topicMessageType,' on node ',char(n.Node.getName()),...
                        ' because the topic is already defined under a different message type ',strtrim(existingType{1}),'. Consider recreating the node before adding the publisher.'];
                    % Shutting down the publisher may not be sufficient to
                    % prevent subsequent incorrect registrations.
                    defaultPublisher.shutdown();
                    error(exceptionMessage);
                end
                %% Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
            catch exception
                %% Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
                rethrow(exception)
            end
            % Note that in certain cases, registration will still succeed
            % even though there is a mismatch in message type. To make sure
            % that the correct message type is captured,
            % defaultPublisher.getTopicMessageType() is used instead of
            % topicMessageType when calling the constructor of
            % rosmatlab.publisher.
            if ~strcmp(topicMessageType,char(defaultPublisher.getTopicMessageType()))
                warning(['Because the topic ',topicName,' is already defined with message type ',...
                    char(defaultPublisher.getTopicMessageType()),', the specified message type ',...
                    topicMessageType,' is ignored.']);
            end
            pub = rosmatlab.publisher(topicName,char(defaultPublisher.getTopicMessageType()),defaultPublisher);
            n.Publishers{end+1} = pub;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % removePublisher                                                 %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function removePublisher(n,publisher)
            % NODE.REMOVEPUBLISHER Remove a publisher from the node.
            %   node.removePublisher(publisher) removes a given publisher
            %   from the node.
            for i = 1:numel(n.Publishers)
                if n.Publishers{i}.eq(publisher)
                    % Note: n.Publishers{i} = [] will only remove the data
                    % in the cell, living behind an empty cell.
                    % n.Publishers(i) = [] will atually remove the cell
                    % itself from the cell array, reducing the size of the
                    % cell array by one element.
                    n.Publishers{i}.delete();
                    variables = evalin('caller','whos');
                    for j = 1:numel(variables)
                        if n.Publishers{i}.eq(evalin('caller',variables(j).name))
                            evalin('caller',['clear(''',variables(j).name,''')']);
                            break
                        end
                    end
                    n.Publishers(i) = [];
                    if isempty(n.Publishers)
                        % Otherwise n.Publishers becomes a {1x0 cell}
                        % instead of its default value [].
                        n.Publishers = [];
                    end
                    break
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % addSubscriber                                                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function sub = addSubscriber(n,topicName,topicMessageType,bufferLimit)
            % NODE.ADDSUBSCRIBER Add a subscriber to the specified topic to
            % the node.
            %   node.addsubscriber(topicName,topicMessageType,bufferLimit)
            %   adds a subscriber to topic topicName for message type
            %   topicMessageType with a buffer limit of bufferLimit to the
            %   node.            
            %
            %   Example: node.addsubscriber('/listener','std_msgs/String',1)
            %   adds a subscriber to the topic /listener that exchanges
            %   message of type std_msgs/String with a buffer limit of 1
            %   message to node. Alternatively, use
            %   rosmatlab.subscriber('/listener','std_msgs/String',1,node).
            try
                % Note: An uncatchable Java error can occur if the node is
                % not running or the topic is already defined under a
                % different message type. Parse ROS Java info so that an
                % error can be returned to MATLAB.
                %% Reroute java.lang.System.err.
                originalStream = java.lang.System.err;
                outStream = java.io.PipedOutputStream();
            	inStream = java.io.PipedInputStream(outStream,8192);
                java.lang.System.setErr(java.io.PrintStream(outStream));
                defaultSubscriber = n.Node.newSubscriber(topicName,topicMessageType);
                pause(1) %need to detect completion of registration
                %% Retrieve ROS Java info from java.lang.System.err.
                info = '';
                for i = 1:inStream.available()
                    info = [info,char(inStream.read())];
                end
                %% Check if the node has been shut down.
                % Error to be looked up in info. Note that "[", "]", "-",
                % and "." must be escaped in a regular expression.
                lookupError = '\[INFO\] DefaultPublisher \- Subscriber registration failed:';
                [detectedError,~] = n.interceptRosJavaError(lookupError,info);
                if ~isempty(detectedError)
                    % If the node has been shut down, delete the obsolete
                    % node and error out.
                    exceptionMessage = ['Failed to register subscriber to topic ',topicName,' for message type ',topicMessageType,' on node ',char(n.Node.getName()),...
                        ' because the node has been shut down. Please recreate the node before adding the subscriber.'];
                    n.delete();
                    error(exceptionMessage);
                end
                %% Check if the topic has unexpected message type.
                % Error to be looked up in info. Note that "[", "]", "-",
                % and "." must be escaped in a regular expression.
                lookupError = 'org\.ros\.exception\.RosRuntimeException: java\.lang\.IllegalStateException: Unexpected message type .+ \!= (.+)';
                [detectedError,existingType] = n.interceptRosJavaError(lookupError,info);
                if ~isempty(detectedError)
                    % if the topic has unexpected message type, shut down
                    % the invalid subscriber and error out.
                    exceptionMessage = ['Failed to register subscriber to topic ',topicName,' for message type ',topicMessageType,' on node ',char(n.Node.getName()),...
                        ' because the topic is already defined under a different message type ',strtrim(existingType{1}),'. Consider recreating the node before adding the subscriber.'];
                    % Shutting down the subcriber may not be sufficient to
                    % prevent subsequent incorrect registrations.
                    defaultSubscriber.shutdown();
                    error(exceptionMessage);
                end
                %% Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
            catch exception
                %% Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
                rethrow(exception)
            end
            % Note that in certain cases, registration will still succeed
            % even though there is a mismatch in message type. To make sure
            % that the correct message type is captured,
            % defaultSubscriber.getTopicMessageType() is used instead of
            % topicMessageType when calling the constructor of
            % rosmatlab.subscriber.
            if ~strcmp(topicMessageType,char(defaultSubscriber.getTopicMessageType()))
                warning(['Because the topic ',topicName,' is already defined with message type ',...
                    char(defaultSubscriber.getTopicMessageType()),', the specified message type ',...
                    topicMessageType,' is ignored.']);
            end
            sub = rosmatlab.subscriber(topicName,char(defaultSubscriber.getTopicMessageType()),bufferLimit,defaultSubscriber);
            n.Subscribers{end+1} = sub;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % removeSubscriber                                                %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function removeSubscriber(n,subscriber)
            % NODE.REMOVESUBSCRIBER Remove a subscriber from the node.
            %   node.removeSubscriber(subscriber) removes a given
            %   subscriber from the node.
            for i = 1:numel(n.Subscribers)
                if n.Subscribers{i}.eq(subscriber)
                    % Note: n.Subscribers{i} = [] will only remove the data
                    % in the cell, living behind an empty cell.
                    % n.Subscribers(i) = [] will atually remove the cell
                    % itself from the cell array, reducing the size of the
                    % cell array by one element.
                    n.Subscribers{i}.delete();
                    variables = evalin('caller','whos');
                    for j = 1:numel(variables)
                        if n.Subscribers{i}.eq(evalin('caller',variables(j).name))
                            evalin('caller',['clear(''',variables(j).name,''')']);
                            break
                        end
                    end
                    n.Subscribers(i) = [];
                    if isempty(n.Subscribers)
                        % Otherwise n.Subscribers becomes a {1x0 cell}
                        % instead of its default value [].
                        n.Subscribers = [];
                    end
                    break
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % deleteWithoutShutdown                                           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function deleteWithoutShutdown(n)
            % NODE.DELETEWITHOUTSHUTDOWN Empty the node without shutdown.
            %   node.deleteWithoutShutdown() prepares the node for deletion
            %   without invoking its shutdown method. If the node has been
            %   replaced, it has been automatically shutdown. Calling the
            %   shutdown method again can confuse the master server. This
            %   method is used instead of the standard destructor to
            %   suppress shutdown operation.
            if ~isempty(n.Subscribers)
                for i = 1:numel(n.Subscribers)
                    n.Subscribers{i}.delete();
                end
                n.Subscribers = [];
            end
            if ~isempty(n.Publishers)
                for i = 1:numel(n.Publishers)
                    n.Publishers{i}.delete();
                end
                n.Publishers = [];
            end
            % The handle variables that point to the rosmatlab.publisher
            % and rosmatlab.subscriber objects may still exist in the
            % caller workspace. Since the handle variables are no longer
            % valid, they must be cleared.
            variables = evalin('caller','whos');
            for i = 1:numel(variables)
                if evalin('caller',['isobject(',variables(i).name,')'])
                    if ~evalin('caller',[variables(i).name,'.isvalid()'])
                        evalin('caller',['clear(''',variables(i).name,''')']);
                    end
                end
            end
            if ~isempty(n.OnStartListener)
                n.OnStartListener = [];
            end
            if ~isempty(n.OnShutdownCompleteListener)
                n.OnShutdownCompleteListener = [];
            end
            if ~isempty(n.OnShutdownListener)
                n.OnShutdownListener = [];
            end
            if ~isempty(n.OnErrorListener)
                n.OnErrorListener = [];
            end
            if ~isempty(n.Node)
                n.Node = [];
            end
            if ~isempty(n.NodeName)
                n.NodeName = '';
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % delete                                                          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function delete(n)
            try
                % Reroute java.lang.System.err.
                originalStream = java.lang.System.err;
                outStream = java.io.PipedOutputStream();
            	inStream = java.io.PipedInputStream(outStream,8192);
                java.lang.System.setErr(java.io.PrintStream(outStream));
                if ~isempty(n.Subscribers)
                    for i = 1:numel(n.Subscribers)
                        n.Subscribers{i}.delete();
                    end
                    n.Subscribers = [];
                end
                if ~isempty(n.Publishers)
                    for i = 1:numel(n.Publishers)
                        n.Publishers{i}.delete();
                    end
                    n.Publishers = [];
                end
                % The handle variables that point to the
                % rosmatlab.publisher and rosmatlab.subscriber objects may
                % still exist in the caller workspace. Since the handle
                % variables are no longer valid, they must be cleared.
                variables = evalin('caller','whos');
                for i = 1:numel(variables)
                    if evalin('caller',['isobject(',variables(i).name,')'])
                        if ~evalin('caller',[variables(i).name,'.isvalid()'])
                            evalin('caller',['clear(''',variables(i).name,''')']);
                        end
                    end
                end
                if ~isempty(n.OnStartListener)
                    n.OnStartListener = [];
                end
                if ~isempty(n.OnShutdownCompleteListener)
                    n.OnShutdownCompleteListener = [];
                end
                if ~isempty(n.OnShutdownListener)
                    n.OnShutdownListener = [];
                end
                if ~isempty(n.OnErrorListener)
                    n.OnErrorListener = [];
                end
                if ~isempty(n.Node)
                    disp(['Shutting down node ',n.NodeName,' on ',char(n.Node.getUri()),'.']);
                    n.Node.shutdown();
                    n.Node = [];
                end
                if ~isempty(n.NodeName)
                    n.NodeName = '';
                end
                % Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
            catch
                % Restore java.lang.System.err.
                inStream.close();
                outStream.close();
                java.lang.System.setErr(originalStream);
            end
        end
    end
    
end

