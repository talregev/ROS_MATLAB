function showCompressedImageData1(message)
% read compressed image data
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%  This message contains a compressed image
% 
% Header header        # Header timestamp should be acquisition time of image
%                      # Header frame_id should be optical frame of camera
%                      # origin of frame should be optical center of cameara
%                      # +x should point to the right in the image
%                      # +y should point down in the image
%                      # +z should point into to plane of the image
% 
% string format        # Specifies the format of the data
%                      #   Acceptable values:
%                      #     jpeg, png
% uint8[] data         # Compressed image buffer
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    persistent videoPlayer;
    
    %from http://stackoverflow.com/questions/25745141/read-image-message-from-in-ros-matlab
    %from http://stackoverflow.com/questions/18659586/from-raw-bits-to-jpeg-without-writing-into-a-file
    a = message.getData();
    data = a.array;
    data = data(a.arrayOffset+1:end);
    
    I = convertFromCompressImageData(data);
    
    if isempty(videoPlayer)
        videoPlayer = vision.VideoPlayer('Name','Compressed 1');
    end
    step(videoPlayer,I);
end
