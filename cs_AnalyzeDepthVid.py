import struct
import numpy as np
from datetime import date
from datetime import datetime
from datetime import timedelta
from matplotlib import pyplot as plt

''' Load file '''
name = '20210315_Overnight.bin'
path = 'R:/Yun/Jafar/OvernightTracking/'

filename = path+name

with open(filename, mode='rb') as file: 
    fileContent = file.read()
    
# Calculate number of frames captured
# Divide by 4 once to get bytes, 4 to get 32 bits
# Double is 64 bit, so need to finally divide by 10
totalframes = int(len(fileContent)//4/10)

# Structure data
data = struct.unpack("dffffiiff" * totalframes, fileContent)
data = np.reshape(data,(totalframes,9))

''' Parse data '''
# Time used for current time calculation
# Add ts in seconds to this time to get real time
basetime = date.fromisoformat('2021-01-01 00:00:00.000')

# Time and delta t to check sampling rate
ts = data[:,0]
dt = np.diff(ts)

# Figure out start time
delta = timedelta(seconds=ts[0])
starttime = basetime+delta

# Weights
posWeight = data[:,5]
negWeight = data[:,6]
weight = (posWeight+negWeight)/2

plt.plot(ts-ts[0],posWeight)
plt.plot(ts-ts[0],negWeight)
plt.plot(ts-ts[0],weight)
plt.show()

# Distances
posDist = data[:,7]
negDist = data[:,8]
dist = (posDist+negDist)/2

# plt.plot(ts-ts[0],posDist)
# plt.plot(ts-ts[0],negDist)
# plt.plot(ts-ts[0],dist)
# plt.show()