# 📊 SQL Server Statistics Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how SQL Server Statistics work, how they influence the Query Optimizer, and how to maintain them for optimal database performance.

---

# 📖 Overview

SQL Server **Statistics** are metadata that describe the distribution of values within one or more columns.

The **Query Optimizer** uses statistics to estimate:

- Number of rows
- Data distribution
- Selectivity
- Query cost
- Best execution plan

Without accurate statistics, SQL Server may choose inefficient execution plans, resulting in slow queries.

---

# Why Statistics Matter

Statistics help SQL Server decide:

- Whether to use an Index Seek
- Whether to perform a Table Scan
- Which JOIN algorithm to use
- Which index is most efficient
- Estimated query cost

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

If statistics are outdated, SQL Server may estimate the wrong number of rows and select a poor execution plan.

---

# What Information is Stored?

Statistics contain:

- Histogram
- Density Information
- Average Key Length
- Row Count
- Sample Rate
- Last Updated Date

---

# Histogram

A histogram stores information about the distribution of values in a column.

Example

```text
CustomerID

1 - 1000

██████████

1001 - 2000

████

2001 - 3000

██
```

The optimizer uses this information to estimate how many rows match a query.

---

# Automatic Statistics

SQL Server automatically creates statistics when:

```
AUTO_CREATE_STATISTICS = ON
```

Verify:

```sql
SELECT
name,
is_auto_create_stats_on
FROM sys.databases;
```

---

# Auto Update Statistics

SQL Server can automatically update outdated statistics.

Verify:

```sql
SELECT
name,
is_auto_update_stats_on
FROM sys.databases;
```

---

# View Statistics

```sql
EXEC sp_helpstats
@objname='dbo.Customers';
```

---

# Display Statistics Details

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

# Update Statistics

Update statistics for a single table.

```sql
UPDATE STATISTICS dbo.Customers;
```

---

Update all statistics in the current database.

```sql
EXEC sp_updatestats;
```

---

Update with FULLSCAN.

```sql
UPDATE STATISTICS dbo.Customers
WITH FULLSCAN;
```

FULLSCAN reads every row and produces the most accurate statistics but requires more time and I/O.

---

# Create Statistics

```sql
CREATE STATISTICS ST_LastName
ON Customers(LastName);
```

---

# Delete Statistics

```sql
DROP STATISTICS Customers.ST_LastName;
```

---

# Find Outdated Statistics

```sql
SELECT
OBJECT_NAME(object_id) AS TableName,
name,
STATS_DATE(object_id, stats_id) AS LastUpdated
FROM sys.stats
ORDER BY LastUpdated;
```

---

# Statistics Sampling

| Option | Description |
|----------|-------------|
| SAMPLE | Reads a portion of the table |
| FULLSCAN | Reads the entire table |
| RESAMPLE | Uses the previous sampling rate |

---

# Statistics and Execution Plans

Accurate statistics allow SQL Server to choose:

```
Index Seek
```

instead of

```
Table Scan
```

Poor statistics may result in:

- Incorrect row estimates
- Inefficient JOINs
- High CPU usage
- Excessive Disk I/O

---

# Statistics Maintenance

## Daily

- Monitor slow queries
- Review execution plans

---

## Weekly

```sql
EXEC sp_updatestats;
```

---

## Monthly

Review statistics age.

```sql
SELECT
name,
STATS_DATE(object_id, stats_id)
FROM sys.stats;
```

---

# Common Performance Problems

| Problem | Possible Cause | Solution |
|----------|----------------|----------|
| Table Scan | Outdated Statistics | Update Statistics |
| Index Scan | Poor Estimates | Update Statistics |
| High CPU | Incorrect Row Estimates | Refresh Statistics |
| Slow JOIN | Old Statistics | FULLSCAN |
| Bad Execution Plan | Stale Statistics | Rebuild Index + Update Statistics |

---

# Best Practices

- Keep AUTO_CREATE_STATISTICS enabled.
- Keep AUTO_UPDATE_STATISTICS enabled.
- Update statistics after large data changes.
- Use FULLSCAN for critical databases during maintenance windows.
- Review execution plans after updating statistics.
- Monitor statistics age regularly.

---

# Common Mistakes

❌ Disabling automatic statistics.

❌ Never updating statistics.

❌ Updating statistics during peak business hours.

❌ Assuming index rebuilds always eliminate the need for statistics updates.

❌ Ignoring execution plan changes after statistics updates.

---

# Real-World Example

## Parking Management System

### Problem

Cashiers reported that searching by **Ticket Number** became slower after importing several million records.

Investigation

1. Execution Plan showed a **Table Scan**.
2. Indexes existed and were healthy.
3. Statistics were several months old.

Action

```sql
UPDATE STATISTICS dbo.ParkingTransaction
WITH FULLSCAN;
```

Result

- Query Optimizer recalculated row estimates.
- Execution Plan changed from **Table Scan** to **Index Seek**.
- Search time improved from **4.5 seconds** to **0.03 seconds**.

---

# Performance Checklist

Before troubleshooting a slow query:

- [ ] Check Execution Plan
- [ ] Verify statistics are current
- [ ] Review histogram
- [ ] Check row estimates
- [ ] Update statistics if necessary
- [ ] Test query performance again

---

# Related Documentation

- Performance Tuning Tutorial
- Execution Plans
- SQL Server Indexing Guide
- Query Optimization
- Query Store
- SQL Server DMVs

---

# Summary

| Feature | Purpose |
|----------|----------|
| Histogram | Data distribution |
| Density | Value uniqueness |
| Auto Create Statistics | Automatically creates statistics |
| Auto Update Statistics | Refreshes outdated statistics |
| UPDATE STATISTICS | Manually refreshes statistics |
| FULLSCAN | Most accurate statistics |
| DBCC SHOW_STATISTICS | Displays statistics details |

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
