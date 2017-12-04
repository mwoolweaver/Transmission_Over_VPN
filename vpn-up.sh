#! /bin/bash

# Must be created in /etc/iproute2/rt_tables
VPNTABLE=transmission

# Must match the mark value saved in iptables.rules:
#  (1) in the rules that mark packets by GUID
#        -A OUTPUT -m owner --uid-owner $USERNAME -j MARK --set-xmark $MARK
#  (2) in the rule that rejects all marked packets by default (see below)
MARK=0x2

# Gateway of VPN interface
GATEWAYIP=10.8.0.2

if [[ `ip rule list | grep -c $MARK` == 0 ]]; then
	ip rule add from all fwmark $MARK lookup $VPNTABLE
fi

ip route replace default via $GATEWAYIP table $VPNTABLE

# when default route disappears, will fall back to this null route:
# NOTE: this is crucial, because iptables rejection rule is removed below,
# so when openvpn-client service is stopped, iptables no longer protects.
ip route append blackhole default table $VPNTABLE

ip route flush cache

# Remove the rejection rule
if iptables -C OUTPUT -m mark --mark $MARK  -j REJECT
then
   iptables -D OUTPUT -m mark --mark $MARK -j REJECT
fi