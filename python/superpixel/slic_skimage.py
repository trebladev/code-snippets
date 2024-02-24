from skimage.segmentation import slic, mark_boundaries
import matplotlib.pyplot as plt

image = plt.imread('00002.png')

segments = slic(image, n_segments=1000, compactness=10)

# save segment image to segment.png
# plt.imsave('segment.png', mark_boundaries(image, segments))
print(segments.shape)

