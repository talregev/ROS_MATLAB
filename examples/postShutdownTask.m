function postShutdownTask(handle,event)
node = event.JavaEvent.getSource;
disp(['Node ',char(node.getName()),' running on ',char(node.getUri()),' has shut down.'])
end