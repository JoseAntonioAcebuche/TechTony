# Cisco DHCP Configuration Guide (Layer 3 Switch and Router)

## DHCP Configuration

The DHCP server configuration on a Cisco Layer 3 Switch and a Cisco
Router is almost identical because both run Cisco IOS.

### Common DHCP Configuration

``` text
ip dhcp excluded-address 192.168.10.1 192.168.10.20

ip dhcp pool VLAN10_POOL
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
 dns-server 8.8.8.8 1.1.1.1
```

## Difference Between Layer 3 Switch and Router

### Layer 3 Switch

The default gateway is configured on the SVI (Switch Virtual Interface).

``` text
interface vlan 10
 ip address 192.168.10.1 255.255.255.0
 no shutdown
```

### Cisco Router

The default gateway is configured on a physical interface or
subinterface.

Single LAN:

``` text
interface GigabitEthernet0/0
 ip address 192.168.10.1 255.255.255.0
 no shutdown
```

Router-on-a-Stick:

``` text
interface GigabitEthernet0/0.10
 encapsulation dot1Q 10
 ip address 192.168.10.1 255.255.255.0
```

## Verification

``` text
show ip dhcp pool
show ip dhcp binding
show running-config | section dhcp
```

## Summary

  Feature              Layer 3 Switch         Cisco Router
  -------------------- ---------------------- -----------------------
  DHCP Configuration   Same                   Same
  Default Gateway      SVI (interface vlan)   Physical/Subinterface
  Inter-VLAN Routing   Yes                    Yes
  Typical Use          Enterprise LAN         Small office / Branch

> **Note:** `ip helper-address` is **not required** if the Layer 3
> Switch or Router is acting as the DHCP server. Configure
> `ip helper-address` only when the DHCP server resides on another
> subnet.
