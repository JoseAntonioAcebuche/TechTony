# 📊 SQL Server Update Statistics Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to update SQL Server statistics to ensure the Query Optimizer has accurate information about data distribution, resulting in better execution plans and improved query performance.

---

# 📖 Overview

**Statistics** are metadata that describe the distribution of data within database tables and indexes.

The **SQL Server Query Optimizer** uses statistics to estimate:

- Number of rows
- Data distribution
- Selectivity
- Query cost
- Join methods
- Index selection

As data changes over time, statistics become outdated. Updating them helps SQL Server choose more efficient execution plans.

---

# Why Update Statistics?

Updating statistics can:

- Improve query performance
- Improve row estimates
- Reduce unnecessary table scans
- Improve join selection
- Reduce CPU usage
- Improve execution plans
- Reduce logical reads

---

# How Statistics Work

```text
Table Data

      │

      ▼

Statistics

      │

      ▼

Query Optimizer

      │

      ▼

Execution Plan
```

If statistics are stale, SQL Server may choose inefficient execution plans.

---

# When Should You Update Statistics?

Consider updating statistics:

- After large data imports
- After bulk INSERT operations
- After mass UPDATE operations
- After DELETE operations
- After index maintenance
- When query performance suddenly degrades
- During scheduled maintenance

---

# Automatic Statistics

SQL Server can automatically:

- Create statistics
- Update statistics

Verify settings:

```sql
SELECT
name,
is_auto_create_stats_on,
is_auto_update_stats_on
FROM sys.databases;
```

---

# Update Statistics for a Single Table

```sql
UPDATE STATISTICS dbo.Customers;
```

This updates all statistics associated with the table.

---

# Update a Specific Statistic

```sql
UPDATE STATISTICS
dbo.Customers
IX_LastName;
```

---

# Update All Statistics in the Database

```sql
EXEC sp_updatestats;
```

This updates statistics that SQL Server determines require refreshing.

---

# Update Statistics with FULLSCAN

```sql
UPDATE STATISTICS dbo.Customers
WITH FULLSCAN;
```

FULLSCAN reads every row in the table.

Advantages:

- Highest accuracy
- Better row estimates
- Better execution plans

Disadvantages:

- Longer execution time
- Higher CPU usage
- Higher Disk I/O

---

# Update Statistics with SAMPLE

Example

```sql
UPDATE STATISTICS dbo.Customers
WITH SAMPLE 50 PERCENT;
```

Only a portion of the table is scanned.

Advantages:

- Faster
- Less resource usage

Disadvantages:

- Less accurate than FULLSCAN

---

# Update Statistics with RESAMPLE

```sql
UPDATE STATISTICS dbo.Customers
WITH RESAMPLE;
```

Uses the same sampling rate as the previous update.

---

# View Statistics Information

```sql
DBCC SHOW_STATISTICS
(
'dbo.Customers',
'IX_LastName'
);
```

Displays:

- Header
- Density Vector
- Histogram

---

# Check Statistics Last Updated

```sql
SELECT
OBJECT_NAME(object_id) AS TableName,
name,
STATS_DATE(object_id, stats_id) AS LastUpdated
FROM sys.stats
ORDER BY LastUpdated;
```

---

# Check Auto-Created Statistics

```sql
SELECT
name,
auto_created,
user_created
FROM sys.stats;
```

---

# Statistics Update Workflow

```text
Data Changes

      │

      ▼

Statistics Become Outdated

      │

      ▼

UPDATE STATISTICS

      │

      ▼

Query Optimizer

      │

      ▼

New Execution Plan

      │

      ▼

Improved Performance
```

---

# Statistics and Index Maintenance

| Operation | Updates Statistics |
|-----------|:------------------:|
| Rebuild Index | ✅ Yes |
| Reorganize Index | ❌ No |
| UPDATE STATISTICS | ✅ Yes |
| sp_updatestats | ✅ Yes |

If you **reorganize** indexes, update statistics afterward.

---

# FULLSCAN vs SAMPLE

| Option | Accuracy | Speed | Resource Usage |
|---------|:--------:|:-----:|:--------------:|
| FULLSCAN | ⭐⭐⭐⭐⭐ | ⭐⭐ | High |
| SAMPLE | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Low |
| RESAMPLE | ⭐⭐⭐⭐ | ⭐⭐⭐ | Medium |

---

# Performance Considerations

Updating statistics may increase:

- CPU usage
- Disk I/O
- Memory usage

Schedule large statistics updates during maintenance windows whenever possible.

---

# Best Practices

- Keep AUTO_CREATE_STATISTICS enabled.
- Keep AUTO_UPDATE_STATISTICS enabled.
- Update statistics after large data modifications.
- Run `sp_updatestats` during regular maintenance.
- Use `FULLSCAN` for critical tables when maximum accuracy is required.
- Review execution plans after updating statistics.

---

# Common Mistakes

❌ Never updating statistics.

❌ Running FULLSCAN on very large databases during business hours.

❌ Assuming Reorganize updates statistics.

❌ Ignoring outdated statistics after bulk imports.

❌ Disabling automatic statistics without a maintenance strategy.

---

# Real-World Example

## Parking Management System

### Problem

Searching by **Plate Number** became noticeably slower after importing millions of parking transaction records.

Investigation

- Execution Plan showed a **Table Scan**.
- Indexes existed.
- Statistics had not been updated for several months.

Action

```sql
UPDATE STATISTICS
dbo.ParkingTransaction
WITH FULLSCAN;
```

Result

- Query Optimizer recalculated row estimates.
- Execution Plan changed from:

```text
Table Scan
```

to

```text
Index Seek
```

Performance improved:

| Before | After |
|---------|-------|
| 5.2 seconds | 0.03 seconds |
| High CPU | Low CPU |
| Table Scan | Index Seek |

---

# Maintenance Checklist

Daily

- Monitor slow queries.
- Review execution plans.

Weekly

- Execute:

```sql
EXEC sp_updatestats;
```

- Review statistics age.

Monthly

- Perform FULLSCAN on critical tables if appropriate.
- Validate execution plans.
- Review index fragmentation.

---

# Related Documentation

- Statistics Guide
- Execution Plans
- Query Optimization
- SQL Server Indexing Guide
- Rebuild Index
- Reorganize Index
- Performance Tuning Tutorial
- Maintenance Plan
- Query Store

---

# Summary

| Method | Scope | Recommended Use |
|---------|-------|-----------------|
| UPDATE STATISTICS Table | Single Table | Routine maintenance |
| UPDATE STATISTICS Statistic | Single Statistic | Targeted updates |
| sp_updatestats | Entire Database | Regular maintenance |
| FULLSCAN | Maximum Accuracy | Critical tables |
| SAMPLE | Faster Updates | Large tables |
| RESAMPLE | Previous Sampling Rate | Consistent maintenance |

---

# Statistics Maintenance Flow

```text
Large Data Changes
        │
        ▼
Check Statistics Age
        │
        ▼
Update Statistics
        │
        ▼
Review Execution Plan
        │
        ▼
Validate Performance
        │
        ▼
Resume Normal Operations
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
