import numpy as np
import cv2
import struct
from pykinect2 import PyKinectV2
from pykinect2 import PyKinectRuntime
from datetime import datetime

''' Initialization '''
# File name and path
name = 'PythonTest.bin'
path = 'C:/Users/Richy Yun/Dropbox/Fetz Lab/Brain States/Videos/'

filename = path+name

file = open(filename,'wb')

# Time used for current time calculation
basetime = datetime.fromisoformat('2021-01-01 00:00:00.000')

# Start kinect
kinect = PyKinectRuntime.PyKinectRuntime(PyKinectV2.FrameSourceTypes_Depth)

# Variables
n = 10 # look at n largest regions
thresh = 200 # threshold for binary images

# Begin collection loop
lastframe = []
print('Starting')
starttime = datetime.now()
print(starttime)
try:
    while True:
        
        # Current time
        now = datetime.now()
        now = now - basetime
        now = float(now.days*60*60*24) + float(now.seconds) + float(now.microseconds/10**6) 
    
        ''' Get frame '''
        frame = kinect.get_last_depth_frame()
        
        # Skip if nothing 
        if(frame is None or sum(frame) == 0):
            continue
        
        # Blur and shape into screen
        frame = cv2.GaussianBlur(frame,(5,5),0)
        frame = np.reshape(frame,(424,512))
        
        # Set to most recent frame if first frame
        if (len(lastframe) == 0):
            lastframe = np.copy(frame)
            continue
        
        # Difference between frames
        diff = lastframe.astype(int)-frame.astype(int)
        
        ''' Positive difference (moved towards) '''
        posdiff = np.copy(diff)        
        posdiff[posdiff<thresh] = 0
        posdiff[posdiff>=thresh] = 255
                
        # Get all connected regions
        nlabels, labels, stats, centroids = cv2.connectedComponentsWithStats(posdiff.astype(np.uint8), 4)
        area = stats[:,4]
        
        # Safety check
        if(nlabels<n):
            continue
        
        # Sort all regions from largest to smallest and get the highest n
        inds = (-area).argsort()[:n+1]
        inds = inds[1:n]
        
        # Sum of all changes in distance 
        weights = [sum(diff[labels==x]) for x in inds]
        
        # Calculate centroid, sum weights, calculate average distance of movement
        posCentroid = sum(centroids[inds,:] * np.transpose(np.tile(weights,(2,1))))/sum(weights)
        posWeight = sum(weights)
        posDist = np.mean([np.mean(frame[labels==x]) for x in inds])

        ''' Negative difference (moved away from) '''
        negdiff = np.copy(diff)        
        negdiff[negdiff>-thresh] = 0
        negdiff[negdiff<=-thresh] = 255
                
        # Get all connected regions
        nlabels, labels, stats, centroids = cv2.connectedComponentsWithStats(negdiff.astype(np.uint8), 4)
        area = stats[:,4]
        
        # Safety check
        if(nlabels<n):
            continue
        
        # Sort all regions from largest to smallest and get the highest n
        inds = (-area).argsort()[:n+1]
        inds = inds[1:n]
        
        # Sum of all changes in distance
        weights = [sum(-diff[labels==x]) for x in inds]
        
        # Calculate centroid, sum weights, calculate average distance of movement
        negCentroid = sum(centroids[inds,:] * np.transpose(np.tile(weights,(2,1))))/sum(weights)
        negWeight = sum(weights)
        negDist = np.mean([np.mean(lastframe[labels==x]) for x in inds])
        
        ''' Write to file '''
        tofile = struct.pack('dffffiiff', now, float(posCentroid[0]), float(posCentroid[1]),
                            float(negCentroid[0]), float(negCentroid[1]), 
                            int(posWeight), int(negWeight),
                            float(posDist), float(negDist))
        file.write(tofile)
        
        ''' Reset most recent frame '''
        lastframe = np.copy(frame)
        
except KeyboardInterrupt:
    pass

kinect.close()
file.close()

print('Done')
endtime = datetime.now()
print(endtime)
print('Duration:')
print(endtime-starttime)