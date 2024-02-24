import numpy as np
import cv2
from skimage.io import imread
from skimage.segmentation import slic, mark_boundaries
from skimage.util import img_as_float
import random

def sample_points_per_segment(image, labels, num_samples=10):
    """
    在每个超像素内随机采样指定数量的点。
    
    :param image: 原始图像数组。
    :param labels: 超像素标签数组。
    :param num_samples: 每个超像素采样的点的数量。
    :return: 采样点的坐标列表。
    """
    unique_labels = np.unique(labels)
    sampled_points = []

    for label in unique_labels:
        # 找到当前超像素的所有点
        y, x = np.where(labels == label)
        points = list(zip(x, y))  # 注意这里我们改为(x, y)以适应cv2的坐标系统
        if len(points) < num_samples:
            sampled_points.extend(points)
        else:
            sampled_points.extend(random.sample(points, num_samples))
    
    return sampled_points

# 读取图片
image = img_as_float(imread('00002.png'))

# 使用SLIC算法进行超像素分割
segments = slic(image, n_segments=2500, compactness=10, sigma=1, start_label=1)

# 标记超像素的边界
boundaries_marked_image = mark_boundaries(image, segments, color=(1, 0, 0))
boundaries_marked_image_cv2 = (boundaries_marked_image * 255).astype(np.uint8)  # 转换为cv2兼容的格式

# 在每个超像素内随机采样点
sampled_points = sample_points_per_segment(image, segments, num_samples=10)

# 使用cv2可视化采样点
for (x, y) in sampled_points:
    cv2.circle(boundaries_marked_image_cv2, (x, y), radius=2, color=(0, 255, 0), thickness=-1)  # 绿色点表示采样点

boundaries_marked_image_cv2 = cv2.cvtColor(boundaries_marked_image_cv2, cv2.COLOR_RGB2BGR)

cv2.imwrite('segment_sampled.png', boundaries_marked_image_cv2)

