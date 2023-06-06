#!/bin/sh

if command -v "iptables-save"; then
    iptables-save
else
    echo "*FILTER"
    iptables -t filter -L -n
    echo""

    echo "*NAT"
    iptables -t nat -L -n
    echo ""

    echo "*MANGLE"
    iptables -t mangle -L -n
    echo ""

    echo "*RAW"
    iptables -t raw -L -n
    echo ""

    echo "*SECURITY"
    iptables -t security -L -n
    echo ""
fi
