clear; close all;

fname = 'ExampleRecording';
path = 'C:\Users\Richy Yun\Dropbox\Fetz Lab\Brain States\Videos';

depthDevice = imaq.VideoDevice('kinect',2);
depthDevice();

vidname = [fullfile(path,fname),'.bin'];
FID = fopen(vidname,'w');

% For example video
vidname = [fullfile(path,fname),'.avi'];
v = VideoWriter(vidname,'Motion JPEG AVI');
v.FrameRate = 30;
v.Quality = 100;
open(v);

tic;
t = 0;
pause(2);
preframe = [];
start = now;
display(['Started: ', datestr(start)]);
fig = figure; axis off; title('Close figure to end');
% xres = 512; yres = 424; xfov = 70.6; yfov = 60;
while ishghandle(fig)
    
    if true %(t > 0.1) % set this if we want to lower framerate
        tic; % Reset timing
        
        ftime = clock; ftime(end) = ftime(end)*1000;
        
        % Downsize
        data = depthDevice();
        
        % Blur
        blur = imgaussfilt(data,1);
        
%         blur = imresize(blur,0.5);
        
        % Initialization
        if(isempty(preframe))
            preframe = blur;
            continue;
        end
        
        bad = blur == 0 | blur == 2^13 | preframe == 0 | preframe == 2^13;
                
        %% See if there is a change since last frame
        change = preframe-blur;
        changebin = imbinarize(change,0.01);
        props = regionprops(changebin);
%         props = regionprops(changebin,'area','centroid','PixelList');
        area = extractfield(props,'Area');
        [~,keep] = maxk(area,5);
        props = props(keep);
%         coord = cell2mat({props.PixelList}');
        
        if(isempty(props)) % If no change at all, save zeros
            posweight = 0;
            poscentroid = [0,0];
            
        else % Otherwise find combined centroid and weight
            if(length(props)==1)
                posweight = sum(change(changebin==1));
                poscentroid = props.Centroid;
            else
                posweight = extractfield(props,'Area');
                poscentroid = extractfield(props,'Centroid');
                poscentroid = reshape(poscentroid,2,length(poscentroid)/2)';
                poscentroid = sum(poscentroid.*posweight'.^2);
                poscentroid = poscentroid./sum(posweight.^2);
                posweight = sum(posweight);
%                 temp = arrayfun(@(x,y) change(x,y),coord(:,2),coord(:,1));
%                 posweight = sum(double(temp));
            end
        end
%         temp = diag(blur(coord(:,2),coord(:,1)));
%         avgposdist = double(nanmean(temp(:)));
%         posweight = posweight;%*(avgposdist./2^13);
        
        negchange = blur-preframe;
        changebin = imbinarize(negchange,0.01);
        props = regionprops(changebin);
%         props = regionprops(changebin,'area','centroid','PixelList');
        area = extractfield(props,'Area');
        [~,keep] = maxk(area,5);
        props = props(keep);
%         coord = cell2mat({props.PixelList}');
        
        if(isempty(props))
            negweight = 0;
            negcentroid = [0,0];
        else
            if(length(props)==1)
                negweight = sum(negchange(changebin==1));
                negcentroid = props.Centroid;
            else
                negweight = extractfield(props,'Area');
                negcentroid = extractfield(props,'Centroid');
                negcentroid = reshape(negcentroid,2,length(negcentroid)/2)';
                negcentroid = sum(negcentroid.*negweight'.^2);
                negcentroid = negcentroid./sum(negweight.^2);
                negweight = sum(negweight);
%                 temp = arrayfun(@(x,y) negchange(x,y),coord(:,2),coord(:,1));
%                 negweight = sum(double(temp));
            end
        end
%         temp = preframe(coord(:,2),coord(:,1));
%         avgnegdist = double(nanmean(temp(:)));
%         negweight = negweight;%*(avgnegdist./2^13);
        
        % Write to binary file. Save as float?
        fwrite(FID,[ftime(2:end),poscentroid,negcentroid,posweight,negweight],'int32');
        
        % Set previous frame to current frame
        preframe = blur;
        
        %% Test recording
        temp = single(data)./2^13;
        
        % Tracking box
        centroid = round(mean([poscentroid;negcentroid]));
        temp(max(1,centroid(2)):min(size(temp,1),centroid(2)),...
            max(1,centroid(1)):min(size(temp,2),centroid(1))) = 1;
        temp(max(1,centroid(2)):min(size(temp,1),centroid(2)),...
            max(1,centroid(1)):min(size(temp,2),centroid(1))) = 1;

        weight = mean([posweight,negweight]);
        width = round(sqrt(weight));
        
        lr = centroid(2)-width-1:centroid(2)-width;
        ud = centroid(1)-width-1:centroid(1)+width+1;
        [x,y] = ndgrid(lr,ud); x = x(:); y = y(:);
        bad = x<=0 | x>size(temp,1) | y<=0 | y>size(temp,2);
        left = [x(:),y(:)]; left(bad,:) = [];
        temp(left(:,1),left(:,2)) = 1;
        
        lr = centroid(2)+width:centroid(2)+width+1;
        ud = centroid(1)-width-1:centroid(1)+width+1;
        [x,y] = ndgrid(lr,ud); x = x(:); y = y(:);
        bad = x<=0 | x>size(temp,1) | y<=0 | y>size(temp,2);
        right = [x(:),y(:)]; right(bad,:) = [];
        temp(right(:,1),right(:,2)) = 1;
        
        lr = centroid(2)-width-1:centroid(2)+width+1;
        ud = centroid(1)-width-1:centroid(1)-width;
        [x,y] = ndgrid(lr,ud); x = x(:); y = y(:);
        bad = x<=0 | x>size(temp,1) | y<=0 | y>size(temp,2);
        down = [x(:),y(:)]; down(bad,:) = [];
        temp(down(:,1),down(:,2)) = 1;
        
        lr = centroid(2)-width-1:centroid(2)+width+1;
        ud = centroid(1)+width:centroid(1)+width+1;
        [x,y] = ndgrid(lr,ud); x = x(:); y = y(:);
        bad = x<=0 | x>size(temp,1) | y<=0 | y>size(temp,2);
        up = [x(:),y(:)]; up(bad,:) = [];
        temp(up(:,1),up(:,2)) = 1;
            
        % Make video
        writeVideo(v,temp);

    end
    t = toc;
end
finish = now;
display('Finished: ', datestr(finish));
dur = datevec(finish-start);
fprintf('Duration: %d days, %d hours, %d minutes, %2.2f seconds\n',dur(3),dur(4),dur(5),dur(6));

release(depthDevice);
fclose(FID);
close(v);
