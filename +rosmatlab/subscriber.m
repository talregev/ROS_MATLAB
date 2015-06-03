classdef subscriber < handle
    % SUBSCRIBER Add a subscriber to the specified topic to a node.
    %   subscriber(topicName,topicMessageType,bufferLimit,node) adds a
    %   subscriber to topic topicName for message type topicMessageType
    %   with a buffer limit of bufferLimit to a given node .
    %
    %   Example: rosmatlab.subscriber('/listener','std_msgs/String',1,node)
    %   adds a subscriber to the topic /listener that exchanges message of
    %   type std_msgs/String with a buffer limit of 1 message to node.
    
    properties (SetAccess = private)        
        TopicName = '';
        TopicMessageType = '';
        BufferLimit = [];
        Subscriber = [];
    end
    
    properties
        OnNewMessageListeners = [];
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % subscriber                                                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function sub = subscriber(topicName,topicMessageType,bufferLimit,object)
            if strcmp(class(object),'org.ros.internal.node.topic.DefaultSubscriber')
                defaultSubscriber = object;
                sub.TopicName = char(defaultSubscriber.getTopicName());
                sub.TopicMessageType = char(defaultSubscriber.getTopicMessageType());
                sub.BufferLimit = int32(bufferLimit);
                sub.Subscriber = defaultSubscriber;
                % Add a default message listener with an empty listener to
                % its onNewMessage callback.
                sub.addCustomMessageListener({@rosmatlab.onNewMessageCallback,[]});
            elseif strcmp(class(object),'rosmatlab.node')
                node = object;
                sub = node.addSubscriber(topicName,topicMessageType,bufferLimit);
            else
                error('Error calling the constructor of rosmatlab.subscriber.')
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % addCustomMessageListener                                        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function addCustomMessageListener(sub,callbackHandle)
            % SUBSCRIBER.ADDCUSTOMMESSAGELISTENER Add a custom message
            % listener that executes the specified function when a message
            % is published to the topic subscribed by the subscriber.
            %   subscriber.addCustomMessageListener(callbackHandle) adds a
            %   message listener to the subscriber and attaches a user
            %   defined function to the onNewMessage callback of the
            %   message listener. The argument callbackHandle must be a
            %   function handle. The function must have the following
            %   signature:
            %
            %     function functionName(handle,event)
            %
            %   Example: subscriber.addCustomMessageListener(@functionName)
            %   adds a message listener to the subscriber and attaches
            %   functionName to the onNewMessage callback of the message
            %   listener.
            %
            %   You can append additional arguments to the user defined
            %   function if necessary. Use a cell array to collect the
            %   function handle and the additional arguments when calling
            %   this method. For example, if the user define function has
            %   the following signature:
            %
            %     function functionName(handle,event,object)
            %
            %   use the following command to add a message listener:
            %
            %     subscriber.addCustomMessageListener({@functionName,object})
            messageListener = com.mathworks.ros.message.MATLABMessageListener();
            sub.Subscriber.addMessageListener(messageListener,sub.BufferLimit);
            % Add a listener to the OnNewMessage callback of the message
            % listener.
            sub.OnNewMessageListeners{end+1} = rosmatlab.listener.bindListener(messageListener,'onNewMessage',callbackHandle);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setOnNewMessageListeners                                        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function setOnNewMessageListeners(sub,callbackHandles)
            % SUBSCRIBER.SETONNEWMESSAGELISTENERS Set the default message
            % listener to execute the specified functions when a message is
            % published to the topic subscribed by the subscriber.
            %   subscriber.setOnNewMessageListeners(callbackHandles)
            %   attaches a set of user defined functions to the
            %   onNewMessage callback for the default message listener of
            %   the subscriber. The argument callbackHandles must be a cell
            %   array of function handles. Each function must have the
            %   following signature:
            %
            %     function functionName(message)
            %
            %   Example: subscriber.setOnNewMessageListeners({@functionName1,@functionName2})
            %   attaches functionName1 and functionName2 to the
            %   onNewMessage callback for the default message listener of
            %   the subscriber.
            sub.OnNewMessageListeners{1}.Callback = {@rosmatlab.onNewMessageCallback,callbackHandles};
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % delete                                                          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function delete(sub)
            if ~isempty(sub.OnNewMessageListeners)
                sub.OnNewMessageListeners = [];
            end
            if ~isempty(sub.Subscriber)
                % The subscriber is automatically shut down when the node
                % it is attached to is shut down. No explicit shutdown
                % operation is required.
                sub.Subscriber = [];
            end
            if ~isempty(sub.BufferLimit)
                sub.BufferLimit = [];
            end
            if ~isempty(sub.TopicMessageType)
                sub.TopicMessageType = '';
            end
            if ~isempty(sub.TopicName)
                sub.TopicName = '';
            end
        end
    end
    
end

