#include <torch/extension.h>
#include <curand_kernel.h>
#include "slic_utils.cuh"
#include <iostream>
#include <thrust/device_vector.h>
#include <thrust/copy.h>
#include <thrust/transform.h>
#include <thrust/functional.h>

// generate random int, no repeat
__global__ void generate_random_int(int min, int max, int N, int* results)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < N)
    {
        curandState_t state;
        curand_init(0, idx, 0, &state);

        // Generate unique random intergers in the range [min, max]
        int range = max - min;
        int r = curand(&state) % range + min;

        results[idx] = r;

    }
}

__global__ void countIndexKernel(
    const int * __restrict__ d_tensor,
    int rows, int cols,  int d_int, 
    int* count){
    // 
    // int i = blockIdx.x * blockDim.x + threadIdx.x;
    // int j = blockIdx.y * blockDim.y + threadIdx.y;

    // // output shape is unknow
    // if (i >= rows || j >= cols) return;
    int ii= 0;
    int global_idx = blockIdx.y * gridDim.x * blockDim.x + blockIdx.x * blockDim.x + threadIdx.x;
    int i = global_idx / cols;
    int j = global_idx % cols;
    // printf("i: %d, j: %d\n", i, j);

    if (i >= rows || j >= cols) return;
    // printf("num idx %d \n ", i*cols + j);
    __syncthreads();

    if (d_tensor[i * cols + j] == d_int) {
        // atomicAdd(&count, 1);
        // *count += 1;
        atomicAdd(count, 1);
        // ii+=1;
    }
}

__global__ void findIndexKernel(
    const int * __restrict__ d_tensor,
    int rows, int cols, int d_int, int* result) {

    // int i = blockIdx.x * blockDim.x + threadIdx.x;
    // int j = blockIdx.y * blockDim.y + threadIdx.y;

    int global_idx = blockIdx.y * gridDim.x * blockDim.x + blockIdx.x * blockDim.x + threadIdx.x;
    int i = global_idx / cols;
    int j = global_idx % cols;

    if (i >= rows || j >= cols) return;

    // result shape is [rows*2]
    if (d_tensor[i * cols + j] == d_int) {
        result[2*i] = i;
        result[2*i + 1] = j;
    }
}

at::Tensor findIndex(at::Tensor d_tensor, int rows, int cols, int d_int)
{
    int *count;
    cudaMallocManaged(&count, sizeof(int));
    // cudaDeviceSynchronize(); 
    cudaMemset(count, 0, sizeof(int));
    // *count = 0;
    // int *count = &d_count;

    // compute the number of elements equal to d_int
    dim3 threadsPerBlock(16, 16);
    dim3 blocksPerGrid((rows + threadsPerBlock.x - 1) / threadsPerBlock.x, (cols + threadsPerBlock.y - 1) / threadsPerBlock.y);
    countIndexKernel<<<blocksPerGrid, threadsPerBlock>>>(d_tensor.data_ptr<int>(), rows, cols, d_int, count);
    cudaDeviceSynchronize();
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Error: %s\n", cudaGetErrorString(err));
    }
    // printf("count: ", *count, "\n");
    printf("count: %d", *count, "\n");

    // allocate memory for the result
    int* result;
    cudaMallocManaged(&result, *count * 2 * sizeof(int));
    // printf("count: ", *count, "\n");

    // find the index of the elements equal to d_int
    findIndexKernel<<<blocksPerGrid, threadsPerBlock>>>(d_tensor.data_ptr<int>(), rows, cols, d_int, result);
    cudaDeviceSynchronize();
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Error: %s\n", cudaGetErrorString(err));
    }

    torch::Tensor result_tensor = torch::from_blob(result, {*count, 2}, torch::kInt32);

    cudaFree(result);
    cudaFree(count);

    return result_tensor;

}

__global__ void find_coords(
    const int * __restrict__ segment,
    const int * __restrict__ segment_unique,
    const int * __restrict__ segment_count,
    const int * __restrict__ pos,
    int H,
    int W,
    int num_segment,
    int* results
){
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= num_segment) return;

    int count = segment_count[idx];
    int segment_idx = segment_unique[idx];
    int start = pos[idx];
    __syncthreads();

    int num_store = 0;
    #pragma unroll
    for (int i=0; i<H; ++i)
    {
        #pragma unroll
        for (int j=0; j<W; ++j)
        {
            if (segment[i*W+j] == segment_idx)
            {
                results[start*2 + num_store*2] = i;
                results[start*2 + num_store*2 + 1] = j;
                num_store += 1;
            }
        }
    }
}

torch::Tensor generate_sample(torch::Tensor segment,
                    torch::Tensor segment_unique,
                    torch::Tensor segment_count,
                    int H,
                    int W,
                    int num_sample,
                    float sample_ratio){
    int num_segment = segment_unique.size(0);
    int num_point = segment.size(0);

    int sample_count = 0;
    thrust::device_vector<int> segment_count_thrust(segment_count.data_ptr<int>(), segment_count.data_ptr<int>() + num_segment);
    sample_count = thrust::reduce(segment_count_thrust.begin(), segment_count_thrust.end());
    // for (int i=0; i<num_segment; ++i)
    // {
    //     int count = segment_count[i].item<int>();
    //     // sample_count += int(count * sample_ratio);
    //     sample_count += count;
    // }

    int* pixel_coords;
    cudaMallocManaged(&pixel_coords, sample_count * 2 * sizeof(int));

    int* pos;
    cudaMallocManaged(&pos, num_segment * sizeof(int));

    // thrust::device_vector<int> segment_count_thrust(segment_count.data_ptr<int>(), segment_count.data_ptr<int>() + num_segment);
    // thrust::devi segment_count_thrust(segment_count.data_ptr<int>(), segment_count.data_ptr<int>() + num_segment);
    for (int i=0; i<num_segment; ++i)
    {
        pos[i] = thrust::reduce(segment_count_thrust.begin(), segment_count_thrust.begin() + i);
    }

    dim3 threadsPerBlock(32, 32);
    dim3 blocksPerGrid((H + threadsPerBlock.x - 1) / threadsPerBlock.x, (W + threadsPerBlock.y - 1) / threadsPerBlock.y);
    find_coords<<<blocksPerGrid, threadsPerBlock>>>(segment.data_ptr<int>(), 
                                                    segment_unique.data_ptr<int>(), 
                                                    segment_count.data_ptr<int>(), 
                                                    pos,
                                                    H, W, num_segment, pixel_coords);
    cudaDeviceSynchronize();
    
    torch::Tensor pixel_torch = torch::from_blob(pixel_coords, {sample_count, 2}, torch::kInt32).clone();

    cudaFree(pixel_coords);
    cudaFree(pos);

    return pixel_torch;

}

// __global__ void generate_uniform_sample(
//     torch::Tensor segments,
//     torch::Tensor segments_unique,
//     int num_segment,
//     int num_sample,
//     torch::Tensor result_coords,
//     torch::Tensor result_segments)
// {
//     int idx = blockIdx.x * blockDim.x + threadIdx.x;
//     if (idx >= num_segment) return;

//     int segment_idx = segments_unique[idx].item<int>();
    

// }

void check_random_init(int min, int max, int N, int* results)
{
    int* d_results;
    cudaMalloc((void**)&d_results, N * sizeof(int));

    int threadsPerBlock = 256;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    generate_random_int<<<blocksPerGrid, threadsPerBlock>>>(min, max, N, d_results);

    cudaMemcpy(results, d_results, N * sizeof(int), cudaMemcpyDeviceToHost);
    cudaFree(d_results);
}