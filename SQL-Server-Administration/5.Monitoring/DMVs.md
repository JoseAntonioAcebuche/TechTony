# 📊 SQL Server Dynamic Management Views (DMVs) Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to use SQL Server Dynamic Management Views (DMVs) to monitor server health, troubleshoot performance issues, analyze queries, monitor sessions, and identify resource bottlenecks.

---

# 📖 Overview

**Dynamic Management Views (DMVs)** are built-in SQL Server system views that provide real-time information about the current state and health of SQL Server.

DMVs allow administrators to monitor:

- Active Sessions
- Running Queries
- Execution Plans
- Index Usage
- Wait Statistics
- Memory Usage
- CPU Usage
- Disk I/O
- Blocking
- Missing Indexes

DMVs are one of the most important tools used by SQL Server Database Administrators (DBAs).

---

# Why Use DMVs?

DMVs help administrators:

- Troubleshoot slow queries
- Monitor SQL Server performance
- Detect blocking sessions
- Monitor CPU and memory usage
- Analyze index usage
- Find missing indexes
- Identify expensive queries
- Monitor disk I/O
- View execution plans

---

# DMV Architecture

```text
SQL Server

        │

        ▼

Dynamic Management Views

        │

 ┌──────────────┐
 │ Sessions     │
 │ Requests     │
 │ Waits        │
 │ Memory       │
 │ CPU          │
 │ Disk I/O     │
 │ Indexes      │
 │ Execution    │
 └──────────────┘

        │

        ▼

Performance Analysis
```

---

# Common DMV Categories

| DMV Category | Purpose |
|--------------|----------|
| Sessions | Connected users |
| Requests | Running queries |
| Query Stats | Expensive queries |
| Wait Statistics | Performance bottlenecks |
| Index Usage | Index effectiveness |
| Missing Indexes | Index recommendations |
| Memory | SQL memory usage |
| Disk I/O | Storage performance |

---

# 1. Active Sessions

View current user sessions.

```sql
SELECT
session_id,
login_name,
host_name,
program_name,
status
FROM sys.dm_exec_sessions;
```

Useful for:

- Active users
- Connected applications
- Login information

---

# 2. Running Requests

View currently executing queries.

```sql
SELECT
session_id,
status,
command,
cpu_time,
total_elapsed_time,
blocking_session_id
FROM sys.dm_exec_requests;
```

Useful for:

- Long-running queries
- Blocking
- CPU usage

---

# 3. Currently Executing SQL

```sql
SELECT
r.session_id,
t.text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t;
```

Shows the SQL statement currently executing.

---

# 4. Top CPU Queries

```sql
SELECT TOP (10)

total_worker_time,
execution_count,

total_worker_time/execution_count
AS AvgCPU,

text

FROM sys.dm_exec_query_stats qs

CROSS APPLY
sys.dm_exec_sql_text(qs.sql_handle);
```

Useful for:

- High CPU queries
- Performance tuning

---

# 5. Top Long-Running Queries

```sql
SELECT TOP (10)

execution_count,

total_elapsed_time,

text

FROM sys.dm_exec_query_stats qs

CROSS APPLY
sys.dm_exec_sql_text(qs.sql_handle)

ORDER BY total_elapsed_time DESC;
```

---

# 6. Execution Plans

```sql
SELECT
query_plan
FROM sys.dm_exec_query_plan
(
0x...
);
```

Normally retrieved together with `plan_handle` from `sys.dm_exec_query_stats`.

Execution plans help identify:

- Table Scans
- Index Scans
- Missing Indexes
- Key Lookups

---

# 7. Wait Statistics

```sql
SELECT
wait_type,
waiting_tasks_count,
wait_time_ms
FROM sys.dm_os_wait_stats
ORDER BY wait_time_ms DESC;
```

Useful for identifying:

- CPU waits
- Disk waits
- Memory waits
- Lock waits

---

# 8. Blocking Sessions

```sql
SELECT
session_id,
blocking_session_id,
wait_type
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
```

---

# 9. Missing Indexes

```sql
SELECT
*
FROM
sys.dm_db_missing_index_details;
```

Review recommendations before creating indexes.

---

# 10. Index Usage

```sql
SELECT

OBJECT_NAME(object_id)
AS TableName,

user_seeks,

user_scans,

user_updates

FROM sys.dm_db_index_usage_stats;
```

Useful for identifying:

- Unused indexes
- Frequently used indexes

---

# 11. Index Fragmentation

```sql
SELECT

OBJECT_NAME(object_id),

avg_fragmentation_in_percent

FROM
sys.dm_db_index_physical_stats
(
DB_ID(),
NULL,
NULL,
NULL,
'LIMITED'
);
```

---

# 12. Memory Usage

```sql
SELECT
*
FROM
sys.dm_os_memory_clerks;
```

Useful for:

- Memory troubleshooting
- Cache usage

---

# 13. Buffer Cache

```sql
SELECT
COUNT(*) * 8 /1024
AS BufferCacheMB
FROM sys.dm_os_buffer_descriptors;
```

---

# 14. Disk I/O Statistics

```sql
SELECT
*
FROM
sys.dm_io_virtual_file_stats
(
NULL,
NULL
);
```

Shows:

- Read latency
- Write latency
- I/O operations

---

# 15. Database File Usage

```sql
SELECT
name,
size
FROM
sys.database_files;
```

---

# 16. TempDB Usage

```sql
SELECT
*
FROM
sys.dm_db_file_space_usage;
```

---

# 17. Cached Execution Plans

```sql
SELECT
*
FROM
sys.dm_exec_cached_plans;
```

Useful for:

- Plan cache analysis
- Reused execution plans

---

# 18. SQL Server Connections

```sql
SELECT
*
FROM
sys.dm_exec_connections;
```

Shows:

- Client IP
- Authentication
- Network protocol

---

# 19. Transaction Information

```sql
DBCC OPENTRAN;
```

Shows:

- Oldest active transaction
- Transaction status

---

# 20. Open Transactions

```sql
SELECT
*
FROM
sys.dm_tran_active_transactions;
```

---

# Common Troubleshooting Workflow

```text
User Reports Slow SQL

        │

        ▼

Check Active Requests

        │

        ▼

Check Wait Statistics

        │

        ▼

Review Execution Plan

        │

        ▼

Check Missing Indexes

        │

        ▼

Review Index Usage

        │

        ▼

Optimize Query
```

---

# Best Practices

- Use DMVs regularly for monitoring.
- Correlate DMV data with Query Store.
- Review execution plans.
- Check wait statistics first.
- Review missing indexes carefully.
- Monitor index usage before dropping indexes.
- Capture baseline performance metrics.

---

# Common Mistakes

❌ Creating every missing index recommendation.

❌ Ignoring execution plans.

❌ Monitoring only CPU.

❌ Never reviewing wait statistics.

❌ Ignoring blocking sessions.

---

# Real-World Example

## Parking Management System

### Problem

Cashiers reported intermittent delays when searching parking tickets.

Investigation

1. Checked active requests.

```sql
SELECT
session_id,
blocking_session_id
FROM sys.dm_exec_requests;
```

2. Found blocking sessions.

3. Reviewed execution plan.

4. Identified a missing index on `TicketNumber`.

5. Created the index.

```sql
CREATE NONCLUSTERED INDEX IX_TicketNumber
ON ParkingTransaction(TicketNumber);
```

Result

- Blocking reduced.
- Query execution improved from **5.1 seconds** to **0.02 seconds**.
- CPU usage decreased.
- User response time improved significantly.

---

# Daily DBA Checklist

- [ ] Review active sessions
- [ ] Check running requests
- [ ] Monitor wait statistics
- [ ] Review expensive queries
- [ ] Check blocking sessions
- [ ] Monitor TempDB
- [ ] Review disk I/O
- [ ] Monitor memory usage

---

# Weekly DBA Checklist

- [ ] Review missing indexes
- [ ] Check index fragmentation
- [ ] Update statistics
- [ ] Review Query Store
- [ ] Analyze execution plans

---

# Related Documentation

- Activity Monitor
- Wait Statistics
- Execution Plans
- Query Store
- Query Optimization
- Statistics Guide
- Performance Tuning Tutorial
- Rebuild Index
- Reorganize Index
- TempDB Optimization

---

# Summary

| DMV | Purpose |
|------|----------|
| sys.dm_exec_sessions | Active Sessions |
| sys.dm_exec_requests | Running Queries |
| sys.dm_exec_query_stats | Query Performance |
| sys.dm_exec_sql_text | SQL Text |
| sys.dm_exec_query_plan | Execution Plans |
| sys.dm_os_wait_stats | Wait Statistics |
| sys.dm_db_index_usage_stats | Index Usage |
| sys.dm_db_index_physical_stats | Fragmentation |
| sys.dm_db_missing_index_details | Missing Indexes |
| sys.dm_io_virtual_file_stats | Disk I/O |
| sys.dm_os_memory_clerks | Memory Usage |
| sys.dm_db_file_space_usage | TempDB Usage |
| sys.dm_exec_cached_plans | Plan Cache |
| sys.dm_exec_connections | Client Connections |
| sys.dm_tran_active_transactions | Active Transactions |

---

# Enterprise DBA Workflow

```text
User Reports Slow Database
            │
            ▼
Check Activity Monitor
            │
            ▼
Review DMVs
            │
     ┌──────┼────────────┐
     ▼      ▼            ▼
 Sessions  Waits     Requests
     │      │            │
     ▼      ▼            ▼
Blocking CPU/I/O     Slow Query
     │      │            │
     └──────┼────────────┘
            ▼
     Execution Plan
            │
            ▼
    Index / Statistics
            │
            ▼
      Optimize Query
            │
            ▼
   Validate Performance
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
