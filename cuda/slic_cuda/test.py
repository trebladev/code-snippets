import torch
import slic_cuda
import time

segment = torch.load('data/segment.pth').cuda().to(torch.int64)
segment_unique, segment_count = torch.unique(segment, return_counts=True)
segment_unique = segment_unique.cuda().to(torch.int64)
segment_count = segment_count.cuda().to(torch.int64)

# segment_unique = torch.load('data/segment_unique.pth').to(torch.int32)
# segment_count = torch.load('data/count.pth').to(torch.int32)

# segment only 0, 1
# segment = torch.randn(4, 4).cuda()

# segment = torch.tensor([[1, 1, 1, 1],
#                         [0, 2, 1, 1],
#                         [2, 2, 3, 3],
#                         [2, 2, 3, 3]], dtype=torch.int32).cuda()
# segment_unique, segment_count = torch.unique(segment, return_counts=True)
# segment_count = segment_count.to(torch.int32)
# print(f'segment: {segment}')
# print(f'segment_unique: {segment_unique[0:2]}')
# print(f'segment_count: {segment_count[0:2]}')
print(f'segment shape: {segment.shape}')
print(f'segment_unique shape: {segment_unique.shape}')
print(f'segment_count shape: {segment_count.shape}')

pixel_coord = torch.empty((segment_count[segment_unique].sum(), 2), dtype=torch.int64).cuda().flatten()
segment_index = torch.empty((segment_count[segment_unique].sum()), dtype=torch.int64).cuda()

# calculate time of slic_cuda.generate_sample with torch time
torch.cuda.synchronize()
start, end = torch.cuda.Event(enable_timing=True), torch.cuda.Event(enable_timing=True)
start.record()
result = slic_cuda.generate_sample(segment, 
                            segment_unique, 
                            segment_count, 
                            pixel_coord,
                            segment_index,
                            int(segment.shape[0]), int(segment.shape[1]), 1000, 0.5)
end.record()
torch.cuda.synchronize()
print(f"Time: {start.elapsed_time(end)} ms")


# print(f'result shape: {result.shape}')
# print(f'result: {result}')
# print(torch.count_nonzero(segment[result[..., 0], result[..., 1]]))
# print(result.shape)
# print(torch.count_nonzero(segment == 0))

print(pixel_coord.view(-1, 2))
print(segment[pixel_coord.view(-1, 2)[:, 0], pixel_coord.view(-1, 2)[:, 1]])
print(segment_index)
# print(f'result: {segment[[..., 0], result[..., 1]]}')
# print(segment.max())
# print(segment_unique[-1])
# print(torch.sum(segment_count))



# all_cocunt = 0
# for count in segment_count:
#     all_cocunt += int(count * 0.5)

# print(all_cocunt)

