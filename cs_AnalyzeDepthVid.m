%% Analyze videos recorded using the Kinect with the MATLAB script

fname = 'C:\ExampleRecording.bin';
FID = fopen(fname,'r');
data = fread(FID,[11,inf],'int32');

time = data(1:5,:);
time = time.*[60*60*24*30;60*60*24;60*60;60;.001];
time = sum(time);
dt = diff(time);

poscentroid = data(6:7,:);

negcentroid = data(8:9,:);

posweight = data(10,:);

negweight = data(11,:);

figure; plot(time-time(1),negweight);
hold on; plot(time-time(1),posweight);
hold on; plot(time-time(1),(negweight+posweight)/2)