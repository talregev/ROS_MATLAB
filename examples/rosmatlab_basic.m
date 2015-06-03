%% Creating a Publisher and a Subscriber

% Launch a ROS master on port 11311 on localhost.
roscore = rosmatlab.roscore(11311);

% Create a new node named /NODE and connect it to the master.
node = rosmatlab.node('NODE',roscore.RosMasterUri);

% Add a publisher of a topic named /TOPIC to the node to send message of
% type std_msgs/String.
publisher = rosmatlab.publisher('TOPIC','std_msgs/String',node);

% Add a subscriber to a topic named /TOPIC to the node to receive message
% of type std_msgs/String.
subscriber = rosmatlab.subscriber('TOPIC','std_msgs/String',1,node);

% Set function1 and function2 to execute when a valid message is published
% to /TOPIC.
subscriber.setOnNewMessageListeners({@function1,@function2});

% Create a new message of type std_msgs/String.
msg = rosmatlab.message('std_msgs/String',node);

% Set the data field of the message and then publish the message.
msg.setData(sprintf('Message created: %s',datestr(now)));
publisher.publish(msg);
pause(1);


%% Reassigning Message Listener Tasks of a Subscriber

% Replace function1 and function2 in the standard message listener with
% function3. 
subscriber.setOnNewMessageListeners({@function3});

% Update the data field of the message and then publish the message
% iteratively.
for i = 1:10
    msg.setData(sprintf('Iteration %d:\n  Message created: %s',i,datestr(now)));
    publisher.publish(msg);
    pause(1)
end

% Remove function3 from the standard message listener.
subscriber.setOnNewMessageListeners([]);

% Update the data field of the message and then publish the message.
msg.setData(sprintf('Message created: %s',datestr(now)));
publisher.publish(msg);
pause(1);

% Remove the subscriber from the node.
node.removeSubscriber(subscriber);

% Delete the master.
clear('roscore');


%% Clean up workspace.
clear;

