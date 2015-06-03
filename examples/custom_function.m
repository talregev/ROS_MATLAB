function custom_function(handle,event,node)
message = event.JavaEvent.getSource;
magnitude = norm([message.getX(),message.getY(),message.getZ()]);
point = ['[',num2str(message.getX()),',',num2str(message.getY()),',',num2str(message.getZ()),']'];
node.getLog().info(['Distance of ',point,' from the origin is ',num2str(magnitude),'.']);
end