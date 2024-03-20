#include "utils.h"


void generate_sample(torch::Tensor segment,
                    torch::Tensor segment_unique,
                    torch::Tensor segment_count,
                    torch::Tensor pixel_coord,
                    torch::Tensor segment_index,
                    int H,
                    int W,
                    int num_sample,
                    float sample_ratio);