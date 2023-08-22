# EchoMAV mavlink-router Installation

## What is Mavlink-router

[MAVLink Router](https://github.com/mavlink-router/mavlink-router) is an open-source application to distribute MAVLink messages between multiple endpoints (connections). It distributes packets to a single port or multiple endpoints depending on the target address. Connections can be made via UART, UDP or TCP (see the endpoints chapter for details). For the EchoPilot AI, the most common application is to to accept data from the serial port (e.g. on `/dev/ttyTHS1`) and forward it to a ground control system over the network using either UDP or TCP.

This repository provides a makefile to easily install mavlink-router on a Jetson running on the EchoPilot AI hardware. It also sets up a service `mavlink-router` to start at boot.

## Prerequisites

You must have an internet connection from the Jetson module to complete this install. Please refer to these instructions: https://echomav.github.io/docs/Rev1/echopilot_ai/#configure-the-network

Gain console access to the Jetson module installed on the EchoPilot AI. You can do this with either a USB cable or via ssh. See https://echomav.github.io/docs/Rev1/echopilot_ai/#accessing-the-jetson-via-the-console for additional information.

To verify you have internet connectivity, use 
```ping 8.8.8.8```

## Dependencies

All software dependencies will be installed automatically by during `make install` assuming you have an internet connection.  

## Installation

To perform an initial install, first gain console and internet access per links above, then clone the repository.
Issue the following commands:

```
git clone https://github.com/echomav/mavlink-router.git ~/tmp/mavlink-router
```
then install :
```
make -C ~/tmp/mavlink-router install
```
The system may ask for the password at this point.

To configure your system, edit the self-documeted configuration file `/etc/mavlink-router/main.conf`
```
sudo nano /etc/mavlink-router/main.conf
```
Reboot the system to ensure user permissions are applied. The mavlink-router service will start automatically using the settings in the /etc/mavlink-router/main.conf` file.

## Configuring, Srarting and Stoping

Mavlink-router will be installed as a system service, and will start automatically (see `/lib/systemd/system/mavlink-router.service`) at boot using the configuration defined in `/etc/mavlink-router/main.conf`.  

To edit the configuration file
```
sudo nano /etc/mavlink-router/main.conf
```
To stop the service:  
```
sudo systemctl stop mavlink-router
```
To start the service:  
```
sudo systemctl start mavlink-router
```
To restart the service:  
```
sudo systemctl restart mavlink-router
```
## Receiving Telemetry Data with a GCS

This most common and simplest configuration method is for mavlink-router to be a UDP client. In the `main.conf` file, enter the IP address of the computer on your network running the GCS software (QGroundControl or MissionPlanner recommended). 
```
[UdpEndpoint alpha]
Mode = Normal
Address = 192.168.?.?  # Change this to your GCS's IP Address
Port = 14550
```
Both QGroundControl and MissionPlanner will accept UDP connections on port 14550 by default (no specific configuration required).
