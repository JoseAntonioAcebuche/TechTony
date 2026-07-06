# 📊 SQL Server Query Store Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Administration

**Purpose:** Learn how to use Query Store to monitor query performance, compare execution plans, identify regressions, and improve SQL Server performance.

---

# 📖 Overview

**Query Store** is a built-in SQL Server feature introduced in **SQL Server 2016**.

It automatically collects and stores:

- Query Text
- Execution Plans
- Runtime Statistics
- Query Performance History
- Plan Changes

Unlike the plan cache, Query Store retains historical performance information even after SQL Server restarts.

---

# Why Use Query Store?

Query Store helps administrators:

- Identify slow queries
- Compare execution plans
- Detect performance regressions
- Force stable execution plans
- Troubleshoot application slowdowns
- Analyze historical query performance

---

# How Query Store Works

```text
Application

        │

        ▼

SQL Server

        │

        ▼

Query Execution

        │

        ▼

Query Store

        │

 ┌───────────────┐
 │ Query Text    │
 │ Execution Plan│
 │ Runtime Stats │
 │ Wait Stats    │
 └───────────────┘
```

---

# Benefits

✅ Tracks historical query performance

✅ Keeps execution plans

✅ Detects plan regressions

✅ Helps identify expensive queries

✅ Supports plan forcing

---

# Requirements

Supported versions:

- SQL Server 2016
- SQL Server 2017
- SQL Server 2019
- SQL Server 2022
- Azure SQL Database

---

# Enable Query Store

## Using SSMS

```
Database

↓

Properties

↓

Query Store

↓

Operation Mode

↓

Read Write
```

---

## Using T-SQL

```sql
ALTER DATABASE ParkingDB
SET QUERY_STORE = ON;
```

---

# Verify Query Store Status

```sql
SELECT
name,
is_query_store_on
FROM sys.databases;
```

---

# Configure Query Store

Example

```sql
ALTER DATABASE ParkingDB
SET QUERY_STORE
(
OPERATION_MODE = READ_WRITE
);
```

---

# Query Store Options

| Option | Description |
|----------|-------------|
| READ_WRITE | Collects new query information |
| READ_ONLY | Allows viewing only |
| OFF | Disabled |

---

# View Top Resource Consuming Queries

Using SSMS

```
Database

↓

Query Store

↓

Top Resource Consuming Queries
```

Displays:

- CPU Usage
- Duration
- Logical Reads
- Execution Count
- Execution Plans

---

# View Query History

Query Store stores:

- Query execution history
- Performance over time
- Execution frequency
- Runtime statistics

Useful after:

- Software upgrades
- SQL Server updates
- Index changes

---

# Compare Execution Plans

Query Store allows comparing:

Old Plan

↓

New Plan

Example:

```
Plan A

Execution Time

0.2 sec

↓

Plan B

Execution Time

8.4 sec
```

This helps identify plan regressions.

---

# Force an Execution Plan

If SQL Server chooses a slower plan, you can force a previous efficient plan.

Using SSMS

```
Query Store

↓

Select Query

↓

Force Plan
```

---

# Remove Forced Plan

```sql
EXEC sys.sp_query_store_unforce_plan
@query_id = 10,
@plan_id = 15;
```

---

# Clear Query Store

```sql
ALTER DATABASE ParkingDB
SET QUERY_STORE CLEAR;
```

Use with caution because this deletes all collected Query Store data.

---

# Query Store Catalog Views

Useful catalog views:

```sql
sys.query_store_query
```

```sql
sys.query_store_plan
```

```sql
sys.query_store_runtime_stats
```

```sql
sys.query_store_wait_stats
```

Example

```sql
SELECT *
FROM sys.query_store_query;
```

---

# Common Use Cases

## After SQL Server Upgrade

Compare execution plans before and after the upgrade.

---

## After Creating an Index

Verify whether the query now uses:

```
Index Seek
```

instead of

```
Table Scan
```

---

## Slow Application

Identify:

- Expensive Queries
- High CPU Queries
- Long Duration Queries
- High Logical Reads

---

# Best Practices

✅ Enable Query Store on production databases.

✅ Review Top Resource Consuming Queries weekly.

✅ Monitor execution plan changes.

✅ Use Plan Forcing only after testing.

✅ Configure automatic cleanup.

✅ Periodically review Query Store size.

---

# Common Mistakes

❌ Leaving Query Store disabled.

❌ Ignoring plan regressions.

❌ Forcing inefficient execution plans.

❌ Never reviewing Query Store reports.

❌ Allowing Query Store to grow without limits.

---

# Real-World Example

## Parking Management System

### Problem

Cashiers reported that ticket searches became slow after a system update.

Investigation

1.

Opened Query Store.

↓

2.

Viewed Top Resource Consuming Queries.

↓

3.

Compared the old execution plan with the new one.

↓

4.

The new plan used:

```
Table Scan
```

instead of

```
Index Seek
```

↓

5.

Forced the previous execution plan.

↓

6.

Execution time improved from:

```
6.2 seconds
```

to

```
0.03 seconds
```

---

# Monitoring Checklist

Weekly

- Review expensive queries
- Review plan regressions
- Review forced plans
- Review Query Store size

Monthly

- Remove unnecessary forced plans
- Archive reports if required
- Review cleanup policies

---

# Related Documentation

- Performance Tuning Tutorial
- Query Optimization Guide
- SQL Server Indexing Guide
- Execution Plans
- Statistics and Query Optimizer
- SQL Server DMVs

---

# Summary

| Feature | Benefit |
|----------|----------|
| Query History | Historical performance analysis |
| Execution Plans | Compare query plans |
| Runtime Statistics | Identify slow queries |
| Wait Statistics | Detect bottlenecks |
| Plan Forcing | Stabilize query performance |
| Historical Data | Survives SQL Server restarts |

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
