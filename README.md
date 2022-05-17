# OvernightTracking

Tracking non-human primate movements through a 24-hour period using an XBox one Kinect. Both Python and MATLAB versions are included, but the project mainly used the Python scripts. Due to constraints on recording video in the primate center, movements were collected via changes in depth using the IR camera. 

One disadvantage of this method is its inability to track rotations. However, its similarity to the accelerometer data from the Neurochip3 mounted on the animal's head showed the animal rarely engages in perfectly rotational movement.

## Analyses Performed
For each frame:
- Apply a gaussian blur to remove noise.
- Subtract from the previous frame to find the difference in distance for each pixel. 
- Find the largest region with a positive change (moved away) and the largest region with a negative change (moved closer). The changes were initially separated to account for proximity to the camera (i.e. the same movement closer to the camera will be detected as a larger movement) but the effect of distance was inconsequential in frame-by-frame analysis. 
- Find the centroid, raw sum, and average change of both the positive and negative regions.
- Save the above values as well as the current time into a binary file.
- Load data and plot the changes over time.

Example of calculating the differences on a hand wave:

<p align="center">
  <img width="1000" height="620" src="https://github.com/richyyun/OvernightTracking/blob/main/TrackingExample.png">
</p>

                                                                                                                 
