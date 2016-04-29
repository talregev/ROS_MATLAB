clearJava = false;
if exist('grabber')
    clearJava = true;
    grabber.stop();
end
clear import;
if clearJava
    clear java;
end
clearvars;