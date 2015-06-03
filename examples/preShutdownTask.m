function preShutdownTask(handle,event)
node = event.JavaEvent.getSource;
disp(['Node ',char(node.getName()),' running on ',char(node.getUri()),' is shutting down.'])
end