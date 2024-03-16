import glob
import os.path as osp
from setuptools import setup
from torch.utils.cpp_extension import CUDAExtension, BuildExtension


ROOT_DIR = osp.dirname(osp.abspath(__file__))
include_dirs = [osp.join(ROOT_DIR, "include")]

sources = glob.glob('*.cpp')+glob.glob('*.cu')


setup(
    name='slic_cuda',
    version='1.0',
    author='treblade',
    author_email='zhognwei_xuan@outlook.com',
    description='slic_cuda',
    long_description='cppcuda_tutorial',
    ext_modules=[
        CUDAExtension(
            name='slic_cuda',
            sources=sources,
            include_dirs=include_dirs,
            extra_compile_args={'cxx': ['-O2'],
                                'nvcc': ['-O2']}
        )
    ],
    cmdclass={
        'build_ext': BuildExtension
    }
)