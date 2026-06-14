# HPE 1920 Switch — VLAN Configuration Guide

> **Platform:** HPE 1920-24G | Web Management Platform (GUI) + CLI Reference  
> **Scope:** VLAN creation, access ports, trunk ports, switch-to-switch trunking, management IP

---

## Table of Contents

1. [Creating a VLAN](#1-creating-a-vlan)
2. [Assigning a Port to a VLAN (Access Port)](#2-assigning-a-port-to-a-vlan-access-port)
3. [Configuring a Trunk Port](#3-configuring-a-trunk-port)
4. [Trunk Port — Switch to Switch](#4-trunk-port--switch-to-switch)
5. [Assigning a Management IP to the Switch](#5-assigning-a-management-ip-to-the-switch)
6. [Common Troubleshooting](#6-common-troubleshooting)

---

## 1. Creating a VLAN

### Via GUI

Navigate to: **Network > VLAN > Create tab**

1. Enter VLAN ID/s in the **VLAN IDs** field
2. Supports range format — example: `5-10` creates VLAN 5, 6, 7, 8, 9, 10 in one shot
3. Click **Create**
4. Optional: Add a **Description** (1–32 characters) then click **Apply**

> **NOTE:** Range input is a key HPE advantage — on Cisco CLI you would need `vlan 5,6,7,8,9,10` or create them one by one.

### Via CLI

```bash
system-view

vlan 200
 name DATA_VLAN
quit

save force
```

---

## 2. Assigning a Port to a VLAN (Access Port)

### Via GUI

Navigate to: **Network > VLAN > select your VLAN > Port Detail tab**

1. Select the target port (e.g. `GE1/0/1`)
2. Set **Membership Type** to: `Untagged`
3. Set **PVID** to match the VLAN ID (e.g. `200`)
4. Click **Apply**

> **NOTE:** PVID (Port VLAN ID) is critical for access ports. It tells the switch which VLAN to tag untagged incoming frames with.

| Membership Type | Use Case | PVID Required? |
|---|---|---|
| Untagged | Access port — end devices (PC, printer, IP phone) | Yes — set to VLAN ID |
| Tagged | Trunk port — switch-to-switch or router uplink | No (or set to native VLAN) |

### Via CLI

```bash
interface GigabitEthernet 1/0/1
 port link-type access
 port access vlan 200
quit
```

---

## 3. Configuring a Trunk Port

A trunk port carries multiple VLANs between switches or to a router. You must set each VLAN's membership to **Tagged** on the trunk port.

### Via GUI

> **IMPORTANT:** HPE GUI is **per-VLAN** assignment — you need to go into each VLAN and tag the trunk port individually. This is different from Cisco CLI where one command covers all VLANs.

1. Navigate to: **Network > VLAN**
2. Click on **VLAN 100**
3. Select your trunk port (e.g. `GE1/0/24`)
4. Set **Membership Type** to: `Tagged`
5. Click **Apply**
6. **Repeat steps 2–5 for every VLAN** that needs to pass through the trunk

#### Quick Visual Flow

```
Network > VLAN
  └── Click VLAN 100 → Select GE1/0/24 → Tagged → Apply
  └── Click VLAN 200 → Select GE1/0/24 → Tagged → Apply
  └── Click VLAN 300 → Select GE1/0/24 → Tagged → Apply
```

### Via CLI

```bash
interface GigabitEthernet 1/0/24
 port link-type trunk
 port trunk permit vlan 100 200 300
 port trunk pvid vlan 1
quit

save force
```

> **TIP:** If you have 10+ VLANs to assign to a trunk port — CLI is significantly faster than GUI.

---

## 4. Trunk Port — Switch to Switch

**Both sides of a trunk link must be manually configured.**  
HPE 1920 has **NO auto-negotiation protocol** (unlike Cisco DTP).

```
Switch A (GE1/0/24) ←————————→ Switch B (GE1/0/24)
  VLAN 100 Tagged                 VLAN 100 Tagged
  VLAN 200 Tagged                 VLAN 200 Tagged
  VLAN 300 Tagged                 VLAN 300 Tagged
```

> **NOTE:** If VLANs do not match on both sides, traffic for the missing VLAN will be dropped silently.

### HPE vs Cisco — Trunk Comparison

| Feature | HPE 1920 | Cisco |
|---|---|---|
| Auto trunk negotiation | None — manual both sides | DTP (not recommended in production) |
| Trunk config method | Per-VLAN Tagged in GUI | `switchport mode trunk` + `allowed vlan` |
| Batch VLAN assignment | Range input (`5-10`) | `vlan 5,6,7,8,9,10` |
| Security posture | More secure by default | Must disable DTP manually (`switchport nonegotiate`) |

> **Security note:** Cisco's DTP is a known attack vector (DTP spoofing). Best practice on Cisco is to disable it with `switchport nonegotiate`. HPE 1920 effectively enforces this by default — no auto negotiation at all.

---

## 5. Assigning a Management IP to the Switch

A management IP allows you to access the switch via browser or SSH from the network.

### Via GUI

Navigate to: **Network > VLAN Interface > select VLAN 1** (or your management VLAN)

1. Click on **VLAN Interface**
2. Select **VLAN 1** (default management VLAN)
3. Enter **IP Address** and **Subnet Mask**
4. Click **Apply**

### Via CLI

```bash
system-view

interface Vlan-interface 1
 ip address 192.168.1.1 255.255.255.0
quit

# Default gateway
ip route-static 0.0.0.0 0.0.0.0 192.168.1.254

save force
```

### Accessing the Switch via Browser

```
http://192.168.1.1

Default credentials:
  Username : admin
  Password : admin (or blank)
```

> **SECURITY:** Change default credentials immediately after initial setup.

---

## 6. Common Troubleshooting

| Issue | Possible Cause | Fix |
|---|---|---|
| Cannot access switch after VLAN change | Management VLAN not in trunk | Add management VLAN as Tagged on trunk port |
| PVID not working | PVID not set on access port | Set PVID = VLAN ID on the access port |
| Trunk not passing traffic | VLANs not Tagged on one or both sides | Verify Tagged membership on both switch ends |
| Slow GUI configuration | Per-VLAN assignment limitation | Use CLI for bulk VLAN-to-port assignments |
| VLANs exist but no traffic | VLAN not created on the other switch | Ensure same VLANs exist and are tagged both sides |

---

## Quick Reference Cheatsheet

```bash
# Create VLAN
vlan 200
 name DATA_VLAN
quit

# Access port
interface GigabitEthernet 1/0/1
 port link-type access
 port access vlan 200
quit

# Trunk port
interface GigabitEthernet 1/0/24
 port link-type trunk
 port trunk permit vlan 100 200 300
 port trunk pvid vlan 1
quit

# Management IP
interface Vlan-interface 1
 ip address 192.168.1.1 255.255.255.0
quit

ip route-static 0.0.0.0 0.0.0.0 192.168.1.254

# Save
save force
```

---

*Document prepared for personal IT documentation library | HPE 1920-24G Switch Reference*
