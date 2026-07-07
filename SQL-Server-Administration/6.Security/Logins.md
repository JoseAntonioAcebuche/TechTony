# 👤 SQL Server Logins Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Security

**Purpose:** Learn how SQL Server Logins work, how to create and manage logins, assign permissions, troubleshoot authentication issues, and apply security best practices.

---

# 📖 Overview

A **Login** is the identity used to authenticate and connect to a SQL Server instance.

Without a valid login, users cannot access SQL Server.

Think of a Login as the **front door** to SQL Server.

---

# Authentication Process

```text
Client

    │

    ▼

Login Request

    │

    ▼

SQL Server Authentication

    │

    ▼

Login Valid?

 ┌────┴────┐
 │         │
Yes       No
 │         │
 ▼         ▼

Access   Login Failed
Granted
```

---

# Login vs User

One of the most common sources of confusion.

| Login | User |
|--------|------|
| Server Level | Database Level |
| Connects to SQL Server | Accesses a database |
| Stored in master database | Stored inside each database |
| Authentication | Authorization |

Example

```text
SQL Server

↓

Login

↓

Database

↓

User

↓

Permissions
```

---

# Types of Logins

SQL Server supports two authentication methods.

## 1. Windows Authentication

Uses Windows or Active Directory credentials.

Advantages

- Integrated Security
- Password policies enforced
- Active Directory integration
- Recommended by Microsoft

Example

```
DOMAIN\jacebuche
```

---

## 2. SQL Server Authentication

Uses SQL Server username and password.

Example

```
Username

parkingadmin

Password

********
```

Useful for:

- Third-party applications
- Legacy systems
- Cross-platform connections

---

# View Existing Logins

```sql
SELECT
name,
type_desc,
create_date
FROM sys.server_principals
ORDER BY name;
```

---

# Create Windows Login

```sql
CREATE LOGIN
[DOMAIN\Tony]
FROM WINDOWS;
```

---

# Create SQL Login

```sql
CREATE LOGIN ParkingAdmin
WITH PASSWORD='StrongPassword123!';
```

---

# Create Login with Password Policy

```sql
CREATE LOGIN ParkingUser
WITH PASSWORD='StrongPassword123!',
CHECK_POLICY = ON,
CHECK_EXPIRATION = ON;
```

Benefits

- Enforces Windows password policy
- Password expiration
- Password complexity

---

# Disable Password Policy

```sql
CREATE LOGIN LegacyApp
WITH PASSWORD='Password123',
CHECK_POLICY = OFF;
```

Use only when absolutely necessary.

---

# View Login Properties

Using SSMS

```text
Security

↓

Logins

↓

Right Click Login

↓

Properties
```

---

# Change Login Password

```sql
ALTER LOGIN ParkingAdmin
WITH PASSWORD='NewStrongPassword123!';
```

---

# Enable Login

```sql
ALTER LOGIN ParkingAdmin
ENABLE;
```

---

# Disable Login

```sql
ALTER LOGIN ParkingAdmin
DISABLE;
```

Useful when:

- Employee leaves
- Account compromised
- Temporary maintenance

---

# Rename Login

```sql
ALTER LOGIN ParkingAdmin
WITH NAME = ParkingAdministrator;
```

---

# Delete Login

```sql
DROP LOGIN ParkingUser;
```

⚠ Ensure the login is no longer required before deleting it.

---

# View Login Status

```sql
SELECT
name,
is_disabled
FROM sys.server_principals;
```

---

# Grant Server Roles

Example

```sql
ALTER SERVER ROLE sysadmin
ADD MEMBER ParkingAdmin;
```

---

# Common Server Roles

| Server Role | Description |
|--------------|-------------|
| sysadmin | Full control |
| securityadmin | Manage logins |
| serveradmin | Server configuration |
| processadmin | Manage sessions |
| setupadmin | Linked servers |
| bulkadmin | Bulk import |
| dbcreator | Create databases |
| diskadmin | Manage disk files (legacy) |
| public | Default permissions |

---

# View Server Roles

```sql
SELECT
sp.name AS LoginName,
sr.name AS ServerRole
FROM sys.server_role_members rm
JOIN sys.server_principals sr
ON rm.role_principal_id = sr.principal_id
JOIN sys.server_principals sp
ON rm.member_principal_id = sp.principal_id;
```

---

# Login Failed Error

Common Error

```
Login failed for user.

Error 18456
```

Possible Causes

- Incorrect password
- Disabled login
- Login does not exist
- Authentication mode mismatch
- No database access

---

# Authentication Modes

## Windows Authentication Only

```
Windows Users

↓

SQL Server
```

---

## Mixed Mode Authentication

Supports:

- Windows Logins
- SQL Logins

Recommended when applications require SQL authentication.

---

# Change Authentication Mode

Using SSMS

```text
Server Properties

↓

Security

↓

Server Authentication

↓

Windows Authentication

or

SQL Server and Windows Authentication Mode
```

Restart SQL Server after changing the authentication mode.

---

# Best Practices

- Prefer Windows Authentication.
- Enforce password policies.
- Use least privilege.
- Disable unused logins.
- Review login permissions regularly.
- Avoid using the `sa` account for daily administration.
- Use separate administrative accounts.
- Audit login activity.

---

# Common Mistakes

❌ Granting `sysadmin` to every user.

❌ Using weak passwords.

❌ Leaving disabled employee accounts enabled.

❌ Sharing SQL login credentials.

❌ Using the `sa` account in applications.

---

# Real-World Example

## Parking Management System

### Environment

- SQL Server 2022
- Active Directory Domain
- 24/7 Operations

Configuration

Windows Login

```
DOMAIN\ParkingSupport
```

SQL Login

```
ParkingPOS
```

Server Roles

```
ParkingSupport

↓

securityadmin

ParkingPOS

↓

public
```

Benefits

- Secure authentication
- Role separation
- Easier account management
- Active Directory integration

---

# Daily DBA Checklist

- [ ] Review failed login attempts
- [ ] Check disabled accounts
- [ ] Verify new login requests
- [ ] Monitor authentication errors

---

# Weekly DBA Checklist

- [ ] Review server role memberships
- [ ] Disable inactive logins
- [ ] Audit privileged accounts
- [ ] Review SQL Server Error Log

---

# Related Documentation

- Users
- Roles
- Permissions
- SQL Server Security
- Database Users
- Server Roles
- Database Roles
- SQL Server Authentication
- Auditing

---

# Summary

| Feature | Description |
|----------|-------------|
| Login | Connects to SQL Server |
| User | Accesses a database |
| Windows Login | Active Directory authentication |
| SQL Login | SQL Server authentication |
| Server Roles | Server-wide permissions |
| Password Policy | Windows password enforcement |

---

# Login Authentication Workflow

```text
Client
    │
    ▼
Login Request
    │
    ▼
Authentication
    │
┌───┴────┐
│        │
Valid   Invalid
│        │
▼        ▼
Server   Error 18456
Access
│
▼
Database User
│
▼
Permissions
│
▼
Access Granted
```

---

# Enterprise Security Workflow

```text
New Employee
      │
      ▼
Create Windows Login
      │
      ▼
Create Database User
      │
      ▼
Assign Database Role
      │
      ▼
Grant Minimum Permissions
      │
      ▼
Test Login
      │
      ▼
Audit Access
      │
      ▼
Production Ready
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
