# Technical Documentation

## Cisco Layer 3 Switch as Centralized DHCP Server

### Objective

Configure a Cisco Layer 3 Switch as a centralized DHCP Server to
automatically assign: - IP Address - Subnet Mask - Default Gateway - DNS
Server

to client devices on different VLANs.

------------------------------------------------------------------------

# Part 1 -- Prerequisite Configuration

Enable Layer 3 routing and configure the VLAN interface (SVI).

``` text
Switch# configure terminal
Switch(config)# ip routing
Switch(config)# interface vlan 10
Switch(config-if)# ip address 192.168.10.1 255.255.255.0
Switch(config-if)# no shutdown
Switch(config-if)# exit
```

Assign access ports:

``` text
Switch(config)# interface fa0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# no shutdown
```

Configure trunk if connecting to another switch:

``` text
Switch(config)# interface gi0/1
Switch(config-if)# switchport mode trunk
```

------------------------------------------------------------------------

# Part 2 -- DHCP Configuration

## Step 1 -- Exclude Static Addresses

``` text
Switch(config)# ip dhcp excluded-address 192.168.10.1
```

Exclude a range:

``` text
Switch(config)# ip dhcp excluded-address 192.168.10.1 192.168.10.20
```

## Step 2 -- Create DHCP Pool

``` text
Switch(config)# ip dhcp pool VLAN10_POOL
Switch(dhcp-config)# network 192.168.10.0 255.255.255.0
Switch(dhcp-config)# default-router 192.168.10.1
Switch(dhcp-config)# dns-server 8.8.8.8 1.1.1.1
Switch(dhcp-config)# exit
```

Optional:

``` text
lease 7
domain-name company.local
```

## Step 3 -- Save Configuration

``` text
Switch(config)# end
Switch# write memory
```

or

``` text
Switch# copy running-config startup-config
```

------------------------------------------------------------------------

# Part 3 -- Verification

``` text
show ip dhcp pool
show ip dhcp binding
show running-config | section dhcp
show ip interface brief
show ip route
show vlan brief
show interfaces status
show interfaces trunk
```

------------------------------------------------------------------------

# Part 4 -- Client Testing

``` text
PC> ip dhcp
```

Expected DORA process:

``` text
Discover
Offer
Request
Acknowledge

IP Address : 192.168.10.2
Subnet Mask: 255.255.255.0
Gateway    : 192.168.10.1
```

Test connectivity:

``` text
PC> ping 192.168.10.1
PC> ping 8.8.8.8
```

------------------------------------------------------------------------

# Sample Topology

``` text
             +------------------+
             |  Cisco L3 Switch |
             | DHCP Server      |
             | Vlan10 .1        |
             +---------+--------+
                       |
                  Trunk Link
                       |
          +------------+-----------+
          |     Access Switch      |
          +------------+-----------+
                       |
          +------------+------------+
          |                         |
         PC1                       PC2
      DHCP Client               DHCP Client
```

## Notes

-   `ip helper-address` is **not required** when the Layer 3 Switch is
    the DHCP server.
-   Use `ip helper-address` only when the DHCP server is located on a
    different subnet.
-   Create one DHCP pool for each VLAN.
