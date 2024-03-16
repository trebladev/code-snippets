#include "utils.h"

torch::Tensor findIndex(torch::Tensor d_tensor, int rows, int cols, int d_int);

torch::Tensor generate_sample(torch::Tensor segment,
                    torch::Tensor segment_unique,
                    torch::Tensor segment_count,
                    int H,
                    int W,
                    int num_sample,
                    float sample_ratio);