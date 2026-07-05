# IT Support L1/L2 Internet Troubleshooting Playbook

## OSI-Based Checklist

  -----------------------------------------------------------------------
  Layer                   Check                   Tools
  ----------------------- ----------------------- -----------------------
  1 Physical              Power, cable, link      Visual inspection
                          lights, Wi-Fi           

  2 Data Link             NIC enabled, VLAN,      Device Manager, switch
                          switch port             

  3 Network               IP, Gateway, Routing    `ipconfig`, `ping`,
                                                  `tracert`

  4 Transport             Firewall, ports         `Test-NetConnection`

  7 Application           DNS, browser, apps      `nslookup`, browser
  -----------------------------------------------------------------------

## Decision Tree

``` text
Start
 │
 ├── Physical connection OK?
 │      ├─ No → Check cable/NIC/switch/Wi-Fi
 │      └─ Yes
 │
 ├── ipconfig /all
 │      ├─ 169.254.x.x → DHCP/VLAN issue
 │      └─ Valid IP
 │
 ├── ping 127.0.0.1
 │      ├─ Fail → TCP/IP or OS issue
 │      └─ Pass
 │
 ├── ping <Your IP>
 │      ├─ Fail → NIC/Driver issue
 │      └─ Pass
 │
 ├── ping Gateway
 │      ├─ Fail → LAN/Switch/Gateway issue
 │      └─ Pass
 │
 ├── ping 8.8.8.8
 │      ├─ Fail → Router/ISP/Routing issue
 │      └─ Pass
 │
 ├── ping google.com
 │      ├─ Fail → DNS issue
 │      └─ Pass → Internet OK
```

## Useful Commands

``` cmd
ipconfig /all
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ping 127.0.0.1
ping <your_ip>
ping <gateway>
ping 8.8.8.8
ping google.com
nslookup google.com
tracert 8.8.8.8
netsh winsock reset
netsh int ip reset
```

## Escalate When

-   ISP outage suspected
-   Core switch/router unavailable
-   DHCP/DNS server unavailable
-   Firewall or WAN issue
-   Hardware failure beyond desktop scope
