function boolean = loopCondition()
    % create a loop until you press q at the new window or close it.
    persistent f;
    % simulate a gui
    if isempty(f)
        disp('press key <q> at the window or close it to stop');
        f=figure(1);
        boolean = true;
        return
    end    

    % if you press 'q' or close the window
    if  ~ishandle(f) | get(f,'currentkey') == 'q'
        % stop the loop
        boolean = false;
        if ishandle(f)
            delete(f);
        end
        disp('stopped');
        return
    else        
        % continue the loop
        boolean = true;
    end
end
