#! /bin/bash
set -e
# install necessary lib
echo "############### install necessary lib ###############" 
echo y|sudo -E apt install git vim cmake wget curl g++ gcc htop tmux tldr cmake-curses-gui smartmontools zsh

echo y|sudo -E apt install -y libglu1-mesa-dev mesa-common-dev mesa-utils
echo y|sudo -E apt install -y freeglut3-dev libglm-dev libassimp-dev libglew-dev
echo y|sudo -E apt install -y libglfw3 libglfw3-dev libglfw3-doc
echo y|sudo -E apt install libglvnd-dev

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# config git 
git config --global user.name "trebladev"
git config --global user.email "2253714301@qq.com"

# install eigen
sudo apt install libeigen3-dev

mkdir requirement_lib
cd requirement_lib

# update cmake
cmakeversion="3.24.0"
echo "############### update cmake to v${cmakeversion} ###############"
git clone -b v${cmakeversion} https://github.com/Kitware/CMake.git
cd CMake
./configure
make -j
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
echo y|sudo apt-get install cmake
echo y|sudo apt-get install libgoogle-glog-dev libgflags-dev
echo y|sudo apt-get install libatlas-base-dev
echo y|sudo apt-get install libsuitesparse-dev

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
make -j
sudo make install
cd ../../

# install pangolin-0,5 
echo "############### install Pangolin-0.5 ###############"
git clone https://github.com/trebladev/my-Pangolin0.5.git
mv my-Pangolin0.5 Pangolin-0.5 
cd Pangolin-0.5
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/Pangolin-0.5 ..
make -j
sudo make install 
cd ../../

# install pangolin 0.6
echo "############### install Pangolin ###############"
sudo apt install libgl1-mesa-dev libglew-dev
git clone -b v0.6 https://github.com/stevenlovegrove/Pangolin.git
cd Pangolin
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/Pangolin-0.6 ..
make -j
cd ../../
mv Pangolin Pangolin-0.6

# install g2o
echo "############### install g2o ###############"
echo y|sudo apt install libsuitesparse-dev qtdeclarative5-dev qt5-qmake libqglviewer-dev-qt5
git clone https://github.com/RainerKuemmerle/g2o.git
cd g2o
mkdir build && cd build
cmake ..
make -j
sudo make install
cd ../../

# install docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# get opencv 4.5.3
opencvversion="4.5.3"
echo "############### get opencv and opencv_contrib ###############"
git clone -b ${opencvversion} https://github.com/opencv/opencv.git
cd opencv
git clone -b ${opencvversion} https://github.com/opencv/opencv_contrib.git
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/opencv-4.5.3 -DWITH_TBB=ON -DOPENCV_EXTRA_MODULES=../opencv_contrib/modules ..
make -j
sudo make install
cd ../../
mv opencv opencv-4.5.3

# get opencv 3.16.0
opencvversion="3.4.16"
echo "############### get opencv and opencv_contrib ###############"
git clone -b ${opencvversion} https://github.com/opencv/opencv.git
cd opencv
git clone -b ${opencvversion} https://github.com/opencv/opencv_contrib.git
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/opencv-3.4.16 -DWITH_TBB=ON -DOPENCV_EXTRA_MODULES=../opencv_contrib/modules ..
make -j
sudo make install
cd ../../
mv opencv opencv-3.4.16

# get opencv 2.4.9
opencvversion="2.4.9"
echo "############### get opencv and opencv_contrib ###############"
git clone -b ${opencvversion} https://github.com/opencv/opencv.git
cd opencv
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/opencv-2.4.9 -DWITH_TBB=ON  ..
make -j
sudo make install
cd ../../
mv opencv opencv-2.4.9

# install librealsense2
echo y|sudo apt install libncurses5-dev
git clone https://github.com/IntelRealSense/librealsense.git
cd librealsense 
mkdir build && cd build 
cmake ..
make -j
sudo make install
cd ../../

#insall nvtop
echo y|sudo apt install libsystemd-dev libudev-dev libdrm-dev
git clone https://github.com/Syllo/nvtop.git
cd nvtop
mkdir build && cd build
cmake ..
make -j
sudo make install
cd ../../

# get pcl
pclversion="1.12.1"
echo "############### get pcl ###############"
git clone -b pcl-${pclversion} https://github.com/PointCloudLibrary/pcl.git
cd pcl
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/pcl-1.12.1 ..
make -j10
sudo make install
cd ../../

# install zsh
cd ~/
echo y|sudo apt-get install zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
chsh -s $(which zsh)
