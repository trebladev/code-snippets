#! /bin/bash

# install necessary lib
echo "############### install necessary lib ###############"
sudo apt install git vim cmake wget curl g++ gcc htop tmux tldr cmake-curses-gui linux-perf

# install ros
echo "############### install ros noetic ###############"
sudo sh -c 'echo "deb http://mirrors.ustc.edu.cn/ros/ubuntu buster main" > /etc/apt/sources.list.d/ros-latest.list'
sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
sudo apt update
sudo apt install ros-noetic-desktop-full
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
source ~/.bashrc

# install eigen
sudo apt install libeigen3-dev
sudo cp -r /usr/local/include/eigen3/Eigen /usr/local/include 

mkdir requirement_lib
cd requirement_lib

# update cmake
cmakeversion="3.24.0"
echo "############### update cmake to v${cmakeversion} ###############"
git clone -b v${cmakeversion} https://github.com/Kitware/CMake.git
cd CMake
./configure
make
sudo make install
sudo update-alternatives --install /usr/bin/cmake cmake /usr/local/bin/cmake 1 --force
cd ../



# install fmt
echo "############### install fmt-8.1.1 ###############"
git clone -b 8.1.1 https://github.com/fmtlib/fmt.git
cd fmt
mkdir build && cd build
cmake ..
make -j
sudo make install
cd ../../


# install ceres
ceresversion="2.1.0"
echo "############### install ceres ${ceresversion}###############"
sudo apt-get install cmake
sudo apt-get install libgoogle-glog-dev libgflags-dev
sudo apt-get install libatlas-base-dev
sudo apt-get install libsuitesparse-dev

git clone -b ${ceresversion} https://github.com/ceres-solver/ceres-solver.git
cd ceres-solver
mkdir build && cd build
cmake ..
make -j6
sudo make install
cd ../../

# install sophus
echo "############### install Sophus ###############"
git clone https://github.com/strasdat/Sophus.git
cd Sophus
mkdir build && cd build
cmake ..
make 
sudo make install
cd ../../

# install pangolin
echo "############### install Pangolin ###############"
sudo apt install libgl1-mesa-dev libglew-dev
git clone https://github.com/stevenlovegrove/Pangolin.git
cd Pangolin
mkdir build && cd build
cmake ..
make -j
sudo make install
cd ../../

# install g2o
echo "############### install g2o ###############"
sudo apt install libsuitesparse-dev qtdeclarative5-dev qt5-qmake libqglviewer-dev-qt5
git clone https://github.com/RainerKuemmerle/g2o.git
cd g2o
mkdir build && cd build
cmake ..
make -j
sudo make install
cd ../../

# install docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# pull ros:kinetic
echo "############### pull ros:kinect ###############"
sudo docker pull paopaorobot/ros-vnc:kinetic

# get opencv 4.5.3
opencvversion="4.5.3"
echo "############### get opencv and opencv_contrib ###############"
git clone -b ${opencvversion} https://github.com/opencv/opencv.git
cd opencv
git clone -b ${opencvversion} https://github.com/opencv/opencv_contrib.git
mkdir build
cd ../
mv opencv opencv-4.5.3

# get opencv 3.4.16
echo "############### get opencv and opencv_contrib ###############"
git clone -b 3.4.16 https://github.com/opencv/opencv.git
cd opencv
git clone -b 3.4.16 https://github.com/opencv/opencv_contrib.git
mkdir build
cd ../
mv opencv opencv-3.4.16

# get pcl
pclversion="1.12.1"
echo "############### get pcl ###############"
git clone -b pcl-${pclversion} https://github.com/PointCloudLibrary/pcl.git
cd pcl
mkdir build
cd ../

# install zsh
cd ~/
sudo apt-get install zsh
git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
chsh -s $(which zsh)
