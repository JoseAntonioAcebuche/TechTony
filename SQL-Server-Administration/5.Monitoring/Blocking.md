# 🔒 SQL Server Blocking Guide

**Author:** Jose Antonio "Tony" Acebuche"

**Category:** SQL Server Administration

**Purpose:** Learn how SQL Server blocking occurs, how to identify blocking sessions, troubleshoot blocking problems, and resolve them safely in production environments.

---

# 📖 Overview

**Blocking** occurs when one SQL Server session prevents another session from accessing the same resource.

Blocking is a **normal behavior** in SQL Server because it protects data consistency using locks.

However, excessive or long-running blocking can cause:

- Slow applications
- User timeouts
- High response times
- Deadlocks
- Poor database performance

---

# What is Blocking?

Example

```text
User A

Updates Ticket #100

        │

        ▼

SQL Server places an Exclusive Lock (X)

        │

        ▼

User B tries to read Ticket #100

        │

        ▼

Must wait...

        │

        ▼

Blocking occurs
```

---

# Why Does Blocking Happen?

Blocking commonly occurs because of:

- Long-running transactions
- Large UPDATE statements
- DELETE operations
- INSERT operations
- Missing indexes
- Table scans
- Uncommitted transactions

---

# Lock Types

| Lock | Description |
|------|-------------|
| Shared (S) | Read operations |
| Exclusive (X) | INSERT, UPDATE, DELETE |
| Update (U) | Preparing to modify data |
| Intent Shared (IS) | Indicates shared locks below |
| Intent Exclusive (IX) | Indicates exclusive locks below |
| Schema (SCH) | Schema modifications |

---

# Blocking Example

```text
Session 55

UPDATE ParkingTransaction

↓

Exclusive Lock

↓

Session 60

SELECT ParkingTransaction

↓

Waiting...

↓

Blocked
```

---

# How to Detect Blocking

## Method 1 – Activity Monitor

```text
Object Explorer

↓

Activity Monitor

↓

Processes

↓

Blocked By
```

---

## Method 2 – sp_who2

```sql
EXEC sp_who2;
```

Look at:

```
BlkBy
```

Example

| SPID | BlkBy |
|------|-------|
| 58 | 55 |

Session **55** is blocking Session **58**.

---

## Method 3 – sys.dm_exec_requests

```sql
SELECT

session_id,

blocking_session_id,

wait_type,

wait_time,

status

FROM sys.dm_exec_requests

WHERE blocking_session_id <> 0;
```

---

## Method 4 – Show SQL Statement

```sql
SELECT

r.session_id,

r.blocking_session_id,

t.text

FROM sys.dm_exec_requests r

CROSS APPLY
sys.dm_exec_sql_text(r.sql_handle) t;
```

Displays the SQL statement causing the block.

---

# Find the Blocking Session

```sql
SELECT

session_id,

status,

command,

cpu_time,

total_elapsed_time

FROM sys.dm_exec_requests;
```

---

# Find Open Transactions

```sql
DBCC OPENTRAN;
```

Shows the oldest active transaction.

---

# Common Wait Types

| Wait Type | Meaning |
|------------|----------|
| LCK_M_S | Waiting for Shared Lock |
| LCK_M_X | Waiting for Exclusive Lock |
| LCK_M_U | Waiting for Update Lock |
| LCK_M_IS | Waiting for Intent Shared Lock |
| LCK_M_IX | Waiting for Intent Exclusive Lock |

---

# Blocking Workflow

```text
Application Slow

        │

        ▼

Check Activity Monitor

        │

        ▼

Blocked Sessions?

        │

      Yes

        │

        ▼

Find Blocking SPID

        │

        ▼

Review SQL Statement

        │

        ▼

Resolve Problem
```

---

# Resolving Blocking

## Option 1 – Wait

If the transaction will finish shortly, allow it to complete.

Recommended for:

- Small updates
- Short transactions

---

## Option 2 – Commit Transaction

Example

```sql
COMMIT;
```

Releases locks immediately.

---

## Option 3 – Rollback

```sql
ROLLBACK;
```

Releases locks but discards uncommitted changes.

---

## Option 4 – Kill Session

```sql
KILL 55;
```

Replace **55** with the blocking session ID.

⚠ Warning

Killing a session causes SQL Server to roll back the transaction, which may take time.

---

# Why Blocking Becomes Severe

Common causes:

- Missing indexes
- Long-running queries
- Large batch updates
- Table scans
- Poor execution plans
- User transactions left open
- Application bugs

---

# Preventing Blocking

- Keep transactions short.
- Commit transactions quickly.
- Create proper indexes.
- Avoid unnecessary table scans.
- Use efficient execution plans.
- Batch large UPDATE or DELETE operations.
- Monitor blocking regularly.

---

# Blocking vs Deadlock

| Blocking | Deadlock |
|----------|----------|
| Waiting | Circular waiting |
| Eventually completes | One transaction is terminated |
| Normal | Error 1205 generated |
| No victim | Deadlock victim selected |

---

# Blocking Chain Example

```text
Session 45

↓

Blocks

↓

Session 60

↓

Blocks

↓

Session 80

↓

Blocks

↓

Session 92
```

This is called a **Blocking Chain**.

---

# Monitoring Blocking

Useful DMVs

```sql
sys.dm_exec_requests
```

```sql
sys.dm_exec_sessions
```

```sql
sys.dm_tran_locks
```

```sql
sys.dm_os_waiting_tasks
```

---

# View Current Locks

```sql
SELECT

request_session_id,

resource_type,

resource_database_id,

request_mode,

request_status

FROM sys.dm_tran_locks;
```

---

# View Waiting Tasks

```sql
SELECT

session_id,

wait_type,

blocking_session_id,

wait_duration_ms

FROM sys.dm_os_waiting_tasks;
```

---

# Best Practices

- Keep transactions as short as possible.
- Avoid user interaction inside transactions.
- Review execution plans.
- Create proper indexes.
- Commit transactions immediately after changes.
- Monitor blocking during peak hours.
- Investigate recurring blocking patterns.

---

# Common Mistakes

❌ Leaving transactions open.

❌ Running large UPDATE statements without batching.

❌ Killing sessions without investigation.

❌ Ignoring missing indexes.

❌ Using transactions for long user operations.

---

# Real-World Example

## Parking Management System

### Problem

Cashiers experienced delays when processing vehicle exits.

Investigation

```sql
EXEC sp_who2;
```

Result

```
SPID 72

Blocking

SPID 81
```

Further investigation

```sql
SELECT

r.session_id,

t.text

FROM sys.dm_exec_requests r

CROSS APPLY
sys.dm_exec_sql_text(r.sql_handle) t;
```

Found:

```
BEGIN TRAN

UPDATE ParkingTransaction

(No COMMIT)
```

Solution

Developer committed the transaction:

```sql
COMMIT;
```

Result

- Blocking disappeared.
- Exit processing resumed immediately.
- Average transaction time dropped from **18 seconds** to **0.2 seconds**.

---

# Daily Blocking Checklist

- [ ] Check Activity Monitor
- [ ] Review blocked sessions
- [ ] Review long-running transactions
- [ ] Check wait statistics
- [ ] Monitor lock waits

---

# Weekly Checklist

- [ ] Review blocking trends
- [ ] Analyze execution plans
- [ ] Review missing indexes
- [ ] Optimize frequently blocked queries

---

# Related Documentation

- Deadlocks
- Wait Statistics
- SQL Server DMVs
- Activity Monitor
- Query Store
- Execution Plans
- Performance Tuning Tutorial
- Query Optimization
- SQL Server Indexing Guide

---

# Summary

| Tool | Purpose |
|------|----------|
| Activity Monitor | View blocked sessions |
| sp_who2 | Identify blocking SPIDs |
| sys.dm_exec_requests | Current blocking information |
| sys.dm_tran_locks | Current locks |
| sys.dm_os_waiting_tasks | Waiting sessions |
| DBCC OPENTRAN | Oldest active transaction |

---

# Enterprise Troubleshooting Workflow

```text
User Reports Slow Application
            │
            ▼
Check Activity Monitor
            │
            ▼
Blocked Sessions?
            │
       ┌────┴────┐
       │         │
      No        Yes
       │         │
       ▼         ▼
Review CPU   Find Blocking SPID
   /I/O            │
                   ▼
          Review Running Query
                   │
                   ▼
         Commit / Rollback / Tune
                   │
                   ▼
          Verify Blocking Cleared
                   │
                   ▼
      Monitor Performance Again
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
