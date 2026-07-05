# Enterprise Local Network Troubleshooting Playbook

## Network Path

``` text
PC
 │
 ▼
Access Switch
 │
 ▼
Core Switch
 │
 ▼
Domain Controller / File Server / Application Server
```

## Step 1 - Physical Layer

Check: - LAN cable - Link lights - NIC status - Switch port status

If FAILED: - Replace cable - Enable NIC - Verify switch port - Check
patch panel

------------------------------------------------------------------------

## Step 2 - Verify IP Configuration

``` cmd
ipconfig /all
```

Verify: - IP Address - Subnet Mask - Default Gateway - DNS Server

Possible Issues: - 169.254.x.x = DHCP issue - Wrong subnet = VLAN/IP
configuration issue

------------------------------------------------------------------------

## Step 3 - Test Local TCP/IP

``` cmd
ping 127.0.0.1
ping <your_ip>
```

Failure indicates: - TCP/IP corruption - NIC driver issue

------------------------------------------------------------------------

## Step 4 - Test Gateway

``` cmd
ping <default_gateway>
```

Failure indicates: - Access switch issue - VLAN mismatch - Gateway
unavailable - Incorrect IP configuration

------------------------------------------------------------------------

## Step 5 - Verify Access Switch

Common Commands:

``` text
show interface status
show vlan
show mac address-table
show interface counters
```

Verify: - Port is UP - Correct VLAN - MAC address learned - No interface
errors

------------------------------------------------------------------------

## Step 6 - Test Core Switch

``` cmd
ping <core_switch_ip>
```

Failure indicates: - Uplink failure - Routing issue - ACL - Core switch
problem

------------------------------------------------------------------------

## Step 7 - Test Domain Controller

``` cmd
ping dc01.company.local
```

or

``` cmd
ping <DC_IP>
```

Failure indicates: - Server offline - Routing issue - Firewall - DNS
issue

------------------------------------------------------------------------

## Step 8 - Verify DNS

``` cmd
nslookup dc01.company.local
```

Failure indicates: - DNS server unavailable - Incorrect DNS
configuration

------------------------------------------------------------------------

## Step 9 - Verify Active Directory

``` cmd
nltest /dsgetdc:company.local
```

Failure indicates: - Domain Controller unavailable - DNS issue -
Netlogon problem

------------------------------------------------------------------------

## Step 10 - Verify File Shares

``` cmd
\\dc01\share
```

or

``` cmd
net use
```

Failure indicates: - SMB issue - Permissions - Firewall - File server
unavailable

------------------------------------------------------------------------

# Enterprise Decision Tree

``` text
PC
 │
 ├── Physical Connection
 │      ├── Fail → Cable / NIC / Switch Port
 │      └── Pass
 │
 ├── Valid IP
 │      ├── No → DHCP / VLAN
 │      └── Yes
 │
 ├── Ping Own IP
 │      ├── Fail → TCP/IP / Driver
 │      └── Pass
 │
 ├── Ping Gateway
 │      ├── Fail → Access Switch / VLAN
 │      └── Pass
 │
 ├── Ping Core Switch
 │      ├── Fail → Routing / Uplink
 │      └── Pass
 │
 ├── Ping Domain Controller
 │      ├── Fail → Server / Firewall
 │      └── Pass
 │
 ├── nslookup
 │      ├── Fail → DNS
 │      └── Pass
 │
 ├── nltest
 │      ├── Fail → Active Directory
 │      └── Pass
 │
 └── Local Network Healthy
```

## Escalation Guide

Escalate to Network Team: - VLAN issues - Core switch issues - Routing
problems - ACL issues

Escalate to System Administrator: - Active Directory - DNS - DHCP - File
Server - Group Policy

Escalate to Security Team: - Firewall blocking - NAC issues - Endpoint
security
