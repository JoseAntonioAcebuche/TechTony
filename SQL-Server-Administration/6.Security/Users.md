# 👥 SQL Server Users Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Security

**Purpose:** Learn how SQL Server Database Users work, how they differ from Logins, how to create and manage users, assign roles and permissions, and apply security best practices.

---

# 📖 Overview

A **Database User** is a security principal that allows a Login to access a specific database.

Unlike a **Login**, which authenticates to the SQL Server instance, a **User** determines what actions can be performed inside a database.

Think of it this way:

- **Login** = Access to the SQL Server building
- **User** = Access to a specific room inside the building

---

# Login vs User

| Login | User |
|--------|------|
| Server Level | Database Level |
| Authenticates to SQL Server | Accesses a database |
| Stored in the master database | Stored in the target database |
| Required before accessing SQL Server | Required before accessing a database |

---

# Authentication and Authorization

```text
Client

    │

    ▼

Login

(Server Authentication)

    │

    ▼

Database User

(Database Authorization)

    │

    ▼

Database Roles

    │

    ▼

Permissions

    │

    ▼

Access Granted
```

---

# Types of Database Users

| User Type | Description |
|------------|-------------|
| SQL User | Mapped to a SQL Login |
| Windows User | Mapped to a Windows Login |
| Windows Group | Mapped to an Active Directory Group |
| Contained Database User | Exists only inside a database |
| Guest User | Allows limited access without a mapped user |

---

# View Database Users

```sql
SELECT
name,
type_desc,
create_date
FROM sys.database_principals
ORDER BY name;
```

---

# Create a Database User

Before creating a user, ensure the Login already exists.

```sql
USE ParkingDB;
GO

CREATE USER ParkingAdmin
FOR LOGIN ParkingAdmin;
```

---

# Create a Windows User

```sql
USE ParkingDB;
GO

CREATE USER
[DOMAIN\Tony]
FOR LOGIN
[DOMAIN\Tony];
```

---

# Create a Contained Database User

```sql
CREATE USER ParkingOperator
WITH PASSWORD='StrongPassword123!';
```

Contained users do not require a server-level Login.

---

# View User Properties

Using SQL Server Management Studio (SSMS):

```text
Databases

↓

ParkingDB

↓

Security

↓

Users

↓

Right Click User

↓

Properties
```

---

# Rename a User

```sql
ALTER USER ParkingAdmin
WITH NAME = ParkingAdministrator;
```

---

# Delete a User

```sql
DROP USER ParkingOperator;
```

> **Note:** Dropping a user removes access to the database but does not delete the associated Login.

---

# Map an Existing Login to a User

```sql
USE ParkingDB;
GO

CREATE USER ParkingSupport
FOR LOGIN ParkingSupport;
```

---

# View User Role Membership

```sql
SELECT
u.name AS UserName,
r.name AS DatabaseRole
FROM sys.database_role_members drm
JOIN sys.database_principals r
ON drm.role_principal_id = r.principal_id
JOIN sys.database_principals u
ON drm.member_principal_id = u.principal_id;
```

---

# Assign Database Roles

Example:

```sql
ALTER ROLE db_datareader
ADD MEMBER ParkingOperator;
```

Another example:

```sql
ALTER ROLE db_datawriter
ADD MEMBER ParkingOperator;
```

---

# Common Database Roles

| Role | Description |
|------|-------------|
| db_owner | Full control of the database |
| db_datareader | Read all tables and views |
| db_datawriter | Insert, update, and delete data |
| db_ddladmin | Create and modify database objects |
| db_backupoperator | Perform database backups |
| db_securityadmin | Manage permissions and roles |
| db_accessadmin | Manage database access |
| public | Default role for all users |

---

# Grant Permissions

Example:

```sql
GRANT SELECT
ON dbo.ParkingTransaction
TO ParkingOperator;
```

Grant multiple permissions:

```sql
GRANT
SELECT,
INSERT,
UPDATE
ON dbo.ParkingTransaction
TO ParkingOperator;
```

---

# Revoke Permissions

```sql
REVOKE
UPDATE
ON dbo.ParkingTransaction
FROM ParkingOperator;
```

---

# Deny Permissions

```sql
DENY DELETE
ON dbo.ParkingTransaction
TO ParkingOperator;
```

Unlike REVOKE, **DENY** explicitly blocks the permission.

---

# View User Permissions

```sql
SELECT
dp.state_desc,
dp.permission_name,
OBJECT_NAME(dp.major_id) AS ObjectName,
pr.name AS Principal
FROM sys.database_permissions dp
JOIN sys.database_principals pr
ON dp.grantee_principal_id = pr.principal_id;
```

---

# Orphaned Users

An orphaned user exists when the database user no longer has a matching Login.

Identify orphaned users:

```sql
SELECT
dp.name
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp
ON dp.sid = sp.sid
WHERE
sp.sid IS NULL
AND dp.authentication_type_desc = 'INSTANCE';
```

---

# Fix an Orphaned User

```sql
ALTER USER ParkingAdmin
WITH LOGIN = ParkingAdmin;
```

---

# Best Practices

- Use Windows Authentication whenever possible.
- Assign permissions through roles instead of individual users.
- Follow the Principle of Least Privilege.
- Remove unused users.
- Audit user permissions regularly.
- Avoid granting `db_owner` unless necessary.
- Use Active Directory groups for easier administration.

---

# Common Mistakes

❌ Granting `db_owner` to every user.

❌ Assigning permissions directly to users instead of roles.

❌ Forgetting to remove inactive users.

❌ Ignoring orphaned users after database restores.

❌ Using shared user accounts.

---

# Real-World Example

## Parking Management System

### Environment

Database

```
ParkingDB
```

Users

| User | Role |
|------|------|
| ParkingCashier | db_datareader |
| ParkingSupervisor | db_datareader, db_datawriter |
| ParkingDBA | db_owner |

Permissions

Cashier

- View parking transactions
- Search tickets

Supervisor

- View
- Update payment status
- Generate reports

DBA

- Full database administration

Benefits

- Role-based security
- Easier administration
- Better auditing
- Reduced security risks

---

# Daily DBA Checklist

- [ ] Review failed login attempts.
- [ ] Check new user requests.
- [ ] Verify user permissions.
- [ ] Monitor security changes.

---

# Weekly DBA Checklist

- [ ] Review database role membership.
- [ ] Identify orphaned users.
- [ ] Audit privileged users.
- [ ] Remove inactive users if appropriate.

---

# Related Documentation

- Logins
- Permissions
- Database Roles
- Server Roles
- SQL Server Security
- Auditing
- SQL Server Authentication

---

# Summary

| Object | Scope | Purpose |
|---------|-------|---------|
| Login | Server | Authenticate to SQL Server |
| User | Database | Access a specific database |
| Role | Database | Group permissions |
| Permission | Object | Allow or deny specific actions |

---

# User Access Workflow

```text
Client
    │
    ▼
SQL Server Login
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
    │
    ▼
Access Granted
```

---

# Enterprise Security Workflow

```text
Create Login
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
Test User Access
      │
      ▼
Audit Permissions
      │
      ▼
Production Ready
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
