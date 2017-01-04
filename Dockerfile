FROM 32bit/ubuntu:16.04
LABEL authors="jimmyli@cim.mcgill.ca,anqixu@cim.mcgill.ca"

# Install ROS
RUN sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
RUN apt-get update && apt-get install -y --no-install-recommends ros-kinetic-ros-base
RUN apt-get install -y build-essential libbullet-dev
RUN sudo rosdep init && rosdep update

# Setup ROS
RUN mkdir -p /root/catkin_ws/src
WORKDIR /root/catkin_ws/src
RUN ["/bin/bash", "-c", "source /opt/ros/kinetic/setup.bash; catkin_init_workspace"]
WORKDIR /root/catkin_ws
RUN ["/bin/bash", "-c", "source /opt/ros/kinetic/setup.bash; catkin_make"]
RUN echo "source /root/catkin_ws/devel/setup.bash" >> /root/.bashrc

# Pull RoboDevel, OCULite, aquacore, aquahw
RUN sudo apt-get install -y mercurial
WORKDIR /root/
# TODO: figure out a secure and semi-public way to hg clone (e.g. via ssh-keygen)
# ..... for now, we require the following to be pulled manually into pwd:
#       RoboDevel (ssh://${CIM_USERNAME}@${CIM_SERVER}://home/discovery/mrl/hgrepo/RoboDevel)
#       OCULite   (ssh://${CIM_USERNAME}@${CIM_SERVER}://home/discovery/mrl/hgrepo/OCULite)
#       aquacore  (ssh://${CIM_USERNAME}@${CIM_SERVER}://home/discovery/mrl/hgrepo/aqua/ros/aquacore)
#       aquahw    (ssh://${CIM_USERNAME}@${CIM_SERVER}://home/discovery/mrl/hgrepo/aqua/ros/aquahw)
ADD ./RoboDevel /root/RoboDevel
ADD ./OCULite /root/OCULite
ADD ./aquahw /root/catkin_ws/src/aquahw
ADD ./aquacore /root/catkin_ws/src/aquacore

# Compile RoboDevel
RUN apt-get install -y libfltk1.3-dev flex bison libjpeg-dev
WORKDIR /root/RoboDevel
RUN ["/bin/bash", "-c", "source aqua-environment-linux-aqua5; make rhex"]
RUN echo "export CURRDIR=\$(pwd) && cd /root/RoboDevel && source aqua-environment-linux-aqua5 && cd \$CURRDIR" >> /root/.bashrc

# Compile OCULite
WORKDIR /root/OCULite
RUN make

# Compile aquacore and aquahw
WORKDIR /root/catkin_ws
RUN ["/bin/bash", "-c", "source /root/catkin_ws/devel/setup.bash; catkin_make"]

# Set default command to run aquahw
CMD ["/bin/bash", "-c", "source /root/catkin_ws/devel/setup.bash; rosrun aquahw aquahw"]
