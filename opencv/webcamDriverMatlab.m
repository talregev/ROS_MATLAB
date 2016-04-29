%% init
loadOpenCV;
import org.bytedeco.javacv.*;
import org.bytedeco.javacpp.*;

grabber = FrameGrabber.createDefault(0);
grabber.start();

%% grab image
while loopCondition()
    img = grabber.grab();
    buffer = img.image(1);
    ptr = BytePointer(buffer);
    w = img.imageWidth;
    h = img.imageHeight;
    cvImage = javaMethod('create', 'org.bytedeco.javacpp.opencv_core$CvMat', h, w, opencv_core.CV_8UC3);
    cvImage  = cvImage.data_ptr(ptr);
    data = cvImage.get();
    I = uint8(data);
    I = cat(3,                          ...
            reshape(I(3:3:end),[w h])', ...
            reshape(I(2:3:end),[w h])', ...
            reshape(I(1:3:end),[w h])'  ...
       );
    imshow(I);
end
%%
grabber.stop();
clear;
clear import;
clear java;
%%