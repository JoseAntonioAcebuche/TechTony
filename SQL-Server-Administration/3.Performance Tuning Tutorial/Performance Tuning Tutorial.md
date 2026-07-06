# 🚀 SQL Server Performance Tuning Tutorial

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to monitor, analyze, troubleshoot, and optimize SQL Server performance using built-in tools, Dynamic Management Views (DMVs), indexing strategies, and query optimization techniques.

---

# 📖 Overview

SQL Server Performance Tuning is the process of identifying and eliminating performance bottlenecks to improve query execution, reduce resource consumption, and maximize database efficiency.

Performance tuning focuses on optimizing:

- CPU Usage
- Memory Usage
- Disk I/O
- Query Execution
- Indexes
- Statistics
- Blocking
- Deadlocks
- TempDB
- Wait Statistics

---

# Performance Tuning Workflow

```text
User Reports Slow Application
            │
            ▼
Verify SQL Server Health
            │
            ▼
Check CPU / Memory / Disk
            │
            ▼
Identify Slow Queries
            │
            ▼
Analyze Execution Plan
            │
            ▼
Check Missing Indexes
            │
            ▼
Update Statistics
            │
            ▼
Rebuild/Reorganize Indexes
            │
            ▼
Validate Performance Improvement
```

---

# Chapter 1 – Performance Monitoring Tools

## 1. Activity Monitor

Location

```text
SSMS
↓

Management

↓

Activity Monitor
```

Displays

- CPU Usage
- Waiting Tasks
- Active Sessions
- Recent Expensive Queries
- Resource Waits

---

## 2. Dynamic Management Views (DMVs)

### Current Running Requests

```sql
SELECT *
FROM sys.dm_exec_requests;
```

---

### Active Sessions

```sql
SELECT *
FROM sys.dm_exec_sessions;
```

---

### Connections

```sql
SELECT *
FROM sys.dm_exec_connections;
```

---

### Query Statistics

```sql
SELECT *
FROM sys.dm_exec_query_stats;
```

---

## 3. Query Store

Available in SQL Server 2016 and later.

Benefits:

- Identify slow queries
- Compare execution plans
- Detect performance regressions
- Force efficient execution plans

---

# Chapter 2 – Understanding Execution Plans

Execution Plans show how SQL Server executes a query.

Enable Actual Execution Plan:

```text
Ctrl + M
```

Common Operators:

| Operator | Description |
|----------|-------------|
| Index Seek | Efficient index lookup |
| Index Scan | Reads an entire index |
| Table Scan | Reads the whole table |
| Key Lookup | Retrieves additional columns |
| Nested Loop | Efficient join for small datasets |
| Merge Join | Sorted data join |
| Hash Match | Used for large datasets |

---

# Chapter 3 – Query Optimization

## Avoid SELECT *

❌ Bad

```sql
SELECT *
FROM Customers;
```

✅ Good

```sql
SELECT CustomerID, CustomerName
FROM Customers;
```

---

## Use WHERE Clause

```sql
SELECT *
FROM Customers
WHERE CustomerID = 1001;
```

---

## Avoid Functions in WHERE

❌ Bad

```sql
WHERE YEAR(OrderDate)=2025
```

✅ Good

```sql
WHERE OrderDate >= '2025-01-01'
AND OrderDate < '2026-01-01'
```

---

## Use Proper JOINs

Ensure join columns are indexed.

---

## Use EXISTS Instead of IN (when appropriate)

```sql
SELECT *
FROM Customers c
WHERE EXISTS
(
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
```

---

# Chapter 4 – Index Optimization

## Check Missing Indexes

```sql
SELECT *
FROM sys.dm_db_missing_index_details;
```

---

## Check Fragmentation

```sql
SELECT *
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

## Reorganize Index

Recommended for **5–30% fragmentation**

```sql
ALTER INDEX ALL
ON dbo.Customers
REORGANIZE;
```

---

## Rebuild Index

Recommended for **greater than 30% fragmentation**

```sql
ALTER INDEX ALL
ON dbo.Customers
REBUILD;
```

---

# Chapter 5 – Statistics

Statistics help SQL Server choose the most efficient execution plan.

Update Statistics

```sql
UPDATE STATISTICS dbo.Customers;
```

Or

```sql
EXEC sp_updatestats;
```

---

# Chapter 6 – Wait Statistics

View wait statistics

```sql
SELECT *
FROM sys.dm_os_wait_stats;
```

Common Wait Types

| Wait | Meaning |
|-------|----------|
| PAGEIOLATCH | Disk I/O bottleneck |
| CXPACKET | Parallelism |
| LCK_M_X | Blocking |
| SOS_SCHEDULER_YIELD | CPU pressure |
| ASYNC_NETWORK_IO | Slow client response |

---

# Chapter 7 – Blocking & Deadlocks

Check Blocking

```sql
EXEC sp_who2;
```

or

```sql
SELECT *
FROM sys.dm_exec_requests;
```

Monitor

- Blocking Session
- Wait Type
- Wait Time
- SQL Statement

---

# Chapter 8 – TempDB Optimization

Best Practices

- Use multiple TempDB data files
- Place TempDB on fast storage (SSD)
- Configure fixed autogrowth
- Monitor TempDB usage

---

# Chapter 9 – Memory Performance

Monitor

- Buffer Pool
- Page Life Expectancy (PLE)
- Memory Grants
- Lazy Writer
- Checkpoints

---

# Chapter 10 – Disk Performance

Monitor disk latency

```sql
SELECT *
FROM sys.dm_io_virtual_file_stats(NULL,NULL);
```

Check

- Read Latency
- Write Latency
- File Growth
- Storage Health

---

# Chapter 11 – Performance Troubleshooting

## Scenario

Users report slow POS transactions.

### Step 1

Check Activity Monitor.

### Step 2

Identify expensive queries.

### Step 3

Review Execution Plan.

### Step 4

Check missing indexes.

### Step 5

Update statistics.

### Step 6

Rebuild indexes if fragmented.

### Step 7

Retest application performance.

---

# Performance Tuning Checklist

## Daily

- Monitor SQL Server health
- Review failed SQL Agent Jobs
- Monitor blocking
- Review Error Logs

---

## Weekly

- Update Statistics
- Reorganize/Rebuild Indexes
- Review Query Store
- Check Wait Statistics

---

## Monthly

- Run DBCC CHECKDB
- Review database growth
- Capacity planning
- Remove unused indexes

---

# Common Mistakes

❌ Running SHRINK DATABASE regularly.

❌ Over-indexing tables.

❌ Ignoring execution plans.

❌ Using SELECT * in production queries.

❌ Never updating statistics.

❌ Running maintenance during business hours.

---

# Best Practices

- Keep statistics updated.
- Monitor execution plans.
- Create indexes based on workload.
- Remove unused indexes.
- Schedule maintenance during off-peak hours.
- Monitor Query Store regularly.
- Test performance changes before production deployment.

---

# Related Documentation

- Recovery Models
- Database States
- DBCC CHECKDB
- SQL Server Indexing Guide
- Query Optimization
- Backup & Restore Operations
- Maintenance Plan

---

**Documentation by:**  
**Jose Antonio "Tony" Acebuche**
