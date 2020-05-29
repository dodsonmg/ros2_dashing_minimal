#!/bin/bash
#
# build command for colcon

# TOOLCHAIN_PATH="/home/broomstick/cheri/ros2_dashing_min/CrossToolchain_old.cmake"

# necessary to find the .cmake files for poco pre-built library
# CHERI_PREFIX_PATH="/home/broomstick/cheri/output/sdk/sysroot128/usr/local/mips-purecap/libcheri/cmake"

if [ "$#" -eq 0 ]; then
	colcon build \
		--packages-skip-build-finished \
		--build-base ./build_ubuntu \
		--install-base ./install_ubuntu \
		--cmake-args \
			-DBUILD_TESTING=NO \
		--no-warn-unused-cli

elif [ "$#" -eq 1 ]; then
    if [ "$1" = "clean" ]; then
		rm -r ./build_ubuntu ./install_ubuntu
		colcon build \
			--build-base ./build_ubuntu \
			--install-base ./install_ubuntu \
			--cmake-args \
				-DBUILD_TESTING=NO \
			--no-warn-unused-cli
    else
		rm -r ./build_ubuntu/$1 ./install_ubuntu/$1
		colcon build \
			--packages-skip-build-finished \
			--build-base ./build_ubuntu \
			--install-base ./install_ubuntu \
			--packages-up-to=$1 \
			--cmake-args \
				-DBUILD_TESTING=NO \
			--no-warn-unused-cli
    fi
elif [ "$#" -eq 2 ]; then
    if [ "$2" = "clean" ]; then
		rm -r ./build_ubuntu/$1 ./install_ubuntu/$1
		colcon build \
			--packages-up-to=$1 \
			--build-base ./build_ubuntu \
			--install-base ./install_ubuntu \
			--cmake-args \
				-DBUILD_TESTING=NO \
			--no-warn-unused-cli
	else
	    echo "Usage: ./build.sh [package] [clean]"
    fi
else
    echo "Usage: ./build.sh [package] [clean]"
fi
