#!/bin/sh -xe

# test run via cheribuild:
# ./cheribuild.py ros2-mips-purecap --test (or similar)

SOURCE="$(realpath .)"
INSTALL="/opt/riscv64-purecap"

if ! test -e "${SOURCE}/run-ros2-tests.sh"; then
   echo "You have to cd to the directory where $0 is located first!"
   exit 1
fi

# Can cheribuild set a host environment variable so we know the prefix for this test?
TEST="${INSTALL}/ros2/lib/ros2_cheribsd_test/cheribsd_test"

# set LD_CHERI_LIBRARY_PATH and LD_LIBRARY_PATH to include all the ROS2 libraries
. ${INSTALL}/ros2/cheri_setup.sh

if "${TEST}"
then
	echo "TEST SUCCEEDED"
else
    echo "Got test failures"
    false
fi
