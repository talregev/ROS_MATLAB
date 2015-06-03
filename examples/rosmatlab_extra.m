%% Creating a Custom Message Listener

% Launch a ROS master on port 11311 on localhost.
roscore = rosmatlab.roscore();

% Create a new node named /NODE and connect it to the master.
node = rosmatlab.node('NODE',[],[],'rosIP','127.0.0.1');

% Add a publisher of a topic named /POINT to the node to send message of
% type geometry_msgs/Point.
publisher = node.addPublisher('POINT','geometry_msgs/Point');

% Add a subscriber to a topic named /POINT to the node to receive message
% of type geometry_msgs/Point.
subscriber = node.addSubscriber('POINT','geometry_msgs/Point',10);

% Add a custom message listener and set custom_function to execute when a
% valid message is published to /POINT.
subscriber.addCustomMessageListener({@custom_function,node.Node});

% Create a new message of type geometry_msgs/Point.
msg = node.newMessage('geometry_msgs/Point');

% Set the X, Y, and Z fields of the message and then publish the message
% iteratively.
for i = 1:10
    msg.setX(rand(1))
    msg.setY(rand(1))
    msg.setZ(rand(1))
    publisher.publish(msg);
    pause(0.1);
end


%% Setting Up Shutdown Tasks of a Node

% Set preShutdownTask to execute when the node has started to shut down.
node.setOnShutdownListener(@preShutdownTask);

% Set postShutdownTask to execute when the node has shut down.
node.setOnShutdownCompleteListener(@postShutdownTask);

% Test the node listener.
node.Node.shutdown();
pause(1);

% Delete the node
clear('node');

% Delete the master.
clear('roscore');


%% Clean up workspace.
clear;

