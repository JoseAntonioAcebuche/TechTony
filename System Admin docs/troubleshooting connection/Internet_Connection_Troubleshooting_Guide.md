# Internet Connection Troubleshooting Decision Tree

  ---------------------------------------------------------------------------------------
  Step                       Kapag FAILED             Posibleng Problema
  -------------------------- ------------------------ -----------------------------------
  **1. Physical Connection** Walang link light o      LAN cable, NIC, switch port,
                             disconnected             router, Wi-Fi

  **2. `ipconfig /all`**     Walang IP o              DHCP server, cable, VLAN, network
                             `169.254.x.x`            connection

  **3. `ping 127.0.0.1`**    Failed                   TCP/IP stack o operating system
                                                      issue

  **4. `ping <your IP>`**    Failed                   Network adapter (NIC), driver, o
                                                      TCP/IP issue

  **5.                       Failed                   LAN problem (switch, cable, VLAN,
  `ping Default Gateway`**                            gateway offline)

  **6. `ping 8.8.8.8`**      Failed                   Walang internet, router routing
                                                      issue, o ISP problem

  **7. `ping google.com`**   `8.8.8.8` works pero ito DNS problem
                             failed                   

  **8. `nslookup` /          Failed                   `nslookup`: DNS server issue.
  `tracert`**                                         `tracert`: routing issue o ISP
                                                      problem
  ---------------------------------------------------------------------------------------

## Halimbawa

### Scenario 1

-   ✅ May IP address
-   ✅ Ping gateway
-   ❌ Ping 8.8.8.8

**Diagnosis:** Router o ISP issue.

### Scenario 2

-   ✅ Ping 8.8.8.8
-   ❌ Ping `google.com`

**Diagnosis:** DNS issue.

### Scenario 3

-   ❌ Ping Default Gateway

**Diagnosis:** LAN problem (cable, switch, VLAN, o gateway).

### Scenario 4

-   `ipconfig` shows **169.254.x.x**

**Diagnosis:** Walang DHCP lease.

## Troubleshooting Flow

``` text
Physical Connection
        ↓
ipconfig /all
        ↓
Ping 127.0.0.1
        ↓
Ping Own IP
        ↓
Ping Default Gateway
        ↓
Ping 8.8.8.8
        ↓
Ping google.com
        ↓
nslookup / tracert
        ↓
Restart Network Equipment
        ↓
Escalate to Network Team / ISP
```
