#!/bin/bash
# Configure iptables firewall

#  Flush iptables
firewall_stop() {
	/usr/sbin/iptables -P INPUT ACCEPT
	/usr/sbin/iptables -P FORWARD ACCEPT
	/usr/sbin/iptables -P OUTPUT ACCEPT
	/usr/sbin/iptables -t nat -F
	/usr/sbin/iptables -t mangle -F
	/usr/sbin/iptables -F
	/usr/sbin/iptables -X
}

#  Execute requested action
case "$1" in
  start|restart)
    echo "Starting firewall"
    firewall_stop
    /usr/sbin/iptables-restore < /etc/iptables.rules
    ;;
  stop)
    echo "Stopping firewall"
    firewall_stop
    ;;
esac

