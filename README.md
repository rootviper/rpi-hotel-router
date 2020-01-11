# rpi-hotel-router

This project uses Ansible to create a hotel router on a Raspberry Pi

## Getting Started

```
git clone https://github.com/rootviper/rpi-hotel-router.git /path/to/install
```

## Tested configuration

This configuration is not necessary to make these Ansible scripts work properly, but it may be helpful.  Most of this project was written using a Raspberry Pi 3.

* Raspberry Pi 4
* ArgonOne Raspberry Pi 4 case with cooling fan
* ArgonOne 18W/3.5A power supply
* Panda Wireless PAU05 300Mbps Wireless N USB adapter
* Samsung 32GB EVO Plus Class 10 Micro SDHC (MB-MC32DA/AM)

## Overview

When fully configured, client devices communicate over an encrypted connection to a wireless hotspot running on wlan0, while on wlan1, the OpenVPN client establishes a connection to an OpenVPN server.  See the companion project [rootviper/digitalocean-openvpn-server](https://github.com/rootviper/digitalocean-openvpn-server) for a self-hosted OpenVPN server.  All traffic from client devices connected to the hotel router is routed through the Raspberry Pi and the OpenVPN tunnel.

Because some hotels require interaction with a captive portal prior to allowing Internet access, the wired Ethernet port is used for VNC connections to the Raspberry Pi.  To provide security for VNC, I recommend tunneling the connection over an SSH tunnel as explained in a subsequent section.

## Installation steps

#### tl;dr
* Place Ansible public key in Raspberry Pi authorized_keys
* Start Raspberry Pi SSH server
* Customize Ansible variables
* Run Ansible playbook
* Copy OpenVPN configuration to Raspberry Pi

These steps assume a minimal understanding of networking, so I skip steps where you will supply an IP address for the Raspberry Pi.

Install Raspbian Buster Lite, the ISO and instructions for which are located on the [Raspberry Pi website](https://www.raspberrypi.org/downloads/raspbian/).

Authenticate to the Raspberry Pi (username: pi, password: raspberry) and start/enable the SSH server.

```
sudo systemctl enable ssh.service --now
```

If you do not already have a public/private keypair to use for this purpose, create them on the machine to be used as the Ansible host, not the Raspberry Pi.  Then, only the public key is copied over to the Raspberry Pi.  In this example, I use the ssh-keygen command and create a private key called ansible_rsa and a public key called ansible_rsa.pub.  On the Ansible host:

```
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/someuser/.ssh/id_rsa): /home/someuser/.ssh/ansible_rsa
Enter passphrase (empty for no passphrase): (Enter a good passphrase)
Enter same passphrase again: (Repeat the passphrase)
Your identification has been saved in /home/someuser/.ssh/ansible_rsa.
Your public key has been saved in /home/someuser/.ssh/ansible_rsa.pub.
```

SCP the newly minted public key to the Raspberry Pi.  On the Ansible host:

```
scp /home/someuser/.ssh/ansible_rsa.pub pi@<rpi-ip-address>:/home/pi
```

Write the contents of the public SSH key into /home/pi/.ssh/authorized_keys.  The /home/pi/.ssh directory will not exist by default and will need to be created.  File modes and ownership are important.  On the Raspberry Pi:

```
mkdir -m 700 /home/pi/.ssh
cat /home/pi/ansible_rsa.pub >> /home/pi/.ssh/authorized_keys
chmod 600 /home/pi/.ssh/authorized_keys
chown -R pi:pi /home/pi/.ssh
```

Change to the installation directory

```
cd /path/to/install
```

Copy the example hosts file and modify it, minimally replacing the following values:

__ansible_ssh_private_key_file__: Fully-qualified path to the private key file to be used by Ansible, e.g. /home/someuser/.ssh/ansible_rsa

__hotspot_ssid__: SSID presented to client devices by the hotspot

__hotspot_psk__: Preshared key for the hotspot

__hotspot_wlan0_macaddr__: MAC address of the wireless interface to be used as the Wi-Fi hotspot

__hotspot_wlan1_macaddr__: MAC address of the wireless interface to be used to connect to the OpenVPN server

```
cp hosts.yml.example hosts.yml
vim hosts.yml
```

Run the setup.yml playbook, optionally using the raspberry_pi_setup.sh script.

```
$ ./raspberry_pi_setup.sh
BECOME password: (password for pi user)
Create a VNC password (6-8 characters): xxxxxxxx
Enter the OpenVPN server IP address: xxx.xxx.xxx.xxx
Enter the OpenVPN server UDP port: xxxx (1194 is the default port)
```

Additionally, the OpenVPN client expects a client configuration to reside in /etc/openvpn/client/client.conf.  Again, see the companion project [rootviper/digitalocean-openvpn-server](https://github.com/rootviper/digitalocean-openvpn-server) for a method for creating an OpenVPN server.  This project will also generate your OpenVPN client configuration for you.

Normally, I would restart services in lieu of a reboot; however, in this case, you should be certain that the configuration can survive a reboot.  Restart the Raspberry Pi.

If everything is configured correctly, the configured SSID will be available to clients, and the tun0 interface will exist on the Raspberry Pi.  Client devices should have Internet access and be able to verify via IP geolocation services that they are transiting the OpenVPN server.  If your configuration can use the same OpenVPN client configuration in every instance, one could easily fold that into an Ansible task.

##  Connect to the Raspberry Pi with VNC over SSH

Choose an arbitrary high port and use it as the port through which to forward the VNC connection (-L).  In this case, I use port 5901 to match the VNC service port on the Raspberry Pi.  Create a control master socket (-S) through which to manage the port forward.

```
ssh -fNT -M -S ~/rpi.sock -L 5901:127.0.0.1:5901 -l pi <rpi-ip-address>
```

The -L option should be read as <em>-L [bind_address:]port:host:hostport</em>.  In this case, the bind_address is implied to be 127.0.0.1 on the client.  Thus, SSH will forward connections from 127.0.0.1 (client side) on port 5901 to 127.0.0.1 (Raspberry Pi side) on port 5901.  If you chose 9191 as the arbitrary high port, the -L option would be 9191:127.0.0.1:5901.  In that case, you would connect to port 9191 on the client, and your VNC connection would be tunneled over SSH to port 5901 on the Raspberry Pi.

Choose a VNC application through which to connect to the Raspberry Pi over the SSH tunnel.  If using Remmina on Linux, choose "127.0.0.1:5901" as the server and "pi" as the user name.  The application will connect locally to port 5901, where SSH is listening.

To check if the control master is running, run the following command.  Often <em>username@hostname</em> is used in place of the x, but that is not necessary.  Any string will do.

```
ssh -S ~/rpi.sock -O check x
```

To close the control master and the port forward, run the following command.

```
ssh -S ~/rpi.sock -O exit x
```

## Running the tests

No tests have yet been written for this project

## License

This project is licensed under the GNU General Public License, Version 3 - see the [LICENSE.md](LICENSE.md) file for details
