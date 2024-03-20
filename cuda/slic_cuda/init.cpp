#include "utils.h"
#include "slic_utils.cuh"
#include <cuda_runtime.h>

void test(torch::Tensor input){
    printf("input size: %d\n", input.size(0));
}

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m){
    m.def("generate_sample", &generate_sample);
    m.def("test", &test, "test function");
}

