function [ I ] = convertFromCompressDepthImageData( data )
    %from http://stackoverflow.com/questions/25745141/read-image-message-from-in-ros-matlab
    %from http://stackoverflow.com/questions/18659586/from-raw-bits-to-jpeg-without-writing-into-a-file
        % decode image stream using Java
    I = javax.imageio.ImageIO.read(java.io.ByteArrayInputStream(data));
    h = I.getHeight;
    w = I.getWidth;

    % convert Java Image to MATLAB image
    I = reshape(typecast(I.getData.getDataStorage, 'uint8'), [1,w,h]);
    I = cat(1,                          ...
            reshape(I(1,:,:), [w,h])'   ...
           );
end

