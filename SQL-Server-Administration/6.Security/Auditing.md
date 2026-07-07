# 📝 SQL Server Auditing Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Security

**Purpose:** Learn how to monitor, record, and review SQL Server activities using SQL Server Audit, Server Audit Specifications, and Database Audit Specifications to improve security, compliance, and accountability.

---

# 📖 Overview

**SQL Server Auditing** is a security feature that records actions performed within SQL Server.

Auditing helps organizations answer questions such as:

- Who logged in?
- Who accessed sensitive data?
- Who modified records?
- Who deleted information?
- Who changed permissions?
- When did an event occur?

Auditing is essential for:

- Security investigations
- Compliance requirements
- Change tracking
- User accountability

---

# Why Audit SQL Server?

Auditing provides:

- Security monitoring
- Compliance reporting
- Insider threat detection
- Activity history
- Database accountability
- Change tracking

---

# SQL Server Audit Architecture

```text
SQL Server

      │

      ▼

SQL Server Audit

      │

      ▼

Audit Specification

      │

      ▼

Audit Target

      │

 ┌────┼───────────────┐
 ▼    ▼               ▼
File Windows Log Azure Storage
```

---

# Components

| Component | Purpose |
|------------|----------|
| SQL Server Audit | Defines audit destination |
| Server Audit Specification | Audits server-level actions |
| Database Audit Specification | Audits database actions |
| Audit Logs | Stores audit records |

---

# Audit Targets

Audit records may be written to:

- File
- Windows Application Log
- Windows Security Log
- Azure Storage (Azure SQL)

Recommended:

```
Audit File
```

---

# Create a Server Audit

```sql
USE master;
GO

CREATE SERVER AUDIT ParkingAudit

TO FILE
(
FILEPATH='D:\SQLAudit\'
);

GO
```

---

# Enable the Audit

```sql
ALTER SERVER AUDIT ParkingAudit

WITH (STATE = ON);
```

---

# Create Server Audit Specification

Example

```sql
CREATE SERVER AUDIT SPECIFICATION ServerAuditSpec

FOR SERVER AUDIT ParkingAudit

ADD (FAILED_LOGIN_GROUP),

ADD (SUCCESSFUL_LOGIN_GROUP);

GO
```

---

# Enable Specification

```sql
ALTER SERVER AUDIT SPECIFICATION ServerAuditSpec

WITH (STATE = ON);
```

---

# Create Database Audit Specification

```sql
USE ParkingDB;

GO

CREATE DATABASE AUDIT SPECIFICATION ParkingAuditSpec

FOR SERVER AUDIT ParkingAudit

ADD
(
SELECT,
INSERT,
UPDATE,
DELETE

ON dbo.ParkingTransaction

BY PUBLIC
);

GO
```

---

# Enable Database Audit

```sql
ALTER DATABASE AUDIT SPECIFICATION ParkingAuditSpec

WITH (STATE = ON);
```

---

# View Audit Logs

```sql
SELECT *

FROM sys.fn_get_audit_file
(
'D:\SQLAudit\*.sqlaudit',
DEFAULT,
DEFAULT
);
```

---

# View Existing Audits

```sql
SELECT *

FROM sys.server_audits;
```

---

# View Audit Specifications

Server

```sql
SELECT *

FROM sys.server_audit_specifications;
```

Database

```sql
SELECT *

FROM sys.database_audit_specifications;
```

---

# Disable Audit

```sql
ALTER SERVER AUDIT ParkingAudit

WITH (STATE = OFF);
```

---

# Delete Audit

```sql
DROP SERVER AUDIT ParkingAudit;
```

Disable the audit first before dropping it.

---

# Common Audit Events

| Event | Description |
|---------|-------------|
| Successful Login | User logged in |
| Failed Login | Invalid login |
| SELECT | Data viewed |
| INSERT | Data inserted |
| UPDATE | Data modified |
| DELETE | Data removed |
| EXECUTE | Stored procedure executed |
| ALTER | Object modified |
| CREATE | Object created |
| DROP | Object deleted |

---

# Server-Level Events

Examples

- Login Success
- Login Failure
- Server Role Changes
- Server Configuration Changes
- Backup Operations
- Restore Operations

---

# Database-Level Events

Examples

- SELECT
- INSERT
- UPDATE
- DELETE
- EXECUTE
- Permission Changes
- Object Creation
- Object Deletion

---

# View Failed Logins

If auditing is enabled:

```sql
SELECT

event_time,

server_principal_name,

action_id

FROM sys.fn_get_audit_file
(
'D:\SQLAudit\*.sqlaudit',
DEFAULT,
DEFAULT
)

WHERE action_id='LGIF';
```

---

# Audit Best Practices

- Audit privileged accounts.
- Audit failed logins.
- Audit permission changes.
- Audit schema changes.
- Protect audit files.
- Archive old audit logs.
- Review audit logs regularly.
- Monitor audit storage usage.

---

# Performance Considerations

Auditing has minimal overhead when configured properly.

Avoid auditing:

- Every SELECT on every table.
- High-frequency operations unless required.
- Temporary objects.

Audit only what is necessary.

---

# Common Mistakes

❌ Auditing everything.

❌ Never reviewing audit logs.

❌ Storing audit files on the same disk as database files.

❌ Allowing unauthorized access to audit logs.

❌ Forgetting to archive old audit files.

---

# Compliance Standards

SQL Server Auditing supports many security standards including:

- ISO 27001
- PCI-DSS
- HIPAA
- SOX
- GDPR

---

# Real-World Example

## Parking Management System

### Environment

- SQL Server 2022
- 24/7 Parking Operations
- Payment Processing

Audited Events

- Cashier logins
- Failed login attempts
- Payment updates
- Parking transaction changes
- Database backups
- Permission changes

Benefits

- Complete audit trail
- Improved security
- Easier investigations
- Regulatory compliance

---

# Daily DBA Checklist

- [ ] Review failed logins.
- [ ] Verify audit service is running.
- [ ] Check audit file storage.
- [ ] Review security-related events.

---

# Weekly DBA Checklist

- [ ] Archive old audit files.
- [ ] Review privileged user activity.
- [ ] Verify audit specifications.
- [ ] Test audit functionality.

---

# Related Documentation

- SQL Server Security
- Logins
- Users
- Roles
- Permissions
- Encryption
- SQL Server Agent Jobs
- Backup and Restore
- Extended Events

---

# Summary

| Audit Component | Purpose |
|-----------------|----------|
| SQL Server Audit | Defines audit target |
| Server Audit Specification | Server-level events |
| Database Audit Specification | Database-level events |
| Audit File | Stores audit logs |
| fn_get_audit_file() | Reads audit files |

---

# Enterprise Auditing Workflow

```text
User Activity
      │
      ▼
SQL Server Audit
      │
      ▼
Audit Specification
      │
      ▼
Audit File
      │
      ▼
Security Review
      │
      ▼
Compliance Report
      │
      ▼
Incident Investigation
```

---

# Enterprise Security Model

```text
Firewall
      │
      ▼
TLS Encryption
      │
      ▼
Authentication
      │
      ▼
Roles & Permissions
      │
      ▼
SQL Server Audit
      │
      ▼
Audit Logs
      │
      ▼
Security Monitoring
      │
      ▼
Compliance
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
