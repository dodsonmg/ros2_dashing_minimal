# Minimal build of ROS2 dashing C/C++ libraries

Based on the original ROS2 [installation instructions](https://index.ros.org/doc/ros2/Installation/Dashing/Linux-Development-Setup/)

## Add the ROS2 apt repository

```
sudo apt update && sudo apt install curl gnupg2 lsb-release
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'
```

## Install development tools and ROS tools

TODO:  I'm confident only a subset of these are needed for this minimal build, especially because we're disabling python-based testing.

```
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
```

## Get ROS2 code

These instructions assume this repository has been cloned into a workspace, such as `ros2_dashing_minimal`

Create a source workspace and clone repositories:

Ubuntu:
```
cd ~/ros2_dashing_minimal
mkdir src
vcs import src < ros2_minimal.repos
```

CHERI:
```
cd ~/cheri/ros2_dashing_minimal
mkdir src
vcs import src < ros2_minimal.repos
```

### Install dependencies with rosdep
```
sudo rosdep init
rosdep update
rosdep install --from-paths src --ignore-src --rosdistro dashing -y --skip-keys "console_bridge fastcdr fastrtps libopensplice67 libopensplice69 rti-connext-dds-5.3.1 urdfdom_headers"
```

### Ignore some sub-packages that we don't want to build

```
cd ~/cheri/ros2_dashing_minimal
touch ./src/ros2/rcl_logging/rcl_logging_log4cxx/COLCON_IGNORE
touch ./src/ros/ros_tutorials/turtlesim/COLCON_IGNORE
touch ./src/ros2/demos/intra_process_demo/COLCON_IGNORE
touch ./src/ros2/demos/pendulum_control/COLCON_IGNORE
touch ./src/ros2/demos/image_tools/COLCON_IGNORE
```

TODO: Create forks which remove these

## Build for Ubuntu

Two options:
1. Use the simple CLI input below
2. Use `build_ubuntu.sh`, which provides some command line arguments for building specific packages (currently not well documented) and builds and installs into directories with `_ubuntu` suffixes to avoid collision with the CHERI build (below)

CLI:
```
cd ~/ros2_dashing/
colcon build --symlink-install
```

Build script:
- `build_ubuntu.sh` will build all packages, but skip those that had successfully been built already
- `build_ubuntu.sh clean` will delete the `build` and `install` directories and build all packages
- `build_ubuntu.sh [package]` will build the named package only
- `build_ubuntu.sh [package] clean` will delete `build/[package]` and `install/[package]` and rebuild the named package and its dependencies

## Run on Ubuntu

First, source the setup file to set environment variables
```
cd ~/ros2_dashing_minimal
source ./install/setup.bash
```

There are ROS2 convenience programs that make it easy to run a given executable within a given package.  Here, we'll just run a demonstration directly:

```
cd ~/ros2_dashing_minimal
./install/minimal_composition_example/lib/minimal_composition_example/composition_composed
```

or

```
cd ~/ros2_dashing_minimal
./install_ubuntu/minimal_composition_example/lib/minimal_composition_example/composition_composed
```

depending on the install directory used.

## Build for CheriBSD

### Build the Poco library

This should be the only third-party library that needs to be independently built.  There is a `cheribuild` target, and we can build it with the purecap abi.
```
cd ~/cheribuild
./cheribuild.py poco-mips-purecap
```

This will create the library `libPocoFoundation.so.71` in `~/cheri/output/rootfs-purecap128/usr/local/mips-purecap/libcheri/`, which we will use below.

This will also create `CrossToolchain.cmake` in `~/cheri/build/poco-128-build`, which we will use below.

### Copy CrossToolchain.cmake from Poco

We need a `cmake` cross-compile toolchain file.  As `Poco` is a simple `cmake` project, and the ROS2 build system (`colcon`) is `cmake` based, we'll just steal that one.

```
cd ~/cheri/ros2_dashing_minimal
cp ~/cheri/build/poco-128-build/CrossToolchain.cmake .
```

TODO: Eventually, if we make ROS2 a `cheribuild` target, this shouldn't be necessary...

### Build ROS2 libraries

Two options:
1. Use the simple CLI input below
2. Use `build.sh`, which provides some command line arguments for building specific packages (currently not well documented)

CLI:
```
# absolute path to the CMAKE toolchain file
TOOLCHAIN_PATH="$PWD/CrossToolchain.cmake"

# absolute path to Poco's CMAKE directory
CMAKE_POCO_PATH="$HOME/cheri/output/sdk/sysroot128/usr/local/mips-purecap/libcheri/cmake"

colcon build \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_PATH \
        -DBUILD_TESTING=NO \
        -DTHIRDPARTY=ON \
        -DCMAKE_PREFIX_PATH="$CMAKE_POCO_PATH;$CMAKE_PREFIX_PATH" \
    --no-warn-unused-cli
```

Build script:
- `build.sh` will build all packages, but skip those that had successfully been built already
- `build.sh clean` will delete the `build` and `install` directories and build all packages
- `build.sh [package]` will build the named package only
- `build.sh [package] clean` will delete `build/[package]` and `install/[package]` and rebuild the named package and its dependencies

### Copy libPocoFoundation.so.71

We will need to link against `libPocoFoundation.so.71` at runtime, so we copy it locally.

```
cd ~/cheri/ros2_dashing_minimal
cp ~/cheri/output/rootfs-purecap128/usr/local/mips-purecap/libcheri/libPocoFoundation.so.71 .
```

TODO: If we can install `libPocoFoundation.so.71` into the hybrid `rootfs128` we may be able to link against it directly.  Given that `cheribuild` is currently installing it in `rootfs-purecap128`, however, it's easier to just copy the library locally to simplify paths for runtime linking

### Create a setup file for use within CheriBSD

ROS2 builds generate a handy setup file that we can source to set our environment variables correctly.  We 
need to convert these to CHERI enviroment variables.  Specifically, `LD_LIBRARY_PATH` -> `LD_CHERI_LIBRARY_PATH`

```
cd ~/cheri/ros2_dashing_minimal

# source the setup file created by ROS2
source ./install/setup.bash

# create a new setup file for CHERI
./convert_install_setup.py
```

`convert_install_setup.py` will create a file `cheri_install_setup.txt` that we can source from within `CheriBSD` to set our environment variables.

## Run on CheriBSD

Start `CheriBSD` on `QEMU` and login, as usual:
```
cd ~/cheribuild
./cheribuild.py run
```

Mount `rootfs` and `source` directories:
```
./qemu-mount-roofs.sh
./qemu-mount-source.sh
```

Change to the `ros2_dashing_minimal` directory and source the setup file (replace `<prefix>` with the contents of `$HOME` on your host machine):
```
cd <prefix>/cheri/ros2_dashing_minimal
source cheri_install_setup.txt
```

Run a demo program:
```
./install/examples_rclcpp_minimal_composition/lib/examples_rclcpp_minimal_composition/composition_composed
```
which should start a publisher and subscriber in the same process, with alternating lines printed to stdout saying `I published: [incrementing count]` and `I heard: [incrementing count]`.

Alternately, in two separate processes (requiring you to `ssh` into `CheriBSD` on another terminal):
```
./install/examples_rclcpp_minimal_publisher/lib/examples_rclcpp_minimal_publisher/publisher_not_composable
```
which should start a publisher printing to stdout `I published: [incrementing count]`.

```
./install/examples_rclcpp_minimal_subscriber/lib/examples_rclcpp_minimal_subscriber/subscriber_not_composable
```
which should start a subscriber printing to stdout `I heard: [incrementing count]`.


