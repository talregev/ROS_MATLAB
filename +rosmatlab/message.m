function msg = message(messageType,node)
    % MESSAGE Create a new message of the specified type.
    %   rosmatlab.message(messageType,node) creates a new message of type
    %   messageType using the message factory of a given node.
    %
    %   Example: rosmatlab.message('std_msgs/String',node) creates a
    %   message of type std_msgs/String.
    msg = node.newMessage(messageType);
end

