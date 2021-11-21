%% Analyze videos recorded using the Kinect with the Python script

fname = 'C:\ExampleRecording.bin';
FID = fopen(fname,'r');

fields = {'double','single','single','single','single','int32','int32','single','single'};
fieldsizes = [8, 4, 4, 4, 4, 4, 4, 4, 4];
skip = @(n) sum(fieldsizes) - fieldsizes(n); 
offset = @(n) sum(fieldsizes(1:n)); 

data = [];
for i = 1:length(fieldsizes)
    data(:,i) = fread(FID, inf, fields{i}, skip(i));
    fseek(FID, offset(i), -1);
end

time = data(:,1);

posWeight = data(:,6);
negWeight = data(:,7);

weight = (posWeight+negWeight)/2;

figure; plot((time-time(1))/60/60,weight);
hold on; plot((time-time(1))/60/60,smooth(weight));
xlabel('Hours')

posDist = data(:,8);
negDist = data(:,9);

temp = posWeight.*posDist;
temp2 = negWeight.*negDist;

yl = ylim;
hold on; plot([3.25,3.25],yl,'k--');

