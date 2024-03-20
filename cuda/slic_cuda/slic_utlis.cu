#include <torch/extension.h>
#include <curand_kernel.h>
#include "slic_utils.cuh"
#include <iostream>
#include <thrust/device_vector.h>
#include <thrust/copy.h>
#include <thrust/transform.h>
#include <thrust/functional.h>

__global__ void find_coords_opt(
    const int64_t * __restrict__ segment,
    const int64_t * __restrict__ segment_unique,
    const int64_t * __restrict__ segment_count,
    const int * __restrict__ pos,
    int H,
    int W,
    int num_segment,
    int64_t * pixel_coord,
    int64_t * segment_index
){
    // every block is responsible for origin data
    // every thread is responsible for a pixel
    // every thread will check if the pixel belongs to the segment
    // if yes, then write the pixel to the pixel_coord
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= H*W) return;

    // load block shared memory


    int i = idx / W;
    int j = idx % W;

}


__global__ void find_coords(
    const int64_t * __restrict__ segment,
    const int64_t * __restrict__ segment_unique,
    const int64_t * __restrict__ segment_count,
    const int * __restrict__ pos,
    int H,
    int W,
    int num_segment,
    int64_t * pixel_coord,
    int64_t * segment_index
){
    int segment_idx = blockIdx.x;
    if (segment_idx >= num_segment) return;

    // a shared memory to store the start index of each segment
    __shared__ int index;
    if(threadIdx.x == 0)
    {
        index = pos[segment_idx];
    }
    __syncthreads();

    // int start = pos[segment_idx];
    int count = segment_count[segment_idx];
    int segment_id = segment_unique[segment_idx];

    for(int pixel_idx = threadIdx.x; pixel_idx < H*W; pixel_idx += blockDim.x){
        int i = pixel_idx / W;
        int j = pixel_idx % W;
        // printf("segment_idx: %d, pixel_idx: %d\n", segment_id, pixel_idx);
        if (segment[pixel_idx] == segment_id){
            int idx = atomicAdd(&index, 1);
            // printf("idx: %d\n", index);
            pixel_coord[idx*2] = i;
            pixel_coord[idx*2 + 1] = j;
            segment_index[idx] = segment_id;
            // atomicAdd(&index, 1);
        }
    }
}

void generate_sample(torch::Tensor segment,
                    torch::Tensor segment_unique,
                    torch::Tensor segment_count,
                    torch::Tensor pixel_coords,
                    torch::Tensor segment_index,
                    // at::Tensor
                    int H,
                    int W,
                    int num_sample,
                    float sample_ratio){

    CHECK_INPUT(segment);
    CHECK_INPUT(segment_unique);
    CHECK_INPUT(segment_count);
    CHECK_INPUT(pixel_coords);
    CHECK_INPUT(segment_index);

    int num_segment = segment_unique.size(0);
    int num_point = segment.size(0);

    int sample_count = 0;
    thrust::device_vector<int64_t> segment_count_thrust(segment_count.data_ptr<int64_t>(), segment_count.data_ptr<int64_t>() + num_segment);
    // sample_count = thrust::reduce(segment_count_thrust.begin(), segment_count_thrust.end());

    int* pos;
    cudaMallocManaged(&pos, num_segment * sizeof(int));

    // compute results start position
    for (int i=0; i<num_segment; ++i)
    {
        pos[i] = thrust::reduce(segment_count_thrust.begin(), segment_count_thrust.begin() + i);
    }
    cudaDeviceSynchronize();

    // printf("befor kernel function : %s\n",cudaGetErrorString(cudaGetLastError()));

    int num_thread = 512;
    int num_blocks = num_segment;
    // printf("number of blocks: %d\n", num_blocks);
    find_coords<<<num_blocks, num_thread>>>(segment.data_ptr<int64_t>(), 
                                                    segment_unique.data_ptr<int64_t>(), 
                                                    segment_count.data_ptr<int64_t>(), 
                                                    pos,
                                                    H, W, num_segment, pixel_coords.data_ptr<int64_t>(), segment_index.data_ptr<int64_t>());
    cudaDeviceSynchronize();
    // printf("after kernel function : %s\n",cudaGetErrorString(cudaGetLastError()));
    
    cudaFree(pos);
}