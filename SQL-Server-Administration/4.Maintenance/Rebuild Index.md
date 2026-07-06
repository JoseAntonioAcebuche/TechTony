# 🔧 SQL Server Rebuild Index Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn when, why, and how to rebuild SQL Server indexes to reduce fragmentation and improve database performance.

---

# 📖 Overview

Indexes become fragmented over time as data is inserted, updated, and deleted.

**Index Rebuild** recreates the entire index, removes fragmentation, updates index pages, and generates new statistics.

It is one of the most important maintenance tasks for SQL Server performance.

---

# What is Index Fragmentation?

Fragmentation occurs when index pages become disorganized.

Example

Before Fragmentation

```text
Page 1

↓

Page 2

↓

Page 3

↓

Page 4
```

After Multiple Inserts and Deletes

```text
Page 1

↓

Page 7

↓

Page 2

↓

Page 10

↓

Page 4
```

SQL Server performs more disk reads because pages are no longer in logical order.

---

# Why Rebuild an Index?

Benefits

- Removes fragmentation
- Improves Index Seek performance
- Reduces Disk I/O
- Improves query execution time
- Updates index statistics
- Reclaims unused index pages

---

# Rebuild vs Reorganize

| Feature | Rebuild | Reorganize |
|----------|:-------:|:----------:|
| Removes Fragmentation | ✅ Complete | ✅ Partial |
| Updates Statistics | ✅ Yes | ❌ No |
| Uses More Resources | ✅ | ❌ |
| Online Option Available | Enterprise Edition (or editions/features that support online operations) | ✅ Yes |
| Speed | Faster overall but more resource-intensive | Slower but lightweight |

---

# When Should You Rebuild?

Microsoft's commonly used guideline:

| Fragmentation | Action |
|--------------|--------|
| 0–5% | No Action |
| 5–30% | Reorganize |
| Greater than 30% | Rebuild |

---

# Check Fragmentation

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

# Rebuild All Indexes

```sql
ALTER INDEX ALL
ON dbo.Customers
REBUILD;
```

---

# Rebuild a Specific Index

```sql
ALTER INDEX IX_LastName
ON dbo.Customers
REBUILD;
```

---

# Rebuild with FILLFACTOR

Example

```sql
ALTER INDEX IX_LastName
ON dbo.Customers
REBUILD
WITH
(
FILLFACTOR = 90
);
```

---

# What is FILLFACTOR?

FILLFACTOR reserves free space on index pages to reduce future page splits.

Example

100%

```text
██████████
```

90%

```text
█████████░
```

---

# Rebuild Online

If your SQL Server edition supports online index operations:

```sql
ALTER INDEX ALL
ON dbo.Customers
REBUILD
WITH
(
ONLINE = ON
);
```

Benefits

- Reduces user blocking
- Database remains available for most operations

---

# Rebuild Offline

```sql
ALTER INDEX ALL
ON dbo.Customers
REBUILD
WITH
(
ONLINE = OFF
);
```

During an offline rebuild, affected objects are unavailable until the operation completes.

---

# Rebuild Partitioned Index

```sql
ALTER INDEX IX_Sales
ON Sales
REBUILD PARTITION = 5;
```

Useful for very large databases.

---

# Update Statistics

Although rebuilding an index updates its statistics, many administrators refresh all statistics afterward.

```sql
EXEC sp_updatestats;
```

---

# Monitor Rebuild Progress

```sql
SELECT
session_id,
command,
percent_complete,
estimated_completion_time
FROM sys.dm_exec_requests
WHERE command LIKE '%INDEX%';
```

---

# Resource Usage

Index rebuild operations may consume:

- CPU
- Memory
- Disk I/O
- TempDB
- Transaction Log

Plan rebuilds during maintenance windows.

---

# Scheduling

Typical recommendation:

| Database Size | Schedule |
|---------------|----------|
| Small | Monthly |
| Medium | Monthly |
| Large | Monthly or based on fragmentation monitoring |
| Mission Critical | As required during maintenance windows |

---

# Best Practices

- Check fragmentation before rebuilding.
- Rebuild only highly fragmented indexes.
- Schedule rebuilds during low activity.
- Monitor TempDB space.
- Ensure adequate transaction log space.
- Verify backups before maintenance.
- Review execution plans after maintenance.

---

# Common Mistakes

❌ Rebuilding every index regardless of fragmentation.

❌ Running rebuilds during peak business hours.

❌ Ignoring transaction log growth.

❌ Forgetting TempDB capacity.

❌ Not checking fragmentation before maintenance.

---

# Real-World Example

## Parking Management System

### Problem

Cashiers reported slow searches for parking tickets during busy hours.

Investigation

```sql
SELECT
OBJECT_NAME(object_id),
avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats
(
DB_ID(),
NULL,
NULL,
NULL,
'LIMITED'
);
```

Result

```
IX_TicketNumber

Fragmentation

67%
```

Action

```sql
ALTER INDEX IX_TicketNumber
ON ParkingTransaction
REBUILD;
```

After Maintenance

- Fragmentation reduced to less than 1%.
- Query execution time improved from **2.4 seconds** to **0.03 seconds**.
- Disk reads decreased significantly.
- CPU utilization improved during peak hours.

---

# Maintenance Checklist

Before Rebuild

- [ ] Check fragmentation level
- [ ] Verify recent backup
- [ ] Confirm available disk space
- [ ] Check TempDB capacity
- [ ] Verify transaction log space

After Rebuild

- [ ] Validate application performance
- [ ] Review execution plans
- [ ] Check SQL Server Error Log
- [ ] Verify fragmentation reduction

---

# Related Documentation

- SQL Server Indexing Guide
- Reorganize Index
- Performance Tuning Tutorial
- Statistics Guide
- Execution Plans
- Query Optimization
- Maintenance Plan
- TempDB Optimization

---

# Summary

| Fragmentation Level | Recommended Action |
|---------------------|--------------------|
| 0–5% | No Action |
| 5–30% | Reorganize Index |
| Greater than 30% | Rebuild Index |

---

## Rebuild Workflow

```text
Check Fragmentation
        │
        ▼
Greater than 30%?
        │
   ┌────┴────┐
   │         │
  No        Yes
   │         │
   ▼         ▼
Monitor   Rebuild Index
              │
              ▼
      Update Statistics
              │
              ▼
     Validate Performance
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
