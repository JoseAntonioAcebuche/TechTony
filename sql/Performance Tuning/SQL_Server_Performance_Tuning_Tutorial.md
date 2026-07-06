# SQL Server Performance Tuning Tutorial

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to monitor, analyze, troubleshoot, and optimize SQL Server performance using industry best practices and built-in tools.

---

# Chapter 1 – Introduction

## What is Performance Tuning?

Performance tuning is the process of improving SQL Server efficiency by reducing query execution time, minimizing CPU, memory, and disk usage, and optimizing database performance.

## Objectives

- Improve query performance
- Reduce CPU utilization
- Reduce Disk I/O
- Optimize memory usage
- Improve application response time

---

# Chapter 2 – Performance Monitoring Tools

## SQL Server Management Studio

- Activity Monitor
- Object Explorer
- Standard Reports

## Dynamic Management Views (DMVs)

```sql
SELECT * FROM sys.dm_exec_requests;
SELECT * FROM sys.dm_exec_sessions;
SELECT * FROM sys.dm_os_wait_stats;
SELECT * FROM sys.dm_exec_query_stats;
```

## Query Store

Track slow queries and compare execution plans.

---

# Chapter 3 – Execution Plans

Learn to identify:

- Table Scan
- Index Scan
- Index Seek
- Key Lookup
- Nested Loop
- Merge Join
- Hash Match

Enable Actual Execution Plan:

Ctrl + M

---

# Chapter 4 – Query Optimization

Avoid:

```sql
SELECT *
FROM Sales;
```

Prefer:

```sql
SELECT OrderID, CustomerID
FROM Sales
WHERE OrderID = 1001;
```

Topics:

- WHERE clause
- JOIN optimization
- EXISTS vs IN
- UNION vs UNION ALL
- TOP and OFFSET/FETCH
- SARGable queries
- Parameter sniffing

---

# Chapter 5 – Indexing

Topics:

- Clustered Index
- Nonclustered Index
- Composite Index
- Covering Index
- Filtered Index
- Columnstore Index

Check missing indexes:

```sql
SELECT *
FROM sys.dm_db_missing_index_details;
```

---

# Chapter 6 – Index Maintenance

Check fragmentation:

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

Reorganize:

```sql
ALTER INDEX ALL
ON dbo.Customers
REORGANIZE;
```

Rebuild:

```sql
ALTER INDEX ALL
ON dbo.Customers
REBUILD;
```

---

# Chapter 7 – Statistics

Update statistics:

```sql
UPDATE STATISTICS dbo.Customers;
```

Topics:

- Auto Update Statistics
- Manual Updates
- Query Optimizer

---

# Chapter 8 – Wait Statistics

Common waits:

- CXPACKET
- PAGEIOLATCH
- LCK_M_X
- SOS_SCHEDULER_YIELD
- ASYNC_NETWORK_IO

---

# Chapter 9 – Blocking and Deadlocks

Useful commands:

```sql
EXEC sp_who2;
```

```sql
SELECT *
FROM sys.dm_exec_requests;
```

Topics:

- Blocking Sessions
- Deadlock Detection
- Deadlock Prevention

---

# Chapter 10 – TempDB

Topics:

- TempDB configuration
- Multiple data files
- Autogrowth
- Best practices

---

# Chapter 11 – Memory Performance

Topics:

- Buffer Pool
- Page Life Expectancy
- Memory Grants
- Lazy Writer
- Checkpoints

---

# Chapter 12 – Disk Performance

Useful DMV:

```sql
SELECT *
FROM sys.dm_io_virtual_file_stats(NULL,NULL);
```

Topics:

- Disk latency
- Read/Write performance
- Storage best practices

---

# Chapter 13 – Query Store

- Enable Query Store
- Analyze slow queries
- Compare execution plans
- Force execution plans

---

# Chapter 14 – Troubleshooting Playbook

Checklist:

- CPU
- Memory
- Disk
- Blocking
- Wait Statistics
- Execution Plans
- Missing Indexes

---

# Chapter 15 – Real-World Scenario

Parking System Example:

1. Users report slow POS transactions.
2. Review Activity Monitor.
3. Identify slow query.
4. Analyze execution plan.
5. Create missing index.
6. Update statistics.
7. Verify improved performance.

---

# Chapter 16 – Performance Tuning Checklist

## Daily

- Review SQL Agent Jobs
- Monitor blocking
- Check SQL Server logs

## Weekly

- Update statistics
- Rebuild/Reorganize indexes
- Review top queries

## Monthly

- Run DBCC CHECKDB
- Capacity planning
- Review wait statistics
- Monitor disk usage

---

# Chapter 17 – Useful Scripts

- Top CPU-consuming queries
- Long-running queries
- Missing indexes
- Unused indexes
- Fragmented indexes
- Blocking sessions
- Deadlocks
- TempDB usage
- Database growth
- File growth
- Memory usage
- Wait statistics

---

**Documentation by:** Jose Antonio "Tony" Acebuche
