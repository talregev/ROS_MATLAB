%% init
stopWebcamDriver;
loadOpenCV;
import org.bytedeco.javacv.*;
import org.bytedeco.javacpp.*;
import org.jboss.netty.buffer.*;
import org.ros.internal.message.*;


% Flags
Flags.isCompressed = false;

grabber = FrameGrabber.createDefault(0);
grabber.start();

% enable it if you want matlab will start the roscore.
roscore = rosmatlab.roscore('10.0.0.7',11311);

% Create a new node named /NODE and connect it to the master.
% if you enable matlab roscore, please put this in the second arrgument:
% roscore.RosMasterUri / 'http://localhost:11311'
node = rosmatlab.node('NODE',roscore.RosMasterUri);

publisherCompressed = rosmatlab.publisher('/camera/image/compressed','sensor_msgs/CompressedImage', node);
publisherRaw = rosmatlab.publisher('/camera/image/raw','sensor_msgs/Image', node);


subscriberCompressedImage2 = rosmatlab.subscriber('/image_converter/output_video/compressed','sensor_msgs/CompressedImage',30,node);
subscriberCompressedImage2.setOnNewMessageListeners({@showCompressedImageData2});

subscriberCompressedImage1 = rosmatlab.subscriber('/camera/image/compressed','sensor_msgs/CompressedImage',30,node);
subscriberCompressedImage1.setOnNewMessageListeners({@showCompressedImageData1});

subscriberImage2 = rosmatlab.subscriber('/image_converter/output_video/raw','sensor_msgs/Image',30,node);
subscriberImage2.setOnNewMessageListeners({@showImageData2});

subscriberImage1 = rosmatlab.subscriber('/camera/image/raw','sensor_msgs/Image',30,node);
subscriberImage1.setOnNewMessageListeners({@showImageData1});

stream = ChannelBufferOutputStream(MessageBuffers.dynamicBuffer());

%% grab image
while loopCondition()
    img = grabber.grab();
    buffer = img.image(1);
    ptr = BytePointer(buffer);
    
    if Flags.isCompressed
        
        image = javaObject('org.bytedeco.javacpp.opencv_core$Mat',img.imageHeight,img.imageWidth,opencv_core.CV_8UC3);
        image  = image.data(ptr);
        
        ptr = BytePointer();
        opencv_imgcodecs.imencode('.jpg',image,ptr);
        
        cvImage = javaMethod('create', 'org.bytedeco.javacpp.opencv_core$CvMat', 1, ptr.limit, opencv_core.CV_8UC1);
        cvImage  = cvImage.data_ptr(ptr);
        data = cvImage.get();
        data = uint8(data);
        stream = ChannelBufferOutputStream(MessageBuffers.dynamicBuffer());
        stream.write(data);

        msg = rosmatlab.message('sensor_msgs/CompressedImage', node);
        msg.setFormat('jpg');
        msg.setData(stream.buffer().copy());
        publisherCompressed.publish(msg);
    else
        cvImage = javaMethod('create', 'org.bytedeco.javacpp.opencv_core$CvMat', img.imageHeight,img.imageWidth, opencv_core.CV_8UC3);
        cvImage  = cvImage.data_ptr(ptr);
        data = cvImage.get();
        data = uint8(data);
        
        stream = ChannelBufferOutputStream(MessageBuffers.dynamicBuffer());
        stream.write(data);
        
        msg = rosmatlab.message('sensor_msgs/Image', node);
        msg.setEncoding('bgr8');
        msg.setWidth(img.imageWidth);
        msg.setHeight(img.imageHeight);
        msg.setStep(img.imageStride);               
        msg.setData(stream.buffer().copy());
        publisherRaw.publish(msg);
    end
        pause(0.001);
end
stopWebcamDriver;
%%