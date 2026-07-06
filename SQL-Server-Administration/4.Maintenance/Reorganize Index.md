# 🔄 SQL Server Reorganize Index Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to reorganize SQL Server indexes to reduce fragmentation with minimal resource usage while keeping the database online.

---

# 📖 Overview

**Index Reorganize** is an online maintenance operation that defragments the leaf-level pages of an index.

Unlike **Index Rebuild**, reorganizing an index does **not** recreate the entire index. Instead, SQL Server rearranges fragmented pages into logical order.

Reorganize operations are less resource-intensive and are ideal for lightly to moderately fragmented indexes.

---

# What is Index Fragmentation?

As records are inserted, updated, and deleted, SQL Server may store index pages out of order.

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

After Multiple Data Modifications

```text
Page 1

↓

Page 5

↓

Page 2

↓

Page 7

↓

Page 4
```

This increases disk reads and slows query performance.

---

# Why Reorganize an Index?

Benefits

- Reduces logical fragmentation
- Improves Index Seek performance
- Reduces Disk I/O
- Runs online
- Uses fewer resources than a rebuild
- Does not require large amounts of TempDB space

---

# Reorganize vs Rebuild

| Feature | Reorganize | Rebuild |
|----------|:----------:|:-------:|
| Removes Fragmentation | Partial | Complete |
| Updates Statistics | ❌ No | ✅ Yes |
| Resource Usage | Low | High |
| Online Operation | ✅ Yes | Depends on edition/features |
| Transaction Log Usage | Lower | Higher |
| Interruptible | ✅ Yes | Generally No |

---

# When Should You Reorganize?

Recommended fragmentation levels:

| Fragmentation | Action |
|---------------|--------|
| 0–5% | No Action |
| 5–30% | Reorganize |
| Greater than 30% | Rebuild |

---

# Check Index Fragmentation

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

# Reorganize All Indexes

```sql
ALTER INDEX ALL
ON dbo.Customers
REORGANIZE;
```

---

# Reorganize a Specific Index

```sql
ALTER INDEX IX_LastName
ON dbo.Customers
REORGANIZE;
```

---

# Large Object (LOB) Compaction

By default, SQL Server compacts Large Object (LOB) pages during a reorganize operation.

Enable explicitly:

```sql
ALTER INDEX ALL
ON dbo.Documents
REORGANIZE
WITH
(
LOB_COMPACTION = ON
);
```

Disable LOB compaction:

```sql
ALTER INDEX ALL
ON dbo.Documents
REORGANIZE
WITH
(
LOB_COMPACTION = OFF
);
```

---

# Monitor Fragmentation After Reorganize

```sql
SELECT
OBJECT_NAME(object_id) AS TableName,
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

---

# Update Statistics

Unlike **Index Rebuild**, reorganizing an index **does not update statistics**.

Run:

```sql
UPDATE STATISTICS dbo.Customers;
```

or

```sql
EXEC sp_updatestats;
```

after reorganizing indexes if needed.

---

# Resource Usage

Index Reorganize uses:

- Low CPU
- Low Memory
- Low Disk I/O
- Small Transaction Log
- Minimal TempDB

It is suitable for production environments because it has a lower impact than a rebuild.

---

# Scheduling

Typical recommendation:

| Database Size | Schedule |
|---------------|----------|
| Small | Weekly |
| Medium | Weekly |
| Large | Weekly |
| High Transaction Systems | Weekly or based on fragmentation monitoring |

---

# Best Practices

- Check fragmentation before reorganizing.
- Reorganize only indexes with 5–30% fragmentation.
- Update statistics after reorganizing.
- Schedule during low-activity periods.
- Monitor execution time and performance.
- Review fragmentation after completion.

---

# Common Mistakes

❌ Reorganizing heavily fragmented indexes.

❌ Assuming reorganize updates statistics.

❌ Running reorganize without checking fragmentation.

❌ Ignoring execution plans after maintenance.

❌ Never monitoring fragmentation levels.

---

# Real-World Example

## Parking Management System

### Problem

The parking transaction table experienced moderate fragmentation due to continuous ticket creation and payment processing.

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
IX_PlateNumber

Fragmentation

18%
```

Action

```sql
ALTER INDEX IX_PlateNumber
ON ParkingTransaction
REORGANIZE;
```

Then update statistics:

```sql
EXEC sp_updatestats;
```

Result

- Fragmentation reduced significantly.
- Query execution became faster.
- Minimal impact on users because the operation remained online.

---

# Maintenance Checklist

Before Reorganize

- [ ] Check fragmentation level
- [ ] Verify index usage
- [ ] Confirm maintenance window
- [ ] Review available storage

After Reorganize

- [ ] Update statistics
- [ ] Validate query performance
- [ ] Review execution plans
- [ ] Verify fragmentation reduction

---

# Choosing Between Reorganize and Rebuild

```text
Check Fragmentation
        │
        ▼
0–5%
        │
        ▼
No Action

        │

5–30%
        │
        ▼
Reorganize Index

        │

Greater than 30%
        │
        ▼
Rebuild Index
```

---

# Related Documentation

- SQL Server Indexing Guide
- Rebuild Index
- Statistics Guide
- Performance Tuning Tutorial
- Execution Plans
- Query Optimization
- Maintenance Plan

---

# Summary

| Fragmentation Level | Recommended Action |
|---------------------|--------------------|
| 0–5% | No Action |
| 5–30% | Reorganize Index |
| Greater than 30% | Rebuild Index |

---

# Reorganize Workflow

```text
Check Fragmentation
        │
        ▼
5–30%?
        │
   ┌────┴────┐
   │         │
  No        Yes
   │         │
   ▼         ▼
Evaluate   Reorganize Index
Alternative       │
                  ▼
        Update Statistics
                  │
                  ▼
        Validate Performance
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
