# Makefile for installation of mavlink-router on EchoPilot AI hardware
.DEFAULT_GOAL := default
SHELL := /bin/bash
SUDO := $(shell test $${EUID} -ne 0 && echo "sudo")
.EXPORT_ALL_VARIABLES:
SYSCFG = /etc/mavlink-router
CONFIG ?= /var/local
LIBSYSTEMD=/lib/systemd/system
SERVICES=mavlink-router.service
DRY_RUN=false

.PHONY = enable install see uninstall static default

default: 
	@$(MAKE) --no-print-directory install 
	@$(MAKE) --no-print-directory static

disable:
	@( for c in stop disable ; do $(SUDO) systemctl $${c} $(SERVICES) ; done ; true )

enable:
	@( for c in stop disable ; do $(SUDO) systemctl $${c} $(SERVICES) ; done ; true )
	@( for s in $(SERVICES) ; do $(SUDO) install -Dm644 $${s%.*}.service $(LIBSYSTEMD)/$${s%.*}.service ; done ; true )
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi
	@( for s in $(SERVICES) ; do $(SUDO) systemctl enable $${s%.*} ; done ; true )
	@echo ""
	@echo "Service is installed. To run now use sudo systemctl start mavlink-router"
	@echo "Inspect output with sudo journalctl -fu mavlink-router"
	@echo ""

static:
# set up static ip address on eth0
	@$(SUDO) ./static-network.sh -i eth0 -a auto

install: 	
# install helper apps
	@$(SUDO) apt update
	@$(SUDO) apt install nano
	@$(SUDO) apt install nload
	@$(SUDO) apt install htop
	@$(SUDO) apt install picocom
# install mavlink-router
	@rm -rf ~/tmp/mavlink-router-source
	@git clone https://github.com/mavlink-router/mavlink-router.git ~/tmp/mavlink-router-source && cd ~/tmp/mavlink-router-source && git submodule update --init --recursive
	@$(SUDO) apt -y install git ninja-build pkg-config gcc g++ systemd
	@$(SUDO) apt -y install python3-pip
	@$(SUDO) pip3 install meson smbus
	@cd ~/tmp/mavlink-router-source && meson setup build . && $(SUDO) ninja -C build install

# install the config file
	@$(SUDO) mkdir -p $(SYSCFG)
	@$(SUDO) cp main.conf $(SYSCFG)/.

# install mavlink-router service
	@for s in $(SERVICES) ; do $(SUDO) install -Dm644 $${s%.*}.service $(LIBSYSTEMD)/$${s%.*}.service ; done
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi
	@for s in $(SERVICES) ; do $(SUDO) systemctl enable $${s%.*} ; done

# set up the system permissions, stop/disable nvgetty etc
	@$(SUDO) systemctl stop nvgetty
	@$(SUDO) systemctl disable nvgetty
	@$(SUDO) usermod -aG dialout $${USER}
	@$(SUDO) usermod -aG tty $${USER}
	@echo ""
	@echo "The installation is complete. To configure mavlink-router, please edit $(SYSCFG)/main.conf, e.g. sudo nano $(SYSCFG)/main.conf"
	@echo ""
	@echo "After a change in $(SYSCFG)/main.conf restart mavlink-router using sudo systemctl restart mavlink-router or reboot."
	@echo ""
	@echo "Please reboot to change required user permissions and complete the installation..."
	@echo ""
	@echo ""

see:
	$(SUDO) cat $(SYSCFG)/main.conf

serial:
	-@$(SUDO) python3 serial_number.py 0 || true
	-@$(SUDO) python3 serial_number.py 1 || true

uninstall:
	@$(MAKE) --no-print-directory disable
	@( for s in $(SERVICES) ; do $(SUDO) rm $(LIBSYSTEMD)/$${s%.*}.service ; done ; true )
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi


