# EchoMAV MAVLink-Router Installation

## What is Mavlink-router?

[MAVLink Router](https://github.com/mavlink-router/mavlink-router) is an open-source application to distribute MAVLink messages between multiple endpoints (connections). It distributes packets to a single port or multiple endpoints depending on the target address. Connections can be made via UART, UDP or TCP (see the endpoints chapter for details). For the EchoPilot AI, the most common application is to to accept data from the serial port (e.g. on `/dev/ttyTHS1`) and forward it to a ground control system over the network using either UDP or TCP (supporting both client and server configurations).

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
then install:
```
make -C ~/tmp/mavlink-router install
```
*Optional*, if you wish to set up a static IP address on the system, derives from the last two octects of the eth0 interface's MAC address, run:
```
make -C ~/tmp/mavlink-router static
```
The default confguration will have the FMU data arriving on `/dev/ttyTHS1` at 500,000 bps and sending to the UDP endpoint at `10.223.1.10:14550`. To configure your system with different settings, edit the self-documeted configuration file `/etc/mavlink-router/main.conf`, for example using `nano` as shown below:
```
sudo nano /etc/mavlink-router/main.conf
```
Reboot the system to ensure user permissions are applied. The mavlink-router service will start automatically using the settings in the /etc/mavlink-router/main.conf` file.  

*Optional*, if you wish to set both install mavlink-router AND set up a static IP address, you can use the default make target
```
make -C ~/tmp/mavlink-router
```

## Configuring, Starting and Stopping

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

This most common and simplest configuration method is for mavlink-router to be a UDP client. In the `main.conf` file, enter the IP address of the computer on your network running the GCS software (QGroundControl or MissionPlanner recommended). Using the default settings, set your computer's IP address to 10.223.1.10 with a netmask of 255.255.0.0.  
```
[UdpEndpoint alpha]
Mode = Normal
Address = 10.223.1.10  # Change this to your GCS's IP Address
Port = 14550
```
Both QGroundControl and MissionPlanner will accept UDP connections on port 14550 by default (no specific configuration required).  If you have any firewalls in your system, you will need to allow access to port 14550.

## Static IP Configuration Utility

The included `static-network.sh` utility can be used standalone as a helper script to set up static ip addresses. When using `make static` above, this script is called with the following arguments: `./static-network.sh -i eth0 -a auto`.  

The general script usage is:  
```
./static-network.sh -i interface_name -a ip_addres|auto -g gateway_address(optional)
```
Passing `auto` to the `-a` argument uses the specified interface's MAC address as a way to form a unique static IP address. The last two octets of the MAC address are converted to decimal and used for the last two octets of the IP address. For example, if the MAC address is 34:73:5a:e8:57:3f, the last two octets 57:3f will convert (hexadecimal to decimal) to 87.63 and the static IP will be set to 10.223.87.63. When using `-a auto`, the netmask `/16` (255.255.0.0) is used.

You can also specify a specific static IP address as well as a gateway address. For example:
```
./static-network.sh -i eth0 -a 192.168.1.100/24 -g 192.168.1.1
```
The command above would set `eth0`'s address to `192.168.1.100` with a `255.255.255.0` netmask and a gateway of `192.168.1.1`. Normally the Ethernet interface (`-i` argumment) on Jetson devices is called `eth0`, however if you wish to use this script to configure a different interface, you can see the names of you system's interfaces with the commannd below and the pass the appropriate interface name to the `-i` argument:
```
ip link show
```
### Backdoor VLAN

The `static-network.sh` also creates a backdoor VLAN at `192.168.154.0/24` which can be used to access the device if you no longer know the static IP address or do not have serial/usb console access. To use this backdoor, set up a host computer to an IP in the same netmask, e.g. `192.168.154.10` with a netmask of `255.255.255.0` and then you can access the device at `192.168.154.0`, for example `ssh echopilot@192.168.154.0`.  

This backdoor/configuration IP address is designed to be used during configuration only and should never be used when more than one EchoPilot AI is on the network. 

