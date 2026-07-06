# 📊 SQL Server Activity Monitor Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to use SQL Server Activity Monitor to monitor database performance, identify bottlenecks, troubleshoot blocking, analyze expensive queries, and monitor system resource usage in real time.

---

# 📖 Overview

**Activity Monitor** is a built-in graphical monitoring tool in **SQL Server Management Studio (SSMS)**.

It provides real-time information about SQL Server performance, including:

- CPU Usage
- Disk I/O
- Active Sessions
- Expensive Queries
- Waiting Tasks
- Database Activity
- Blocking Sessions

Activity Monitor is often the first tool a SQL Server Administrator uses when users report that the database is slow.

---

# Why Use Activity Monitor?

Activity Monitor helps administrators:

- Detect slow queries
- Identify blocking sessions
- Monitor CPU usage
- Monitor Disk I/O
- Identify expensive queries
- Monitor active users
- Troubleshoot database performance
- Detect resource bottlenecks

---

# Opening Activity Monitor

Using SQL Server Management Studio (SSMS):

```text
Object Explorer

↓

Right Click SQL Server Instance

↓

Activity Monitor
```

Shortcut

```
Ctrl + Alt + A
```

---

# Activity Monitor Components

Activity Monitor contains five major sections:

```text
Activity Monitor

│

├── Overview

├── Processes

├── Resource Waits

├── Data File I/O

└── Recent Expensive Queries
```

---

# 1. Overview

The Overview panel displays overall SQL Server health.

Shows:

- CPU %
- Waiting Tasks
- Database I/O
- Batch Requests/sec

Useful for quickly determining whether SQL Server is under heavy load.

---

# CPU

High CPU usage may indicate:

- Missing indexes
- Poor execution plans
- Large table scans
- Expensive queries

Recommended Actions

- Review Execution Plans
- Check Query Store
- Review missing indexes

---

# Batch Requests/sec

Represents:

Number of SQL batches executed every second.

Higher values generally indicate increased workload.

---

# Waiting Tasks

Shows:

Number of worker threads waiting for resources.

Common waits include:

- PAGEIOLATCH_SH
- CXPACKET
- WRITELOG
- LCK_M_X
- RESOURCE_SEMAPHORE

---

# 2. Processes

Displays currently connected sessions.

Information includes:

- Session ID (SPID)
- Login
- Database
- Status
- CPU Time
- Reads
- Writes
- Blocking Session
- Wait Time

---

# Useful Columns

| Column | Description |
|----------|-------------|
| Session ID | SQL Server Process ID |
| Login | Connected user |
| Database | Current database |
| CPU | CPU time consumed |
| Reads | Logical reads |
| Writes | Physical writes |
| Blocked By | Blocking SPID |
| Wait Time | Current wait duration |

---

# Kill a Session

Using Activity Monitor

```text
Right Click Session

↓

Kill Process
```

Equivalent T-SQL

```sql
KILL 57;
```

Replace **57** with the target Session ID.

> ⚠ **Warning:** Terminating a session rolls back its active transaction.

---

# 3. Resource Waits

Shows cumulative wait statistics grouped by category.

Examples:

- CPU Waits
- Lock Waits
- Network Waits
- Memory Waits
- Disk I/O Waits

Useful for identifying the primary performance bottleneck.

---

# Common Resource Waits

| Wait Type | Indicates |
|------------|-----------|
| CPU | Processor bottleneck |
| Lock | Blocking or locking |
| Memory | Insufficient memory grants |
| Network | Slow client/network |
| Disk I/O | Storage latency |

---

# 4. Data File I/O

Displays performance statistics for database files.

Shows:

- Database Name
- File Name
- Read Operations
- Write Operations
- Read Latency
- Write Latency

---

# High Disk Latency

Possible Causes

- Slow storage
- Heavy workload
- Large scans
- Backup operations

Recommended Actions

- Optimize queries
- Add indexes
- Improve storage performance

---

# 5. Recent Expensive Queries

Displays queries consuming the most resources.

Shows:

- CPU Time
- Logical Reads
- Physical Reads
- Duration
- Execution Count
- Execution Plan

This is one of the most valuable sections for performance tuning.

---

# Investigating an Expensive Query

Steps

```text
Recent Expensive Queries

↓

Select Query

↓

View Execution Plan

↓

Identify

• Table Scan
• Index Scan
• Missing Index
• Key Lookup

↓

Optimize Query
```

---

# Monitoring Blocking

Symptoms

- Users report freezing or slow transactions.
- Sessions remain in a waiting state.

Check:

```text
Processes

↓

Blocked By
```

Or use:

```sql
EXEC sp_who2;
```

---

# Monitoring Active Transactions

```sql
DBCC OPENTRAN;
```

Shows the oldest active transaction in the current database.

---

# Activity Monitor vs DMVs

| Tool | Purpose |
|------|----------|
| Activity Monitor | Real-time graphical monitoring |
| DMVs | Detailed diagnostics using T-SQL |
| Query Store | Historical query performance |
| Extended Events | Advanced troubleshooting |

---

# Best Practices

- Monitor Activity Monitor during reported issues.
- Focus on Recent Expensive Queries.
- Review blocking sessions before terminating processes.
- Correlate findings with Query Store and Execution Plans.
- Investigate high wait statistics.
- Monitor Data File I/O regularly.
- Use DMVs for detailed analysis.

---

# Common Mistakes

❌ Killing sessions without identifying the root cause.

❌ Ignoring execution plans.

❌ Assuming high CPU always means hardware issues.

❌ Ignoring blocking sessions.

❌ Monitoring only CPU and overlooking Disk I/O or Memory waits.

---

# Real-World Example

## Parking Management System

### Problem

Cashiers reported that ticket searches became slow during peak hours.

Investigation

1. Opened Activity Monitor.
2. Checked **Recent Expensive Queries**.
3. Found a query performing a **Table Scan** on the `ParkingTransaction` table.
4. Opened the Execution Plan.
5. Discovered no index on **TicketNumber**.

Solution

```sql
CREATE NONCLUSTERED INDEX IX_TicketNumber
ON ParkingTransaction(TicketNumber);
```

Result

- Query execution improved from **5.8 seconds** to **0.03 seconds**.
- CPU utilization decreased.
- Disk reads were significantly reduced.
- Cashier response time improved.

---

# Daily Monitoring Checklist

- [ ] Review CPU usage
- [ ] Check Waiting Tasks
- [ ] Review Recent Expensive Queries
- [ ] Monitor blocking sessions
- [ ] Review Data File I/O
- [ ] Verify SQL Server responsiveness

---

# Weekly Monitoring Checklist

- [ ] Review execution plans
- [ ] Review Query Store
- [ ] Check index fragmentation
- [ ] Update statistics if required
- [ ] Review SQL Server Error Logs

---

# Related Documentation

- Performance Tuning Tutorial
- Query Store
- Execution Plans
- Wait Statistics
- SQL Server DMVs
- Query Optimization
- SQL Server Indexing Guide
- Blocking and Deadlocks
- TempDB Optimization

---

# Summary

| Activity Monitor Section | Purpose |
|--------------------------|----------|
| Overview | Overall SQL Server health |
| Processes | Active user sessions |
| Resource Waits | Performance bottlenecks |
| Data File I/O | Storage performance |
| Recent Expensive Queries | Identify slow queries |

---

# Activity Monitor Troubleshooting Flow

```text
User Reports Slow Performance
            │
            ▼
Open Activity Monitor
            │
            ▼
Review Overview
            │
            ▼
Check Recent Expensive Queries
            │
            ▼
Review Execution Plan
            │
            ▼
Identify Root Cause
     │
 ┌───┼───────────────┐
 ▼   ▼               ▼
CPU Disk I/O     Blocking
 │    │               │
 ▼    ▼               ▼
Tune Add Index   Resolve Locks
Query Improve
Storage
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
