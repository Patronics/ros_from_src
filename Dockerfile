ARG IMAGE=ubuntu:22.04
FROM ${IMAGE}
ARG IMAGE
RUN echo ${IMAGE}

ENV DEBIAN_FRONTEND="noninteractive"

# be able to source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update
RUN apt-get install -y apt-utils

# apt installs
RUN apt-get install -y build-essential
RUN apt-get install -y bzip2 libbz2-dev
RUN apt-get install -y cmake
RUN apt-get install -y git
RUN apt-get install -y libboost-dev
RUN apt-get install -y libboost-filesystem-dev
RUN apt-get install -y libboost-program-options-dev
RUN apt-get install -y libboost-regex-dev
RUN apt-get install -y libboost-thread-dev
RUN apt-get install -y libgpgme-dev
RUN apt-get install -y libgtest-dev
RUN apt-get install -y liblog4cxx-dev
RUN apt-get install -y liblz4-dev lz4
RUN apt-get install -y libpoco-dev
RUN apt-get install -y libtinyxml2-dev
RUN apt-get install -y mawk coreutils
RUN apt-get install -y python-is-python3
RUN apt-get install -y python3
RUN apt-get install -y python3-dev
RUN apt-get install -y python3-empy
RUN apt-get install -y python3-setuptools
RUN apt-get install -y python3-yaml

ENV SRC=/src
RUN mkdir $SRC -p
ENV BUILD=/build
RUN mkdir $BUILD -p
ENV WS=/catkin_ws/src
RUN mkdir $WS -p

ENV DEST=/opt/ros/noetic

# packages that need to be cmake installed, and are ros packages in a catkin workspace
WORKDIR $WS
RUN git clone https://github.com/ros/catkin
RUN git clone https://github.com/ros/console_bridge
RUN git clone https://github.com/ros/cmake_modules
RUN git clone https://github.com/ros-o/class_loader
RUN git clone https://github.com/ros/rospack
RUN git clone https://github.com/ros/genmsg
RUN git clone https://github.com/ros/ros

# pure python
WORKDIR $SRC
RUN git clone https://github.com/ros-infrastructure/catkin_pkg
RUN git clone https://github.com/osrf/osrf_pycommon
RUN git clone https://github.com/catkin/catkin_tools

# cmake installs
RUN git clone https://github.com/ros-o/ros_environment

# python installs

RUN python --version | awk  '{print $2}' | cut -d'.' -f1
RUN python --version | awk  '{print $2}' | cut -d'.' -f2
# TODO(lucasw) these aren't working
# RUN export PYTHON_MAJOR_VERSION=`python --version | awk  '{print $2}' | cut -d'.' -f1`
# RUN export PYTHON_MINOR_VERSION=`python --version | awk  '{print $2}' | cut -d'.' -f2`
# RUN PYTHON_MINOR_VERSION=`python --version | awk  '{print $2}' | cut -d'.' -f2`
ARG PYTHON_MAJOR_VERSION=3
ARG PYTHON_MINOR_VERSION=10
ENV OPT_PYTHONPATH=$DEST/lib/python$PYTHON_MAJOR_VERSION.$PYTHON_MINOR_VERSION/site-packages/
RUN echo $PYTHONPATH
ENV PYTHONPATH=$OPT_PYTHONPATH
RUN echo $PYTHONPATH

# catkin_pkg
WORKDIR $SRC/catkin_pkg
RUN python3 setup.py install --prefix=$DEST --record install_manifest.txt --single-version-externally-managed
RUN ls -l $OPT_PYTHONPATH
RUN ls -l $OPT_PYTHONPATH/catkin_pkg
# RUN python -c "import sys; print(sys.path)"
RUN python -c "import catkin_pkg; print(catkin_pkg.__version__)"
RUN apt-get install -y python3-pyparsing
RUN python -c "from catkin_pkg.package import parse_package"

# osrf pycommon
WORKDIR $SRC/osrf_pycommon
# TODO(lucasw) install to $DEST
RUN python3 setup.py install --prefix=$DEST --record install_manifest.txt --single-version-externally-managed

# catkin tools
WORKDIR $SRC/catkin_tools
RUN python3 setup.py install --prefix=$DEST --record install_manifest.txt --single-version-externally-managed

# cmake install
RUN mkdir $BUILD/catkin -p
WORKDIR $BUILD/catkin
RUN cmake $WS/catkin -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF -DCATKIN_INSTALL_INTO_PREFIX_ROOT=true && make && make install
RUN python -c "import catkin; print(catkin)"
RUN ls -l $DEST/bin
ENV PATH=$PATH:$DEST/bin

# console_bridge
RUN mkdir $BUILD/console_bridge -p
WORKDIR $BUILD/console_bridge
# RUN cmake ../../console_bridge -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib && make && make install
RUN cmake $WS/console_bridge -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$DEST -DCMAKE_INSTALL_LIBDIR=lib
RUN make
RUN make install

# cmake_modules
WORKDIR $WS
RUN mkdir $BUILD/cmake_modules -p
RUN ls -l $DEST/lib
WORKDIR $BUILD/cmake_modules
RUN cmake $WS/cmake_modules -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF
RUN make
RUN make install

# class_loader
RUN mkdir $BUILD/class_loader -p
RUN export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:$DEST:$DEST/lib/cmake
RUN ls -l $DEST
RUN ls -l $DEST/share/cmake_modules/cmake/
WORKDIR $BUILD/class_loader
RUN cmake $WS/class_loader -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF -Dcmake_modules_DIR=$DEST/share/cmake_modules/cmake/
RUN make
RUN make install

# ros_environment
RUN mkdir $BUILD/ros_environment -p
RUN pwd
WORKDIR $BUILD/ros_environment
RUN cmake $SRC/ros_environment -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF
RUN make
RUN make install

# ros_pack
RUN mkdir $BUILD/rospack -p
WORKDIR $BUILD/rospack
RUN cmake $WS/rospack -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF -Dcmake_modules_DIR=$DEST/share/cmake_modules/cmake/
RUN make
RUN make install

# genmsg
RUN mkdir $BUILD/genmsg -p
WORKDIR $BUILD/genmsg
RUN cmake $WS/genmsg -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF
RUN make
RUN make install

# roslib
RUN mkdir $BUILD/roslib -p
WORKDIR $BUILD/roslib
RUN cmake $WS/ros/core/roslib -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF -Drospack_DIR=$DEST/share/rospack/cmake/
RUN make
RUN make install

# rosbuild
RUN mkdir $BUILD/rosbuild -p
WORKDIR $BUILD/rosbuild
RUN cmake $WS/ros/core/rosbuild -DCATKIN_BUILD_BINARY_PACKAGE=ON -DCMAKE_INSTALL_PREFIX=$DEST -DPYTHON_EXECUTABLE=/usr/bin/python -DSETUPTOOLS_DEB_LAYOUT=OFF # -Drospack_DIR=$DEST/share/rospack/cmake/
RUN make
RUN make install

RUN apt-get update
RUN apt-get install -y python3-dateutil
RUN apt-get install -y python3-docutils
RUN export PATH=$PATH:/usr/local/bin
RUN catkin --help

RUN apt-get install -y python3-defusedxml
RUN apt-get install -y python3-distro

# ros packages, regular catkin build only for these
WORKDIR $WS
RUN git clone https://github.com/ros/ros_comm
RUN git clone https://github.com/ros/roscpp_core
RUN git clone https://github.com/ros/ros_comm_msgs
RUN git clone https://github.com/ros/message_generation
RUN git clone https://github.com/ros/gencpp
RUN git clone https://github.com/jsk-ros-pkg/geneus
RUN git clone https://github.com/RethinkRobotics-opensource/gennodejs
RUN git clone https://github.com/ros/genlisp
RUN git clone https://github.com/ros/genpy
RUN git clone https://github.com/ros/std_msgs
RUN git clone https://github.com/ros/message_runtime
RUN git clone https://github.com/ros-o/pluginlib

# TODO(lucasw) this doesn't work in 20.04 because of log
# --build-args ROSCONSOLE=https://github.com/ros-o/rosconsole
ARG ROSCONSOLE=https://github.com/ros-o/rosconsole
# ENV ROSCONSOLE=$ROSCONSOLE
RUN echo $ROSCONSOLE
RUN git clone $ROSCONSOLE

# runtime dependencies
# rosbuild
WORKDIR $SRC
RUN git clone https://github.com/ros/rospkg
WORKDIR $SRC/rospkg
RUN python3 setup.py install --prefix=$DEST --record install_manifest.txt --single-version-externally-managed

WORKDIR $SRC
RUN git clone https://github.com/ros-infrastructure/rosdistro
WORKDIR $SRC/rosdistro
RUN python3 setup.py install --prefix=$DEST --record install_manifest.txt --single-version-externally-managed

WORKDIR $SRC
# can be sudo in docker, but otherwise want git clone https://github.com/lucasw/rosdep --branch disable_root_etc_ros
RUN git clone https://github.com/ros-infrastructure/rosdep
WORKDIR $SRC/rosdep
RUN python3 setup.py install --prefix=$DEST --record install_manifest.txt --single-version-externally-managed
RUN rosdep init
# ERROR: unable to process source [https://raw.githubusercontent.com/ros/rosdistro/master/rosdep/base.yaml]:
RUN rosdep update || true

# TODO(lucasw) already have a copy of this but needs to be in the workspace
# RUN find / | grep setup.bash
# RUN find / | grep catkin-config.cmake
WORKDIR $WS/..
RUN source $DEST/setup.bash
RUN catkin init
RUN source $DEST/setup.bash && catkin config
# rospack list won't work by itself
RUN source $DEST/setup.bash && rospack list

# regular catkin build
# RUN rosdep install --from-paths src --ignore-src -r -s  # do a dry-run first
# RUN rosdep install --from-paths src --ignore-src -r -y
ENV CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:$DEST:$DEST/lib/cmake
RUN echo $CMAKE_PREFIX_PATH
# TODO(lucasw) put this in WS to begin with
RUN echo $ROS_PACKAGE_PATH
RUN catkin build
# rospack list won't work by itself
RUN source devel/setup.bash && rospack list

RUN apt install python3-netifaces

WORKDIR $WS/..
# TODO(lucasw) run tests
