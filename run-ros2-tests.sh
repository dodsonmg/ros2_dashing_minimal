#!/bin/sh -xe

ROS2_ROOT="$(realpath .)"
if ! test -e "${ROS2_ROOT}/run-ros2-tests.sh"; then
   echo "You have to cd to the directory where $0 is located first!"
   exit 1
fi

ROS2_TEST="${ROS2_ROOT}/install/ros2_cheribsd_test/lib/ros2_cheribsd_test/cheribsd_test"

echo "${0}: ROS2 test binary details:"
if ! command -v file > /dev/null; then
	echo "file binary not installed"
else
	file "${ROS2_TEST}"
fi

# set LD_CHERI_LIBRARY_PATH and LD_LIBRARY_PATH to include all the ROS2 libraries
. ${ROS2_ROOT}/cheri_setup.sh

ldd ${ROS2_TEST}

if "${ROS2_TEST}"
then
	echo "TESTS SUCCCEEDED"
else
    echo "Got test failures"
    false
fi
