# 💾 SQL Server DBCC CHECKDB

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** To verify the logical and physical integrity of a SQL Server database and detect corruption before it causes data loss.

---

# 📖 Overview

`DBCC CHECKDB` (Database Console Command CHECKDB) is one of the most important maintenance commands in SQL Server.

It checks the consistency and integrity of:

- Tables
- Indexes
- Allocation structures
- System catalogs
- Data pages
- File consistency
- Metadata

It is considered one of the core health-check tools for every SQL Server Database Administrator (DBA).

---

# Why Run DBCC CHECKDB?

Database corruption can occur because of:

- Power failures
- Storage failures
- Bad sectors
- Memory errors
- Unexpected shutdowns
- RAID controller failures
- Operating system crashes
- SQL Server bugs (rare)

Running DBCC CHECKDB helps detect these issues before they become critical.

---

# Advantages

- Detects database corruption
- Verifies page consistency
- Checks indexes
- Validates allocation structures
- Helps prevent unexpected database failures

---

# Disadvantages

- Can consume significant CPU
- Can generate heavy Disk I/O
- May take a long time on large databases
- Should not be run during peak production hours

---

# Basic Syntax

```sql
DBCC CHECKDB ('DatabaseName');
```

Example

```sql
DBCC CHECKDB ('ParkingDB');
```

---

# Check Current Database

```sql
DBCC CHECKDB;
```

---

# Display Informational Messages

```sql
DBCC CHECKDB
(
'ParkingDB'
)
WITH NO_INFOMSGS;
```

Removes unnecessary informational messages and only reports warnings or errors.

---

# Display All Error Messages

```sql
DBCC CHECKDB
(
'ParkingDB'
)
WITH ALL_ERRORMSGS;
```

Useful for detailed troubleshooting.

---

# Estimate TempDB Space Required

```sql
DBCC CHECKDB
(
'ParkingDB'
)
WITH ESTIMATEONLY;
```

Useful before running CHECKDB on large databases.

---

# Perform Physical Checks Only

```sql
DBCC CHECKDB
(
'ParkingDB'
)
WITH PHYSICAL_ONLY;
```

### Advantages

- Faster
- Less resource intensive
- Detects physical corruption

### Disadvantages

- Does not perform complete logical consistency checks

Recommended for daily health checks.

---

# Repair Options

## REPAIR_REBUILD

Repairs minor corruption without data loss.

```sql
DBCC CHECKDB
(
'ParkingDB',
REPAIR_REBUILD
);
```

---

## REPAIR_ALLOW_DATA_LOSS

Repairs severe corruption.

```sql
DBCC CHECKDB
(
'ParkingDB',
REPAIR_ALLOW_DATA_LOSS
);
```

> ⚠ **Warning:** This option may permanently delete damaged data. It should only be used as a last resort when a valid backup is unavailable.

---

# Emergency Repair Procedure

## Step 1

Set the database to Emergency Mode.

```sql
ALTER DATABASE ParkingDB
SET EMERGENCY;
```

---

## Step 2

Switch to Single User Mode.

```sql
ALTER DATABASE ParkingDB
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
```

---

## Step 3

Run DBCC CHECKDB.

```sql
DBCC CHECKDB
(
'ParkingDB',
REPAIR_ALLOW_DATA_LOSS
);
```

---

## Step 4

Return the database to Multi-User Mode.

```sql
ALTER DATABASE ParkingDB
SET MULTI_USER;
```

---

# Common Output

Healthy Database

```text
CHECKDB found 0 allocation errors and 0 consistency errors.
```

Corrupted Database

```text
Msg 8928

Object ID 123456

Page could not be processed.
```

---

# Recommended Schedule

| Database Size | Frequency |
|---------------|-----------|
| Small | Weekly |
| Medium | Weekly |
| Large | Weekly or Monthly |
| Mission Critical | Weekly with PHYSICAL_ONLY daily |

---

# Best Practices

- Run during maintenance windows.
- Always maintain recent Full and Transaction Log backups.
- Use `PHYSICAL_ONLY` for frequent checks.
- Run a full `DBCC CHECKDB` regularly.
- Review SQL Server Error Logs after corruption is detected.
- Test database restores regularly.
- Monitor disk health and RAID status.

---

# Common Mistakes

❌ Running CHECKDB during business hours on busy servers.

❌ Ignoring corruption warnings.

❌ Using `REPAIR_ALLOW_DATA_LOSS` without attempting a restore from backup.

❌ Not testing backups before relying on them.

---

# Performance Considerations

Large databases may require:

- High CPU utilization
- Increased TempDB usage
- Significant Disk I/O
- Extended execution time

For databases larger than 1 TB, schedule CHECKDB during dedicated maintenance windows.

---

# Real-World Scenario

### Parking Management System

During routine maintenance, users reported occasional POS transaction failures.

Investigation steps:

1. Checked SQL Server Error Log.
2. Ran:

```sql
DBCC CHECKDB ('ParkingDB')
WITH NO_INFOMSGS;
```

Result:

```text
0 allocation errors
0 consistency errors
```

The database was healthy, and the issue was traced to an application configuration problem rather than database corruption.

---

# Troubleshooting Flow

```text
Users Report Database Errors
            │
            ▼
Run DBCC CHECKDB
            │
            ├── No Errors
            │      │
            │      └── Investigate Application or Hardware
            │
            └── Errors Found
                   │
                   ▼
Check Recent Backup
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
Restore Backup      Emergency Repair
                            │
                            ▼
          REPAIR_ALLOW_DATA_LOSS (Last Resort)
```

---

# Summary

| Command | Purpose |
|----------|---------|
| `DBCC CHECKDB` | Full database integrity check |
| `WITH PHYSICAL_ONLY` | Fast physical consistency check |
| `WITH NO_INFOMSGS` | Display only errors |
| `WITH ALL_ERRORMSGS` | Show complete error details |
| `WITH ESTIMATEONLY` | Estimate TempDB requirements |
| `REPAIR_REBUILD` | Repair minor corruption |
| `REPAIR_ALLOW_DATA_LOSS` | Repair severe corruption (last resort) |

---

# Related Documentation

- Recovery Models
- Database States
- Backup Operations
- Restore Operations
- Performance Tuning
- SQL Server Maintenance Plan
- Common Causes of Data Corruption

---

**Documentation by:**  
**Jose Antonio "Tony" Acebuche**
