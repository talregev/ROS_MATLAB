classdef publisher < handle
    % PUBLISHER Add a publisher to the specified topic to a node.
    %   publisher(topicName,topicMessageType,node) adds a publisher to
    %   topic topicName for message type topicMessageType to a given
    %   node.
    %
    %   Example: rosmatlab.publisher('/talker','std_msgs/String',node) adds
    %   a publisher to the topic /talker that exchanges message of
    %   type std_msgs/String to node.
    
    properties (SetAccess = private)        
        TopicName = '';
        TopicMessageType = '';
        Publisher = [];
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % publisher                                                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pub = publisher(topicName,topicMessageType,object)
            if strcmp(class(object),'org.ros.internal.node.topic.DefaultPublisher')
                defaultPublisher = object;
                pub.TopicName = char(defaultPublisher.getTopicName());
                pub.TopicMessageType = char(defaultPublisher.getTopicMessageType());
                pub.Publisher = defaultPublisher;
            elseif strcmp(class(object),'rosmatlab.node')
                node = object;
                pub = node.addPublisher(topicName,topicMessageType);
            else
                error('Error calling the constructor of rosmatlab.publisher.')
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % publish                                                         %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function publish(pub,message)
            % PUBLISHER.PUBLISH Publish a message.
            %   publisher.publish(message) publishes a given message to the
            %   topic advertised by the publisher.
            if ~isempty(strfind(char(message),pub.TopicMessageType))
                pub.Publisher.publish(message);
            else
                error(['Incorrect message type. Publisher expects a message of type ',pub.TopicMessageType,'.']);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % delete                                                          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function delete(pub)            
            if ~isempty(pub.Publisher)
                % The publisher is automatically shut down when the node it
                % is attached to is shut down. No explicit shutdown
                % operation is required.
                pub.Publisher = [];
            end
            if ~isempty(pub.TopicMessageType)
                pub.TopicMessageType = '';
            end
            if ~isempty(pub.TopicName)
                pub.TopicName = '';
            end
        end
    end
    
end

