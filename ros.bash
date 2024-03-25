#!/bin/bash

locale  # check for UTF-8

sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

locale  # verify settings

sudo apt install software-properties-common
sudo add-apt-repository universe

sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update

sudo apt upgrade

sudo apt install ros-humble-desktop

sudo apt install ros-humble-ros-base

sudo apt install ros-dev-tools


echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && source ~/.bashrc

#agora o crazyswarm2

sudo apt install libboost-program-options-dev libusb-1.0-0-dev
pip3 install rowan


pip3 install cflib transforms3d
sudo apt-get install ros-humble-tf-transformations


mkdir -p ros2_ws/src
cd ros2_ws/src
git clone https://github.com/IMRCLab/crazyswarm2 --recursive
git clone --branch ros2 --recursive https://github.com/IMRCLab/motion_capture_tracking.git


cd ../
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
