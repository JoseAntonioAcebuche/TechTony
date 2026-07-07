# 🛡️ SQL Server Roles Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Security

**Purpose:** Learn SQL Server Roles, including Server Roles and Database Roles, how to create custom roles, assign users, and implement Role-Based Access Control (RBAC).

---

# 📖 Overview

A **Role** is a collection of permissions that can be assigned to one or more users or logins.

Instead of granting permissions individually to every user, administrators assign permissions to a role and then add users to that role.

This approach is called **Role-Based Access Control (RBAC)** and is considered a security best practice.

---

# Why Use Roles?

Benefits include:

- Easier administration
- Consistent permissions
- Improved security
- Simplified auditing
- Supports the Principle of Least Privilege
- Easier onboarding and offboarding

---

# SQL Server Security Hierarchy

```text
Login
   │
   ▼
Database User
   │
   ▼
Database Role
   │
   ▼
Permissions
   │
   ▼
Database Objects
```

---

# Types of Roles

SQL Server has two major role categories.

| Role Type | Scope |
|------------|-------|
| Server Roles | Entire SQL Server Instance |
| Database Roles | Individual Database |

---

# Server Roles

Server Roles control permissions at the SQL Server instance level.

View server roles:

```sql
SELECT
name,
type_desc
FROM sys.server_principals
WHERE type='R';
```

---

# Built-in Server Roles

| Role | Description |
|------|-------------|
| sysadmin | Full control of SQL Server |
| securityadmin | Manage logins and permissions |
| serveradmin | Configure server settings |
| processadmin | Manage SQL processes |
| setupadmin | Configure linked servers |
| bulkadmin | Perform BULK INSERT |
| dbcreator | Create and restore databases |
| diskadmin | Manage disk files (legacy) |
| public | Default permissions |

---

# Add Login to Server Role

Example

```sql
ALTER SERVER ROLE sysadmin
ADD MEMBER ParkingDBA;
```

---

# Remove Login from Server Role

```sql
ALTER SERVER ROLE sysadmin
DROP MEMBER ParkingDBA;
```

---

# Database Roles

Database Roles control permissions within a specific database.

View database roles:

```sql
SELECT
name
FROM sys.database_principals
WHERE type='R';
```

---

# Built-in Database Roles

| Role | Description |
|------|-------------|
| db_owner | Full control of database |
| db_datareader | Read all tables and views |
| db_datawriter | Insert, Update, Delete |
| db_ddladmin | Create and modify objects |
| db_backupoperator | Perform backups |
| db_securityadmin | Manage permissions |
| db_accessadmin | Manage database users |
| public | Default database permissions |

---

# Add User to Database Role

```sql
ALTER ROLE db_datareader
ADD MEMBER ParkingCashier;
```

---

# Remove User from Database Role

```sql
ALTER ROLE db_datareader
DROP MEMBER ParkingCashier;
```

---

# Create a Custom Database Role

Example

```sql
CREATE ROLE CashierRole;
```

---

# Grant Permissions to a Role

```sql
GRANT
SELECT,
INSERT
ON dbo.ParkingTransaction
TO CashierRole;
```

---

# Add User to Custom Role

```sql
ALTER ROLE CashierRole
ADD MEMBER ParkingCashier;
```

---

# View Members of a Role

```sql
SELECT

r.name AS RoleName,

m.name AS MemberName

FROM sys.database_role_members drm

JOIN sys.database_principals r
ON drm.role_principal_id = r.principal_id

JOIN sys.database_principals m
ON drm.member_principal_id = m.principal_id

ORDER BY RoleName;
```

---

# Drop a Custom Role

```sql
DROP ROLE CashierRole;
```

> The role must have no members before it can be dropped.

---

# Role-Based Access Control (RBAC)

Instead of this:

```text
User1 → SELECT

User2 → SELECT

User3 → SELECT
```

Use:

```text
CashierRole

↓

SELECT

↓

User1

User2

User3
```

Benefits:

- Easier maintenance
- Fewer mistakes
- Better scalability

---

# Common Permission Workflow

```text
Create Login

↓

Create User

↓

Create Role

↓

Grant Permissions

↓

Add User to Role
```

---

# Example

Parking System

Roles

```
CashierRole

↓

SELECT

INSERT
```

```
SupervisorRole

↓

SELECT

INSERT

UPDATE
```

```
DBARole

↓

Full Database Control
```

---

# Grant Multiple Permissions

```sql
GRANT

SELECT,

INSERT,

UPDATE

ON dbo.ParkingTransaction

TO SupervisorRole;
```

---

# Revoke Permissions

```sql
REVOKE

UPDATE

ON dbo.ParkingTransaction

FROM SupervisorRole;
```

---

# Deny Permissions

```sql
DENY

DELETE

ON dbo.ParkingTransaction

TO CashierRole;
```

---

# Best Practices

- Assign permissions to roles instead of individual users.
- Use custom roles for business functions.
- Follow the Principle of Least Privilege.
- Review role membership regularly.
- Avoid assigning `db_owner` unnecessarily.
- Avoid granting `sysadmin` except to DBAs.

---

# Common Mistakes

❌ Giving every user `db_owner`.

❌ Using `sysadmin` for application accounts.

❌ Granting permissions directly to users.

❌ Not documenting custom roles.

❌ Forgetting to review role memberships.

---

# Real-World Example

## Parking Management System

### Database

```
ParkingDB
```

### Roles

| Role | Permissions |
|------|-------------|
| CashierRole | SELECT, INSERT |
| SupervisorRole | SELECT, INSERT, UPDATE |
| ReportingRole | SELECT |
| MaintenanceRole | EXECUTE Stored Procedures |
| DBARole | Full Control |

Users

```
ParkingCashier01

↓

CashierRole

ParkingSupervisor

↓

SupervisorRole

ParkingDBA

↓

db_owner
```

Benefits

- Secure access
- Easier onboarding
- Easier auditing
- Centralized permission management

---

# Daily DBA Checklist

- [ ] Review new role assignments.
- [ ] Verify privileged accounts.
- [ ] Monitor security changes.

---

# Weekly DBA Checklist

- [ ] Audit server roles.
- [ ] Audit database roles.
- [ ] Remove unnecessary role memberships.
- [ ] Review custom roles.

---

# Related Documentation

- Logins
- Users
- Permissions
- SQL Server Security
- Authentication
- Auditing
- Database Security

---

# Summary

| Object | Scope | Purpose |
|---------|-------|---------|
| Server Role | SQL Server Instance | Server administration |
| Database Role | Database | Database permissions |
| Custom Role | Database | Business-specific permissions |
| RBAC | Security Model | Manage permissions through roles |

---

# Enterprise RBAC Workflow

```text
New Employee
      │
      ▼
Create Login
      │
      ▼
Create Database User
      │
      ▼
Assign Business Role
      │
      ▼
Role Grants Permissions
      │
      ▼
User Gains Access
      │
      ▼
Audit Membership
```

---

# SQL Server Security Model

```text
SQL Server

      │

      ▼

Login

      │

      ▼

Database User

      │

      ▼

Database Role

      │

      ▼

Permissions

      │

      ▼

Database Objects
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
