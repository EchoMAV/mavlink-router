# EchoMAV mavlink-router Installation

## What is Mavlink-router

[MAVLink Router](https://github.com/mavlink-router/mavlink-router) is an open-source application to distribute MAVLink messages between multiple endpoints (connections). It distributes packets to a single port or multiple endpoints depending on the target address. Connections can be made via UART, UDP or TCP (see the endpoints chapter for details). For the EchoPilot AI, the most common application is to to accept data from the serial port (e.g. on `/dev/ttyTHS1`) and forward it to a ground control system over the network using either UDP or TCP.

This repository provides a makefile to easily install mavlink-router on a Jetson running on the EchoPilot AI hardware.

## Prerequisites

You must have an internet connection from the Jetson module to complete this install. Please refer to these instructions: https://echomav.github.io/docs/Rev1/echopilot_ai/#configure-the-network

Gain console access to the Jetson module installed on the EchoPilot AI. You can do this with either a USB cable or via ssh. See https://echomav.github.io/docs/Rev1/echopilot_ai/#accessing-the-jetson-via-the-console for additional information.

To verify you have internet connectivity, use 
```ping 8.8.8.8```

## Dependencies

All software dependencies will be installed automatically by during `make install` assuming you have an internet connection.  

## Installation

To perform an initial install, clone the repository.
Issue the following commands:

```
git clone https://github.com/echomav/mavlink-router.git ~/tmp/mavlink-router
```

then continue:
```
make -C ~/tmp/mavlink-router install
```
The system may ask for the password.  

To configure your system, edit the self-documeted configuration file `/etc/mavlink-router/main.conf`
```
sudo nano /etc/mavlink-router/main.conf
```

## Running

Mavlink-router will be installed as a system service, and will start automatically (see `/lib/systemd/system/mavlink-router.service`) at boot using the configuration defined in `/etc/mavlink-router/main.conf`.  

To edit the configuration file
```
sudo nano /etc/mavlink-router/main.conf
``
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
