#!/bin/bash

## add ROS2 apt repository
sudo apt update && sudo apt install curl gnupg2 lsb-release
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'

## install development tools and ROS tools
sudo apt update && sudo apt install -y \
  build-essential \
  cmake \
  git \
  python3-colcon-common-extensions \
  python3-pip \
  python-rosdep \
  python3-vcstool \
  wget
# install some pip packages needed for testing
python3 -m pip install -U \
  argcomplete \
  flake8 \
  flake8-blind-except \
  flake8-builtins \
  flake8-class-newline \
  flake8-comprehensions \
  flake8-deprecated \
  flake8-docstrings \
  flake8-import-order \
  flake8-quotes \
  pytest-repeat \
  pytest-rerunfailures \
  pytest \
  pytest-cov \
  pytest-runner \
  setuptools
# install Cyclone DDS dependencies
sudo apt install --no-install-recommends -y \
  libcunit1-dev

## get ROS2 code
cd ~/cheri/ros2_dashing_minimal
mkdir src
vcs import src < ros2_minimal.repos

## install dependencies with rosdep
sudo rosdep init
rosdep update
rosdep install --from-paths src --ignore-src --rosdistro dashing -y --skip-keys "console_bridge libopensplice67 libopensplice69 urdfdom_headers"

## ignore packages we don't want to build
cd ~/cheri/ros2_dashing_minimal
touch ./src/ros2/rcl_logging/rcl_logging_log4cxx/COLCON_IGNORE
touch ./src/ros/ros_tutorials/turtlesim/COLCON_IGNORE
touch ./src/ros2/demos/intra_process_demo/COLCON_IGNORE
touch ./src/ros2/demos/pendulum_control/COLCON_IGNORE
touch ./src/ros2/demos/image_tools/COLCON_IGNORE

## build the Poco library
cd ~/cheribuild
./cheribuild.py poco-mips-purecap

## copy CrossToolchain.cmake from Poco
cd ~/cheri/ros2_dashing_minimal
cp ~/cheri/build/poco-128-build/CrossToolchain.cmake .

## build ROS2 libraries
cd ~/cheri/ros2_dashing_minimal
./build_cheri.sh clean

## copy libPocoFoundation.so.71 from Poco
cd ~/cheri/ros2_dashing_minimal
cp ~/cheri/output/rootfs-purecap128/usr/local/mips-purecap/libcheri/libPocoFoundation.so.71 .

## create a setup file for use within cheribsd
cd ~/cheri/ros2_dashing_minimal

# source the setup file created by ROS2
source ./install/setup.bash

# create a new setup file for CHERI
./convert_install_setup.py