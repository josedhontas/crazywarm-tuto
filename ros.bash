#!/bin/bash

# Instalando o ROS

sudo apt update && sudo apt upgrade -y

sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc)  main" > /etc/apt/sources.list.d/ros-latest.list'

curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc |  sudo apt-key add -

sudo apt update && sudo apt install ros-melodic-desktop-full ros-melodic-turtlebot3 ros-melodic-turtlebot3-simulations ros-melodic-gmapping python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential x11-apps gnome-terminal -y

echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc && source ~/.bashrc

#Instalando crazywarm

sudo apt install python3

sudo apt install python3-colcon-common-extensions

sudo apt install libboost-program-options-dev libusb-1.0-0-dev
pip3 install rowan

pip3 install cflib transforms3d
sudo apt-get install ros-*DISTRO*-tf-transformations

mkdir -p ros2_ws/src
cd ros2_ws/src
git clone https://github.com/IMRCLab/crazyswarm2 --recursive
git clone --branch ros2 --recursive https://github.com/IMRCLab/motion_capture_tracking.git


cd ../
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release