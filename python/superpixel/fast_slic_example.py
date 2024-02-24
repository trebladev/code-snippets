import numpy as np

# Much faster than the standard class
from fast_slic.avx2 import SlicAvx2
from PIL import Image
from skimage.segmentation import mark_boundaries
import cv2
import time

with Image.open("00002.png") as f:
   image = np.array(f)
# import cv2; image = cv2.cvtColor(image, cv2.COLOR_RGB2LAB)   # You can convert the image to CIELAB space if you need.
slic = SlicAvx2(num_components=2500, compactness=10)
print(image.dtype)

start = time.time()
assignment = slic.iterate(image) # Cluster Map
end = time.time()
print(f'Elapsed time: {end - start} seconds')
image_marked = mark_boundaries(image, assignment)
boundaries_marked_image_cv2 = (image_marked * 255).astype(np.uint8)
cv2.imwrite('segment.png', boundaries_marked_image_cv2)
# print(assignment)
# print(slic.slic_model.clusters) # The cluster information of superpixels.