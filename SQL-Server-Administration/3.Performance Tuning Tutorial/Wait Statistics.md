# ⏳ SQL Server Wait Statistics Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to analyze SQL Server Wait Statistics to identify the root cause of performance bottlenecks involving CPU, memory, disk I/O, locking, networking, and parallelism.

---

# 📖 Overview

SQL Server uses **Wait Statistics** to record the amount of time worker threads spend waiting for resources before they can continue processing.

Rather than asking **"Why is SQL Server slow?"**, Wait Statistics help answer **"What is SQL Server waiting for?"**

Analyzing wait statistics is one of the fastest and most effective methods for diagnosing performance issues.

---

# Why Wait Statistics Matter

Wait Statistics help identify bottlenecks related to:

- CPU
- Memory
- Disk I/O
- Network
- Locks
- Blocking
- Parallelism
- TempDB
- Storage
- Query Execution

Instead of guessing, administrators can use wait statistics to focus on the actual performance bottleneck.

---

# How Wait Statistics Work

```text
Application

      │

      ▼

SQL Query

      │

      ▼

Needs Resource

      │

      ▼

SQL Server Waits

      │

      ▼

Resource Becomes Available

      │

      ▼

Query Continues
```

---

# Viewing Wait Statistics

View all accumulated wait statistics:

```sql
SELECT
wait_type,
waiting_tasks_count,
wait_time_ms,
max_wait_time_ms,
signal_wait_time_ms
FROM sys.dm_os_wait_stats
ORDER BY wait_time_ms DESC;
```

---

# Reset Wait Statistics

> ⚠ **Warning:** Only reset wait statistics during troubleshooting or when establishing a new performance baseline.

```sql
DBCC SQLPERF
(
'SYS.DM_OS_WAIT_STATS',
CLEAR
);
```

---

# Understanding Wait Statistics Columns

| Column | Description |
|----------|-------------|
| wait_type | Type of resource being waited on |
| waiting_tasks_count | Number of waiting requests |
| wait_time_ms | Total accumulated wait time |
| max_wait_time_ms | Longest single wait |
| signal_wait_time_ms | Time spent waiting for CPU after resource became available |

---

# Resource Wait vs Signal Wait

## Resource Wait

Waiting for:

- Disk
- Lock
- Memory
- Network
- TempDB

Example:

```
PAGEIOLATCH_SH
```

---

## Signal Wait

Waiting for CPU scheduling.

High signal waits often indicate CPU pressure.

---

# Common Wait Types

| Wait Type | Indicates |
|------------|-----------|
| PAGEIOLATCH_SH | Slow disk reads |
| PAGEIOLATCH_EX | Disk write latency |
| WRITELOG | Slow transaction log writes |
| CXPACKET | Parallel query execution |
| CXCONSUMER | Parallelism coordination |
| LCK_M_S | Shared lock waiting |
| LCK_M_X | Exclusive lock waiting |
| ASYNC_NETWORK_IO | Client/network is slow to consume results |
| SOS_SCHEDULER_YIELD | CPU pressure |
| RESOURCE_SEMAPHORE | Memory grant waiting |
| THREADPOOL | Worker thread exhaustion |
| BACKUPIO | Backup I/O operations |
| PREEMPTIVE_OS_AUTHENTICATIONOPS | Windows authentication delay |

---

# Disk I/O Waits

## PAGEIOLATCH_SH

### Meaning

Waiting for data pages to be read from disk.

### Possible Causes

- Slow storage
- Large table scans
- Missing indexes

### Possible Solutions

- Add indexes
- Improve storage performance
- Optimize queries
- Increase memory if appropriate

---

## WRITELOG

### Meaning

Waiting for transaction log writes.

### Causes

- Slow log drive
- Heavy INSERT/UPDATE workload
- Frequent commits

### Solutions

- Place log files on fast storage
- Reduce unnecessary transactions
- Optimize write-intensive operations

---

# CPU Waits

## SOS_SCHEDULER_YIELD

### Meaning

Queries voluntarily yielded CPU while waiting to be scheduled again.

### Causes

- High CPU utilization
- Expensive queries
- Missing indexes
- Inefficient execution plans

### Solutions

- Tune slow queries
- Add appropriate indexes
- Review execution plans
- Upgrade CPU resources if necessary

---

# Memory Waits

## RESOURCE_SEMAPHORE

### Meaning

Queries are waiting for memory grants.

### Causes

- Large sorts
- Hash joins
- Insufficient memory

### Solutions

- Optimize queries
- Reduce memory-intensive operations
- Increase SQL Server memory if justified

---

# Locking Waits

## LCK_M_S

Waiting for a Shared Lock.

---

## LCK_M_X

Waiting for an Exclusive Lock.

### Common Causes

- Long-running transactions
- Blocking sessions
- Poor transaction design

### Troubleshooting

```sql
EXEC sp_who2;
```

or

```sql
SELECT *
FROM sys.dm_exec_requests;
```

---

# Parallelism Waits

## CXPACKET

### Meaning

Parallel worker threads are synchronizing.

Not always a problem.

Investigate only when accompanied by poor query performance.

---

## CXCONSUMER

Usually a normal wait associated with parallel query execution in modern SQL Server versions.

---

# Network Waits

## ASYNC_NETWORK_IO

### Meaning

SQL Server is waiting for the client application to receive data.

### Possible Causes

- Slow client application
- Slow network
- Returning excessive result sets

### Solutions

- Reduce returned rows
- Avoid `SELECT *`
- Improve client-side processing

---

# Backup Waits

## BACKUPIO

Occurs during backup or restore operations.

Generally expected during maintenance windows.

---

# Finding Top Wait Types

```sql
SELECT TOP (10)
wait_type,
wait_time_ms,
waiting_tasks_count
FROM sys.dm_os_wait_stats
ORDER BY wait_time_ms DESC;
```

---

# Wait Statistics Analysis Workflow

```text
Users Report Slow Performance
          │
          ▼
Review Wait Statistics
          │
          ▼
Identify Highest Wait Type
          │
          ▼
Determine Resource Bottleneck
          │
 ┌────────┼────────┬─────────┬─────────┐
 ▼        ▼        ▼         ▼
CPU     Disk     Memory   Locking
 │        │        │         │
 ▼        ▼        ▼         ▼
Tune     Add      Optimize  Resolve
Queries  Indexes  Memory    Blocking
```

---

# Real-World Example

## Parking Management System

### Problem

Cashiers experienced slow ticket searches during peak hours.

Investigation

```sql
SELECT TOP (10)
wait_type,
wait_time_ms
FROM sys.dm_os_wait_stats
ORDER BY wait_time_ms DESC;
```

Top Wait

```
PAGEIOLATCH_SH
```

Execution Plan

```
Table Scan
```

Root Cause

No index existed on **TicketNumber**.

Solution

```sql
CREATE NONCLUSTERED INDEX IX_TicketNumber
ON ParkingTransaction(TicketNumber);
```

Result

- Wait time decreased significantly.
- Query execution changed to **Index Seek**.
- Average search time improved from **5.4 seconds** to **0.02 seconds**.

---

# Best Practices

- Establish a performance baseline.
- Monitor wait statistics regularly.
- Focus on the highest cumulative waits.
- Correlate waits with execution plans and Query Store.
- Review indexes before upgrading hardware.
- Monitor after major application deployments.
- Reset wait statistics only when beginning a controlled troubleshooting session.

---

# Common Mistakes

❌ Treating every wait type as a problem.

❌ Ignoring execution plans.

❌ Optimizing based only on wait statistics.

❌ Resetting wait statistics too frequently.

❌ Assuming CXPACKET is always a configuration issue.

---

# Performance Checklist

- [ ] Review top wait types
- [ ] Analyze execution plans
- [ ] Check missing indexes
- [ ] Verify statistics are current
- [ ] Review blocking sessions
- [ ] Check disk latency
- [ ] Review Query Store
- [ ] Monitor CPU utilization
- [ ] Validate improvements after tuning

---

# Related Documentation

- Performance Tuning Tutorial
- SQL Server DMVs
- Query Store
- Execution Plans
- Query Optimization
- SQL Server Indexing Guide
- Statistics
- Blocking and Deadlocks
- TempDB Optimization

---

# Summary

| Wait Type | Resource | Typical Resolution |
|-----------|----------|--------------------|
| PAGEIOLATCH_SH | Disk Read | Optimize queries, add indexes, improve storage |
| WRITELOG | Transaction Log | Faster storage, optimize writes |
| SOS_SCHEDULER_YIELD | CPU | Tune queries, review execution plans |
| RESOURCE_SEMAPHORE | Memory | Reduce memory grants, optimize queries |
| LCK_M_X | Locking | Resolve blocking, shorten transactions |
| LCK_M_S | Shared Lock | Investigate blocking |
| CXPACKET | Parallelism | Review query design and MAXDOP if necessary |
| CXCONSUMER | Parallelism | Usually informational |
| ASYNC_NETWORK_IO | Network/Client | Reduce result sets, improve client processing |
| BACKUPIO | Backup Operations | Expected during backups |

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
