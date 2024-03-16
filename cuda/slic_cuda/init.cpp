#include "utils.h"
#include "slic_utils.cuh"
#include <cuda_runtime.h>

int get_tensor_shape(const torch::Tensor& tensor, int dim) {
    return tensor.size(dim);
}

void test_random_init(int min, int max, int N) {
    int results[N];

    check_random_init(min, max, N, results);
    printf("Results: ");
    for (int i = 0; i < N; i++) {
        printf("%d ", results[i]);
    }
}

torch::Tensor findIndex2D(torch::Tensor d_tensor, int rows, int cols, int d_int)
{
    torch::Tensor result = findIndex(d_tensor, rows, cols, d_int);
    return result;
}

at::Tensor sample_superpixel(
    torch::Tensor segment,
    torch::Tensor segment_unique,
    torch::Tensor segment_count,
    int H,
    int W,
    int num_sample,
    float sample_ratio
){

    CHECK_INPUT(segment);
    CHECK_INPUT(segment_unique);
    CHECK_INPUT(segment_count);
    // print segment shape
    at::Tensor pixel_coord1 = generate_sample(segment, segment_unique, segment_count, H, W, num_sample, sample_ratio);
    at::Tensor pixel_coord2 = generate_sample(segment, segment_unique, segment_count, H, W, num_sample, sample_ratio);
    at::Tensor pixel_coord3 = generate_sample(segment, segment_unique, segment_count, H, W, num_sample, sample_ratio);
    at::Tensor pixel_coord4 = generate_sample(segment, segment_unique, segment_count, H, W, num_sample, sample_ratio);
    at::Tensor pixel_coord5 = generate_sample(segment, segment_unique, segment_count, H, W, num_sample, sample_ratio);
     
    // record time
    auto start = std::chrono::high_resolution_clock::now();
    at::Tensor pixel_coord = generate_sample(segment, segment_unique, segment_count, H, W, num_sample, sample_ratio);
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;
    std::cout << "Elapsed time: " << elapsed.count() << " s\n";


    return pixel_coord;
}

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m){
    m.def("get_tensor_shape", &get_tensor_shape);
    m.def("test_random_init", &test_random_init);
    m.def("findIndex2D", &findIndex2D);
    m.def("sample_superpixel", &sample_superpixel);
}

