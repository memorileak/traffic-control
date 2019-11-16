#!/bin/bash

# device to apply
DEVICE=$1

# ip address list
CLIENT1_IP=10.0.2.4/32
CLIENT2_IP=10.0.2.6/32
CLIENT_SUBNET_IP=10.0.2.0/24

# setup bandwidth limitation values
CH1_LIM=16
CH2_LIM=2
CH3_LIM=1

# set up new virtual interface to create virtual egress qdisc
modprobe ifb numifbs=1
ip link set ifb0 up

# redirect the ingress qdisc to virtual egress qdisc
tc qdisc del dev $DEVICE ingress
tc qdisc add dev $DEVICE ingress handle ffff:0
tc filter add dev $DEVICE parent ffff:0 protocol ip prio 1 u32 match ip dst 0.0.0.0/0 action mirred egress redirect dev ifb0

# limit download speed
tc qdisc del dev $DEVICE root
tc qdisc add dev $DEVICE root handle 1:0 htb

tc class add dev $DEVICE parent 1:0 classid 1:1 htb rate "$CH1_LIM"Mbit ceil "$((CH1_LIM + 1))"Mbit
tc class add dev $DEVICE parent 1:0 classid 1:2 htb rate "$CH2_LIM"Mbit ceil "$((CH2_LIM + 1))"Mbit
tc class add dev $DEVICE parent 1:0 classid 1:3 htb rate "$CH3_LIM"Mbit ceil "$((CH3_LIM + 1))"Mbit

tc filter add dev $DEVICE parent 1:0 protocol ip prio 1 u32 match ip dst $CLIENT1_IP flowid 1:1
tc filter add dev $DEVICE parent 1:0 protocol ip prio 1 u32 match ip dst $CLIENT2_IP flowid 1:2
tc filter add dev $DEVICE parent 1:0 protocol ip prio 2 u32 match ip dst $CLIENT_SUBNET_IP flowid 1:3

# limit upload speed
tc qdisc del dev ifb0 root
tc qdisc add dev ifb0 root handle 1:0 htb

tc class add dev ifb0 parent 1:0 classid 1:1 htb rate "$CH1_LIM"Mbit ceil "$((CH1_LIM + 1))"Mbit
tc class add dev ifb0 parent 1:0 classid 1:2 htb rate "$CH2_LIM"Mbit ceil "$((CH2_LIM + 1))"Mbit
tc class add dev ifb0 parent 1:0 classid 1:3 htb rate "$CH3_LIM"Mbit ceil "$((CH3_LIM + 1))"Mbit

tc filter add dev ifb0 parent 1:0 protocol ip prio 1 u32 match ip src $CLIENT1_IP flowid 1:1
tc filter add dev ifb0 parent 1:0 protocol ip prio 1 u32 match ip src $CLIENT2_IP flowid 1:2
tc filter add dev ifb0 parent 1:0 protocol ip prio 2 u32 match ip src $CLIENT_SUBNET_IP flowid 1:3
