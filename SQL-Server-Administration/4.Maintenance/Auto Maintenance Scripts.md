# 🤖 SQL Server Auto Maintenance Scripts Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Administration

**Purpose:** Learn how to automate SQL Server maintenance tasks using T-SQL scripts and SQL Server Agent Jobs to keep databases healthy with minimal manual intervention.

---

# 📖 Overview

Database maintenance should be automated whenever possible.

SQL Server provides several tools for automation:

- SQL Server Agent
- Maintenance Plans
- T-SQL Scripts
- PowerShell (Advanced)
- Windows Task Scheduler (SQL Express)

Automation helps ensure that critical maintenance tasks run consistently and on schedule.

---

# Why Automate Maintenance?

Automated maintenance provides:

- Consistent database health
- Reduced manual work
- Better performance
- Improved reliability
- Faster disaster recovery
- Reduced human error

---

# Typical Automated Maintenance Workflow

```text
SQL Server Agent

        │

        ▼

Full Backup

        │

        ▼

DBCC CHECKDB

        │

        ▼

Index Maintenance

        │

        ▼

Update Statistics

        │

        ▼

Cleanup Backup Files

        │

        ▼

Send Notification

        │

        ▼

Maintenance Complete
```

---

# Recommended Maintenance Schedule

| Task | Frequency |
|--------|-----------|
| Full Backup | Weekly |
| Differential Backup | Daily |
| Transaction Log Backup | Every 15–30 Minutes |
| DBCC CHECKDB | Weekly |
| Index Reorganize | Weekly |
| Index Rebuild | Monthly or as Needed |
| Update Statistics | Weekly |
| Cleanup Backup Files | Daily |

---

# Script 1 – Full Database Backup

```sql
BACKUP DATABASE ParkingDB
TO DISK = 'D:\SQLBackups\ParkingDB_FULL.bak'
WITH
FORMAT,
INIT,
COMPRESSION,
STATS = 10;
```

---

# Script 2 – Differential Backup

```sql
BACKUP DATABASE ParkingDB
TO DISK = 'D:\SQLBackups\ParkingDB_DIFF.bak'
WITH
DIFFERENTIAL,
COMPRESSION,
STATS = 10;
```

---

# Script 3 – Transaction Log Backup

```sql
BACKUP LOG ParkingDB
TO DISK = 'D:\SQLBackups\ParkingDB_LOG.trn'
WITH
COMPRESSION,
STATS = 10;
```

---

# Script 4 – Database Integrity Check

```sql
DBCC CHECKDB
(
'ParkingDB'
)
WITH NO_INFOMSGS;
```

---

# Script 5 – Update Statistics

```sql
EXEC sp_updatestats;
```

---

# Script 6 – Rebuild All Indexes

```sql
EXEC sp_MSforeachtable
'ALTER INDEX ALL ON ? REBUILD';
```

> **Note:** `sp_MSforeachtable` is an undocumented stored procedure. It is convenient for learning and small environments but is **not recommended for production automation**. In production, loop through tables using supported catalog views.

---

# Script 7 – Reorganize Indexes

```sql
EXEC sp_MSforeachtable
'ALTER INDEX ALL ON ? REORGANIZE';
```

---

# Script 8 – Shrink Log File (Emergency Only)

```sql
DBCC SHRINKFILE
(
ParkingDB_Log,
1024
);
```

⚠ **Warning**

Do **NOT** schedule this as routine maintenance.

Use only when:

- Transaction log has grown unexpectedly
- Disk space is critically low
- After resolving the cause of excessive log growth

---

# Script 9 – Backup Verification

```sql
RESTORE VERIFYONLY
FROM DISK='D:\SQLBackups\ParkingDB_FULL.bak';
```

Verifies that the backup file is readable.

---

# Script 10 – Database Size Report

```sql
EXEC sp_spaceused;
```

---

# Script 11 – Check Index Fragmentation

```sql
SELECT
OBJECT_NAME(object_id) AS TableName,
index_id,
avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats
(
DB_ID(),
NULL,
NULL,
NULL,
'LIMITED'
)
ORDER BY avg_fragmentation_in_percent DESC;
```

---

# Script 12 – Check Statistics Age

```sql
SELECT
OBJECT_NAME(object_id) AS TableName,
name,
STATS_DATE(object_id, stats_id) AS LastUpdated
FROM sys.stats;
```

---

# Script 13 – Failed SQL Agent Jobs

```sql
EXEC msdb.dbo.sp_help_job;
```

Review job history in SQL Server Management Studio for execution status and errors.

---

# Script 14 – Active Sessions

```sql
EXEC sp_who2;
```

---

# Script 15 – Long Running Queries

```sql
SELECT
session_id,
status,
command,
cpu_time,
total_elapsed_time
FROM sys.dm_exec_requests
ORDER BY total_elapsed_time DESC;
```

---

# Script 16 – Disk Space Report

```sql
EXEC xp_fixeddrives;
```

Displays available free space on local drives.

---

# Sample Weekly Maintenance Job

```text
Sunday

01:00 AM

↓

Full Backup

↓

DBCC CHECKDB

↓

Rebuild Indexes

↓

Update Statistics

↓

Backup Verification

↓

Cleanup Old Backups

↓

Complete
```

---

# Sample Daily Maintenance Job

```text
01:00 AM

↓

Differential Backup

↓

Reorganize Indexes

↓

Update Statistics

↓

Database Health Check
```

---

# Sample 15-Minute Maintenance Job

```text
Transaction Log Backup

↓

Verify Success

↓

Log Completion
```

---

# Creating SQL Server Agent Jobs

Using SSMS

```text
SQL Server Agent

↓

Jobs

↓

New Job

↓

Steps

↓

Schedule

↓

Save
```

---

# SQL Server Express

SQL Server Express does **not** include SQL Server Agent.

Alternative options:

- Windows Task Scheduler
- PowerShell
- Batch (.bat) scripts
- SQLCMD

---

# Best Practices

- Test scripts in a development environment before production.
- Verify backups using `RESTORE VERIFYONLY`.
- Monitor SQL Server Agent job history.
- Schedule maintenance during low-usage periods.
- Monitor transaction log growth.
- Keep backup retention policies in place.
- Document all maintenance schedules.

---

# Common Mistakes

❌ Shrinking databases or log files regularly.

❌ Running index rebuilds every day.

❌ Ignoring failed SQL Server Agent jobs.

❌ Never testing backups.

❌ Running maintenance during business hours.

❌ Forgetting Transaction Log Backups in Full Recovery Model.

---

# Real-World Example

## Parking Management System

### Environment

- SQL Server 2019
- 180 GB Database
- 24/7 Parking Operations

Automation Schedule

| Time | Task |
|------|------|
| Every Sunday 1:00 AM | Full Backup |
| Every Day 1:00 AM | Differential Backup |
| Every 15 Minutes | Transaction Log Backup |
| Saturday 11:00 PM | DBCC CHECKDB |
| Sunday 2:00 AM | Rebuild Fragmented Indexes |
| Sunday 3:00 AM | Update Statistics |
| Daily 4:00 AM | Cleanup Old Backups |

Benefits

- Reduced manual administration
- Consistent maintenance
- Improved query performance
- Faster recovery during incidents
- Increased system reliability

---

# Maintenance Checklist

Daily

- [ ] Verify backups completed successfully
- [ ] Check SQL Server Agent jobs
- [ ] Monitor disk space
- [ ] Review SQL Server Error Log

Weekly

- [ ] Run DBCC CHECKDB
- [ ] Review index fragmentation
- [ ] Update statistics
- [ ] Verify backup integrity

Monthly

- [ ] Test restore procedure
- [ ] Review maintenance schedules
- [ ] Remove obsolete backup files
- [ ] Review SQL Server performance

---

# Related Documentation

- SQL Server Maintenance Plan
- SQL Server Backup Types
- Restore Operations
- DBCC CHECKDB
- Rebuild Index
- Reorganize Index
- Update Statistics
- SQL Server Agent
- Performance Tuning Tutorial
- Query Store

---

# Summary

| Maintenance Task | Automation Method |
|------------------|-------------------|
| Full Backup | SQL Server Agent |
| Differential Backup | SQL Server Agent |
| Transaction Log Backup | SQL Server Agent |
| DBCC CHECKDB | SQL Server Agent |
| Index Maintenance | SQL Server Agent / T-SQL |
| Update Statistics | SQL Server Agent / T-SQL |
| Cleanup Backups | Maintenance Cleanup Task |
| Monitoring | SQL Server Agent |

---

# Enterprise Maintenance Flow

```text
SQL Server Agent
        │
        ▼
Full Backup
        │
        ▼
DBCC CHECKDB
        │
        ▼
Check Fragmentation
        │
   ┌────┴────┐
   │         │
5–30%      >30%
   │         │
   ▼         ▼
Reorganize Rebuild
      │        │
      └───┬────┘
          ▼
Update Statistics
          │
          ▼
Verify Backup
          │
          ▼
Cleanup Old Files
          │
          ▼
Generate Maintenance Report
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
