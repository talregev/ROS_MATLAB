function showImageData1(message)
    % read raw image data
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%  This message contains an uncompressed image
%  (0, 0) is at top-left corner of image
% 
% 
% Header header        # Header timestamp should be acquisition time of image
%                      # Header frame_id should be optical frame of camera
%                      # origin of frame should be optical center of cameara
%                      # +x should point to the right in the image
%                      # +y should point down in the image
%                      # +z should point into to plane of the image
%                      # If the frame_id here and the frame_id of the CameraInfo
%                      # message associated with the image conflict
%                      # the behavior is undefined
% 
% uint32 height         # image height, that is, number of rows
% uint32 width          # image width, that is, number of columns
% 
%  The legal values for encoding are in file src/image_encodings.cpp
%  If you want to standardize a new string format, join
%  ros-users@lists.sourceforge.net and send an email proposing a new encoding.
% 
% string encoding       # Encoding of pixels -- channel meaning, ordering, size
%                       # taken from the list of strings in include/sensor_msgs/image_encodings.h
% 
% uint8 is_bigendian    # is this data bigendian?
% uint32 step           # Full row length in bytes
% uint8[] data          # actual matrix data, size is (step * rows)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    persistent videoPlayer;
    
    %from http://stackoverflow.com/questions/25745141/read-image-message-from-in-ros-matlab
    a = message.getData();
    w = message.getWidth();
    h = message.getHeight();
    data = a.array;
    data = data(a.arrayOffset+1:end);
    
    I = convertFromBGRRawImageData(data,w,h);

    if isempty(videoPlayer)
        videoPlayer = vision.VideoPlayer('Name','Raw 1');
    end
    step(videoPlayer,I);
end