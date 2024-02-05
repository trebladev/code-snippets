import torch
import open3d as o3d
import numpy as np
import argparse
import time
import frnn
# from frnn import frnn_grid_points

def args_config():
    parser = argparse.ArgumentParser()
    parser.add_argument('--file_name', type=str, help='ply file name', \
                        default='/home/steve/Desktop/pc/pointnerf/lego_pointnerf.ply')
    parser.add_argument('--k_n', type=int, default=8, help='the number of nearest neighbors')
    parser.add_argument('--vis', action='store_true', help='Enable visualize') 
    parser.add_argument('--vis_radius', type=int, help='sphere radius of chosen points visualization', \
                        default=0.005)
    parser.add_argument('--ignore_query_point', action='store_true', help="If True the points that coincide with"
                        "the center of the search window will be ignored. This excludes the query point if ‘queries’"
                        "and ‘points’ are the same point cloud.")
    config = parser.parse_args()
    return config

def knn(args):
    device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
    # load points, print necessary infomation
    pcd = o3d.io.read_point_cloud(args.file_name)
    # gray color
    pcd.colors = o3d.utility.Vector3dVector(np.tile([0.5, 0.5, 0.5], (pcd.points.__len__(), 1)))
    pcd_array = np.asarray(pcd.points)
    
    idx_chosen = [65535]# chosen point cloud
    
    queries_array = pcd_array[idx_chosen]
    queries_array.shape = (-1, 3)
    print(time.strftime(f'[%m.%d--%H:%M:%S] Start...'))
    print(f"Load a point cloud from {args.file_name} with points {pcd_array.shape[0]}.")
    
    # compute queries knn
    points = torch.tensor(pcd_array, dtype=torch.float32, device=device).unsqueeze(0)
    queries = torch.tensor(queries_array, dtype=torch.float32, device=device).unsqueeze(0)
    num_queries = queries_array.shape[0]
    lengths2 = torch.tensor([pcd_array.shape[0]], dtype=torch.int64, device=device)
    lengths1 = torch.tensor([queries_array.shape[0]], dtype=torch.int64, device=device)
    
    # start = torch.cuda.Event(enable_timing=True)
    # end = torch.cuda.Event(enable_timing=True)
    # # start.record()
    dists, idxs, nn, grid = frnn.frnn_grid_points(queries, points, lengths1, lengths2, args.k_n, 0.1, grid=None, return_nn=False, return_sorted=True)
    # end.record()
    # print(f'knn time: {start.elapsed_time(end)} ms')
    #print the time
    
    
    print(f'knn idx: {idxs}')
    print(idxs.squeeze(0).shape)
    
    if args.vis:
        # o3d.visualization.draw_geometries([pcd])
        print("Visualize the point cloud.")
        # paint all points with specified color except the chosen points and neighbors
        np.asarray(pcd.colors)[:, :] = [0.5, 0.5, 0.5]
        # draw neighbors with specified color
        np.asarray(pcd.colors)[idxs.cpu().numpy(), :] = [0, 1, 0]
        
        vis = o3d.visualization.Visualizer()
        vis.create_window(window_name=f"lego_pointnerf {args.k_n} knn with distance")
        vis.get_render_option().point_size = 1
        opt = vis.get_render_option()
        opt.background_color = np.asarray([0, 0, 0])
        vis.add_geometry(pcd)
        # draw chosen points with specified color by sphere
        for i in idx_chosen:
            sphere = o3d.geometry.TriangleMesh.create_sphere(radius=0.005)
            sphere.paint_uniform_color(np.asarray([1, 0, 0]))
            sphere.translate(pcd_array[i])
            vis.add_geometry(sphere)
        
        vis.run()
        vis.destroy_window()
        
        
if __name__ == '__main__':
    config = args_config()
    knn(config)
