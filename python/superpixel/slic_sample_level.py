import numpy as np
import cv2
from skimage.io import imread
from skimage.segmentation import slic, mark_boundaries
from skimage.util import img_as_float
import random

def color_complexity(image, labels):
    """
    计算每个超像素的颜色复杂度（标准差）。
    
    :param image: 原始图像数组。
    :param labels: 超像素标签数组。
    :return: 每个超像素的颜色复杂度。
    """
    unique_labels = np.unique(labels)
    complexity = {}
    for label in unique_labels:
        segment_pixels = image[labels == label]
        complexity[label] = np.std(segment_pixels)
    return complexity

def sample_points_per_segment_with_complexity(image, labels, complexity, low_threshold, high_samples=100, low_samples=2):
    """
    根据颜色复杂度在每个超像素内随机采样不同数量的点。
    
    :param image: 原始图像数组。
    :param labels: 超像素标签数组。
    :param complexity: 每个超像素的颜色复杂度。
    :param low_threshold: 低复杂度阈值。
    :param high_samples: 高复杂度采样数量。
    :param low_samples: 低复杂度采样数量。
    :return: 采样点的坐标列表。
    """
    sampled_points = []
    for label, comp in complexity.items():
        num_samples = low_samples if comp < low_threshold else high_samples
        y, x = np.where(labels == label)
        points = list(zip(x, y))
        if len(points) < num_samples:
            sampled_points.extend(points)
        else:
            sampled_points.extend(random.sample(points, num_samples))
    return sampled_points

# 读取图片
image = img_as_float(imread('00002.png'))

# 使用SLIC算法进行超像素分割
segments = slic(image, n_segments=2500, compactness=10, sigma=1, start_label=1)

# 计算颜色复杂度
complexity = color_complexity(image, segments)

# 根据颜色复杂度在每个超像素内随机采样点
low_threshold = np.mean(list(complexity.values())) * 0.5  # 示例阈值，可根据需要调整
sampled_points = sample_points_per_segment_with_complexity(image, segments, complexity, low_threshold)

# 标记超像素的边界
boundaries_marked_image = mark_boundaries(image, segments)
boundaries_marked_image_cv2 = (boundaries_marked_image * 255).astype(np.uint8)
marked_image = boundaries_marked_image_cv2.copy()
marked_image = cv2.cvtColor(marked_image, cv2.COLOR_RGB2BGR)

# 使用cv2可视化采样点
for (x, y) in sampled_points:
    cv2.circle(boundaries_marked_image_cv2, (x, y), radius=2, color=(0, 255, 0), thickness=-1)

boundaries_marked_image_cv2 = cv2.cvtColor(boundaries_marked_image_cv2, cv2.COLOR_RGB2BGR)
# 显示图像
cv2.imwrite('segment_sampled_level.png', boundaries_marked_image_cv2)
cv2.imwrite('segment_sampled_level_marked.png', marked_image)

