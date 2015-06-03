function onNewMessageCallback(handle,event,callbackHandles)
    % ONNEWMESSAGECALLBACK Execute user callbacks for the default message
    % listener of a subscriber.
    %   rosmatlab.onNewMessageCallback(handle,event,callbackHandles)
    %   executes user defined functions listed in callbackHandles as a
    %   onNewMessage callback for the default message listener of a
    %   subscriber. The first two arguments are intrinsic. handle is a
    %   javahandle.com.mathworks.jmi.Callback object while event is a
    %   handle.JavaEventData object. The following command is used to
    %   register onNewMessageCallback as an onNewMessage callback for a
    %   message listener of a subscriber:
    %
    %     subscriber.addCustomMessageListener({@rosmatlab.onNewMessageCallback,[]})
    %
    %   The following command is then used to register user defined
    %   functions for execution when onNewMessageCallback is invoked:
    %
    %     subscriber.setMessageListenerOnNewMessageCallbacks(callbackHandles)
    %
    %   Note that callbackHandles in the above command is a cell array of
    %   function handles. Each element of callbackHandles must be a handle
    %   to a function with the following signature:
    %
    %     function functionName(message)
    message = event.JavaEvent.getSource();
    for i = 1:numel(callbackHandles)
        feval(callbackHandles{i},message);
    end
end

