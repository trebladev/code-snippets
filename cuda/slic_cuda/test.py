import torch
import slic_cuda

segment = torch.load('data/segment.pth').to(torch.int32)
segment_unique, segment_count = torch.unique(segment, return_counts=True)
segment_unique = segment_unique.to(torch.int32)
segment_count = segment_count.to(torch.int32)
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
# print(f'segment_unique: {segment_unique}')
# print(f'segment_count: {segment_count}')
print(f'segment shape: {segment.shape}')
print(f'segment_unique shape: {segment_unique.shape}')
print(f'segment_count shape: {segment_count.shape}')

result = slic_cuda.sample_superpixel(segment.cuda(), 
                            segment_unique.cuda(), 
                            segment_count.cuda(), segment.shape[0], segment.shape[1], 1000, 0.5)

# print(f'result shape: {result.shape}')

# print(f'result: {result}')
# print(torch.count_nonzero(segment[result[..., 0], result[..., 1]]))
# print(result.shape)
# print(torch.count_nonzero(segment == 0))

print(f'result: {segment[result[..., 0], result[..., 1]]}')
print(segment.max())
print(segment_unique[-1])
print(torch.sum(segment_count))
print(result.shape)



# all_cocunt = 0
# for count in segment_count:
#     all_cocunt += int(count * 0.5)

# print(all_cocunt)

