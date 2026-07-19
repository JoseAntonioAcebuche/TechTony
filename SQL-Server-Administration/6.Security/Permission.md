# 🔑 SQL Server Permissions Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Security

**Purpose:** Learn how SQL Server Permissions work, how to grant, revoke, and deny permissions, understand the permission hierarchy, and apply security best practices in enterprise environments.

---

# 📖 Overview

SQL Server **Permissions** determine what actions a Login or Database User can perform within SQL Server.

Permissions are the foundation of SQL Server security and should be granted following the **Principle of Least Privilege**, ensuring users receive only the permissions necessary to perform their jobs.

Permissions may be granted directly to users or, preferably, through database roles.

---

# Why Permissions Matter

Permissions help organizations:

- Protect sensitive data
- Prevent unauthorized access
- Reduce accidental changes
- Support compliance requirements
- Implement Role-Based Access Control (RBAC)
- Improve database security

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

# Permission Levels

SQL Server permissions exist at different levels.

| Level | Examples |
|--------|----------|
| Server | CREATE LOGIN, ALTER ANY LOGIN |
| Database | CREATE TABLE, CREATE VIEW |
| Schema | SELECT ON SCHEMA |
| Object | SELECT, INSERT, UPDATE |
| Column | SELECT specific columns |

---

# Common Object Permissions

| Permission | Description |
|------------|-------------|
| SELECT | Read data |
| INSERT | Add new rows |
| UPDATE | Modify existing rows |
| DELETE | Remove rows |
| EXECUTE | Run stored procedures/functions |
| ALTER | Modify an object |
| CONTROL | Full control of an object |
| REFERENCES | Create foreign key references |
| VIEW DEFINITION | View object definitions |

---

# GRANT Permission

Allows access to an object.

```sql
GRANT SELECT
ON dbo.ParkingTransaction
TO ParkingCashier;
```

---

# Grant Multiple Permissions

```sql
GRANT

SELECT,
INSERT,
UPDATE

ON dbo.ParkingTransaction

TO ParkingSupervisor;
```

---

# Grant EXECUTE

```sql
GRANT EXECUTE

ON dbo.usp_ProcessPayment

TO CashierRole;
```

---

# REVOKE Permission

Removes a previously granted permission.

```sql
REVOKE UPDATE

ON dbo.ParkingTransaction

FROM ParkingSupervisor;
```

---

# DENY Permission

Explicitly blocks a permission.

```sql
DENY DELETE

ON dbo.ParkingTransaction

TO CashierRole;
```

Even if DELETE is granted through another role, **DENY takes precedence**.

---

# Permission Priority

```text
GRANT

↓

Access Allowed

DENY

↓

Access Blocked

DENY always wins.
```

---

# View Existing Permissions

```sql
SELECT

pr.name AS Principal,

pe.permission_name,

pe.state_desc,

OBJECT_NAME(pe.major_id) AS ObjectName

FROM sys.database_permissions pe

JOIN sys.database_principals pr

ON pe.grantee_principal_id = pr.principal_id

ORDER BY Principal;
```

---

# View Server Permissions

```sql
SELECT *

FROM sys.server_permissions;
```

---

# View Database Permissions

```sql
SELECT *

FROM sys.database_permissions;
```

---

# Grant Schema Permission

```sql
GRANT SELECT

ON SCHEMA::Sales

TO ReportingRole;
```

---

# Grant Database Permission

```sql
GRANT CREATE TABLE

TO DeveloperRole;
```

---

# Revoke Permission

```sql
REVOKE SELECT

ON dbo.ParkingTransaction

FROM ReportingRole;
```

---

# Best Practices

- Grant permissions to Roles instead of individual Users.
- Follow the Principle of Least Privilege.
- Review permissions regularly.
- Audit permission changes.
- Avoid granting CONTROL unnecessarily.
- Avoid using db_owner for application accounts.
- Document permission assignments.

---

# Common Mistakes

❌ Granting permissions directly to every user.

❌ Giving db_owner to application accounts.

❌ Ignoring inherited permissions.

❌ Forgetting to audit permission changes.

❌ Using sysadmin for ordinary users.

---

# Real-World Example

## Parking Management System

### Database

```text
ParkingDB
```

### Permission Model

| Role | Permissions |
|------|-------------|
| CashierRole | SELECT, INSERT |
| SupervisorRole | SELECT, INSERT, UPDATE |
| ReportingRole | SELECT |
| MaintenanceRole | EXECUTE |
| DBARole | Full Control |

### User Assignment

```text
ParkingCashier

↓

CashierRole

↓

SELECT
INSERT
```

```text
ParkingSupervisor

↓

SupervisorRole

↓

SELECT
INSERT
UPDATE
```

```text
ParkingMaintenance

↓

MaintenanceRole

↓

EXECUTE Stored Procedures
```

Benefits

- Better security
- Easier permission management
- Simplified auditing
- Reduced accidental data changes

---

# Daily DBA Checklist

- [ ] Review permission requests.
- [ ] Verify privileged users.
- [ ] Review failed access attempts.
- [ ] Check recent permission changes.

---

# Weekly DBA Checklist

- [ ] Audit database permissions.
- [ ] Audit server permissions.
- [ ] Remove unnecessary grants.
- [ ] Review role memberships.

---

# Related Documentation

- Logins
- Users
- Roles
- Auditing
- Encryption
- SQL Server Security

---

# Summary

| Permission | Purpose |
|------------|---------|
| SELECT | Read data |
| INSERT | Add data |
| UPDATE | Modify data |
| DELETE | Remove data |
| EXECUTE | Execute stored procedures |
| ALTER | Modify database objects |
| CONTROL | Full object control |
| DENY | Explicitly block access |

---

# Enterprise Permission Workflow

```text
Create Login

      │

      ▼

Create User

      │

      ▼

Assign Role

      │

      ▼

Grant Permissions

      │

      ▼

Test Access

      │

      ▼

Audit Permissions

      │

      ▼

Production Ready
```

---

# SQL Server Permission Model

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

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
