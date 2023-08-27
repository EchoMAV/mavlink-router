#!/bin/bash
# EchoMAV, LLC
# This script sets up a static network on the EchoPilot AI using NetworkManager (nmcli)
# usage: static-network.sh -i {interface} -a {ip_addres|auto} -g {gateway(optional)}
# If auto is used, the static IP address will be set to 10.223.x.y where x and y are the last two octects of the network interface mac address

IP_PREFIX="10.223"
VLAN_ADDR="192.168.154.0/24"
sigterm_handler() { 
  echo "Shutdown signal received."
  exit 1
}

## Setup signal trap
trap 'trap " " SIGINT SIGTERM SIGHUP; kill 0; wait; sigterm_handler' SIGINT SIGTERM SIGHUP

SUDO=$(test ${EUID} -ne 0 && which sudo)

function print_help { echo "Usage: ./static-network.sh -i interface_name -a ip_addres|auto -g gateway_address(optional)" >&2 ; }

# process args
while getopts :i:a:g:h: flag;
do
    case "${flag}" in
        h)  print_help
            exit 1
            ;;
        i) IFACE=${OPTARG};;
        a) IP_INPUT=${OPTARG};;
        g) GATEWAY=${OPTARG};;
        *) print_help
           exit 1
           ;;
    esac
done

# check mandatory arguments

if [ -z $IP_INPUT ]; then
        echo 'Missing mandatory -a argument' >&2
        print_help
        exit 1
fi

if [ -z $IFACE ]; then
        echo 'Missing mandatory -i argument' >&2
        print_help
        exit 1
fi

# install vlan
$SUDO apt -y install vlan

exist=$(modinfo 8021q 2>/dev/null)
if [ -z "$exist" ] ; then     # if not present, install
        $SUDO modprobe --first-time 8021q
fi

if [ $IP_INPUT = "auto" ]; then    
    ifconfig ${IFACE} &> /dev/null
    if [ $? -ne 0 ] 
    then 
        echo "ERROR: Failed to get information for interface ${IFACE}, does it really exist?"
        echo ""
        echo "Here is output of ip link show:"
        ip link show
        exit 1 
    fi

    echo "Determining the auto static IP address for interface ${IFACE}...";
    # Get the mac address
    MAC_ADDRESS=$(ifconfig ${IFACE} | awk '/ether/ {print $2}')

    OCT1DEC=$((0x`ifconfig ${IFACE} | awk '/ether/ {print $2}' | awk '{split($0,a,"[:]"); print a[5]}'`))
    OCT2DEC=$((0x`ifconfig ${IFACE} | awk '/ether/ {print $2}' | awk '{split($0,a,"[:]"); print a[6]}'`))
    
    echo "MAC address for ${IFACE} is $MAC_ADDRESS";

    if ! [[ $OCT1DEC =~ ^[0-9]{1,3} && $OCT2DEC =~ ^[0-9]{1,3} ]] ; then
        echo "Error: Failure calculating the target IP address" >&2; exit 1
    fi
    
    HOST="$IP_PREFIX.$OCT1DEC.$OCT2DEC";
    NETMASK=16;
    echo "Auto-calculated IP is $HOST/$NETMASK";
    
else
    # validate ip address
    if [[ ! $IP_INPUT =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,3}$ ]]; then
        echo "ERROR! Invalid IP Address, should be x.x.x.x/y where y is the subnet mask" >&2; exit 1
    fi
    HOST=$(echo ${IP_INPUT} | cut -d/ -f 1);
    NETMASK=$(echo ${IP_INPUT} | cut -d/ -f 2);

    echo "Configuring ${IFACE} with the provided static IP address ${HOST}/${NETMASK}";
   
fi

# check if there is a connection called Wired connection 1", if so take it down and delete\

state=$(nmcli -f GENERAL.STATE c show "Wired connection 1" 2>/dev/null)
if [[ "$state" == *activated* ]] ; then         # take the interface down
        $SUDO nmcli c down "Wired connection 1"
fi
exist=$(nmcli c show "Wired connection 1" 2>/dev/null)
if [ ! -z "$exist" ] ; then     # delete the interface if it exists
        echo "Removing Wired connection 1..."
        $SUDO nmcli c delete "Wired connection 1"
fi

# check if there is already an interface called static-$IFACE, if so take down and delete
state=$(nmcli -f GENERAL.STATE c show "static-$IFACE" 2>/dev/null)
if [[ "$state" == *activated* ]] ; then         # take the interface down
        $SUDO nmcli c down "static-$IFACE"
fi
exist=$(nmcli c show "static-$IFACE" 2>/dev/null)
if [ ! -z "$exist" ] ; then     # delete the interface if it exists
        $SUDO nmcli c delete "static-$IFACE"
fi

echo "Creating new connection static-$IFACE..."
$SUDO nmcli c add con-name "static-$IFACE" ifname $IFACE type ethernet ip4 $HOST/$NETMASK

# if gateway was provided, add that info to the connection
if [[ "$GATEWAY" == *.* ]]
then
    echo "Defining gateway ${GATEWAY}...";
    $SUDO nmcli c mod "static-$IFACE" ifname $IFACE gw4 $GATEWAY 
fi
$SUDO nmcli c up "static-$IFACE"

# check if there is already an interface called vlan-config, if so take down and delete
state=$(nmcli -f GENERAL.STATE c show "vlan-config" 2>/dev/null)
if [[ "$state" == *activated* ]] ; then         # take the interface down
        $SUDO nmcli c down "vlan-config"
fi
exist=$(nmcli c show "vlan-config" 2>/dev/null)
if [ ! -z "$exist" ] ; then     # delete the interface if it exists
        $SUDO nmcli c delete "vlan-config"
fi

$SUDO nmcli c add type vlan con-name vlan-config ifname vlan10 dev $IFACE id 10 ip4 $VLAN_ADDR
$SUDO nmcli c up vlan-config

echo "";
echo "Static Ethernet Configuration Successful! Interface static-$IFACE is set to $HOST/$NETMASK"
