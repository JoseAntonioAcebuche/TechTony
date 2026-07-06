# ⚔️ SQL Server Deadlocks Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn what SQL Server deadlocks are, how they occur, how to detect them, troubleshoot them, and implement best practices to prevent them in production environments.

---

# 📖 Overview

A **Deadlock** occurs when two or more SQL Server sessions permanently block each other because each session is waiting for a resource locked by another session.

Unlike normal blocking, **SQL Server automatically resolves a deadlock** by selecting one transaction as the **Deadlock Victim** and terminating it.

The terminated transaction receives:

```
Msg 1205

Transaction (Process ID xx) was deadlocked on resources with another process and has been chosen as the deadlock victim.
```

---

# What is a Deadlock?

Example

```text
Session A

Locks Table A

        │

        ▼

Needs Table B

────────────────────────────

Session B

Locks Table B

        │

        ▼

Needs Table A

────────────────────────────

Neither session can continue.

↓

Deadlock
```

---

# Deadlock vs Blocking

| Blocking | Deadlock |
|----------|----------|
| One session waits | Both sessions wait |
| Eventually completes | Never completes |
| No transaction terminated | SQL Server kills one transaction |
| Normal behavior | Error 1205 |

---

# How Deadlocks Occur

Example

Transaction A

```sql
BEGIN TRAN;

UPDATE Customers
SET Name='John'
WHERE CustomerID=1;

UPDATE Orders
SET Status='Paid'
WHERE OrderID=100;

COMMIT;
```

Transaction B

```sql
BEGIN TRAN;

UPDATE Orders
SET Status='Processing'
WHERE OrderID=100;

UPDATE Customers
SET Name='Johnny'
WHERE CustomerID=1;

COMMIT;
```

Result

```
Transaction A

Waiting for Orders

↓

Transaction B

Waiting for Customers

↓

Deadlock
```

---

# SQL Server Deadlock Detection

SQL Server continuously monitors lock dependencies.

When a deadlock is detected:

```text
Detect Cycle

↓

Choose Deadlock Victim

↓

Rollback Victim

↓

Allow Remaining Transaction
```

---

# Deadlock Victim

SQL Server chooses the victim based on:

- Lowest rollback cost
- Deadlock priority
- Estimated transaction cost

---

# Set Deadlock Priority

Low Priority

```sql
SET DEADLOCK_PRIORITY LOW;
```

Normal

```sql
SET DEADLOCK_PRIORITY NORMAL;
```

High Priority

```sql
SET DEADLOCK_PRIORITY HIGH;
```

Numeric values

```sql
SET DEADLOCK_PRIORITY -10;
```

Range

```
-10

to

10
```

Higher values reduce the likelihood of becoming the victim.

---

# Detect Deadlocks

## Method 1 – Extended Events (Recommended)

The built-in **system_health** Extended Events session captures deadlock graphs by default.

---

## Method 2 – SQL Server Error Log

If configured, deadlock information may be written to the SQL Server Error Log.

---

## Method 3 – Extended Events Session

Create a dedicated Extended Events session for deadlocks when detailed monitoring is required.

---

# View Current Locks

```sql
SELECT

request_session_id,

resource_type,

request_mode,

request_status

FROM sys.dm_tran_locks;
```

---

# View Waiting Sessions

```sql
SELECT

session_id,

blocking_session_id,

wait_type,

wait_duration_ms

FROM sys.dm_os_waiting_tasks;
```

---

# Current Requests

```sql
SELECT

session_id,

status,

blocking_session_id,

command

FROM sys.dm_exec_requests;
```

---

# Deadlock Graph

A deadlock graph displays:

- Processes
- Locked resources
- Wait chain
- Victim process

Example

```text
Process A

↓

Waiting

↓

Table Orders

↑

↓

Process B

↓

Waiting

↓

Table Customers

↓

Deadlock

↓

Victim

↓

Process B
```

---

# Common Causes

- Transactions updating tables in different order
- Long-running transactions
- Missing indexes
- Table scans
- Large batch updates
- User interaction inside transactions
- Poor execution plans

---

# Preventing Deadlocks

## 1. Keep Transactions Short

Bad

```sql
BEGIN TRAN;

UPDATE Customers;

WAITFOR DELAY '00:01:00';

COMMIT;
```

Good

```sql
BEGIN TRAN;

UPDATE Customers;

COMMIT;
```

---

## 2. Access Tables in the Same Order

Always update related tables consistently.

Good

```text
Customers

↓

Orders

↓

Payments
```

Do not change the order between transactions.

---

## 3. Create Proper Indexes

Missing indexes often force table scans, increasing lock duration.

---

## 4. Commit Quickly

Always commit immediately after completing work.

---

## 5. Avoid User Interaction

Never wait for user input while a transaction is open.

---

## 6. Process Large Updates in Batches

Instead of:

```sql
UPDATE Orders
SET Status='Closed';
```

Process smaller batches.

---

# Retry Logic

Applications should retry transactions after receiving Error 1205.

Pseudo-code

```text
Execute Transaction

↓

Deadlock?

↓

Yes

↓

Wait

↓

Retry
```

---

# Monitoring Deadlocks

Useful Tools

| Tool | Purpose |
|------|----------|
| Extended Events | Deadlock graphs |
| Activity Monitor | Blocking overview |
| DMVs | Current sessions |
| Query Store | Historical query analysis |
| SQL Server Error Log | Deadlock events (if configured) |

---

# Best Practices

- Keep transactions short.
- Access tables in a consistent order.
- Create appropriate indexes.
- Review execution plans.
- Batch large updates.
- Implement retry logic in applications.
- Monitor Extended Events regularly.
- Investigate recurring deadlocks.

---

# Common Mistakes

❌ Leaving transactions open.

❌ Updating tables in different order.

❌ Ignoring missing indexes.

❌ Running large updates during business hours.

❌ Not implementing retry logic.

❌ Ignoring deadlock graphs.

---

# Real-World Example

## Parking Management System

### Problem

During peak exit hours, payment processing occasionally failed.

Application Error

```
Error 1205

Transaction was deadlocked.
```

Investigation

- Extended Events captured a deadlock graph.
- Transaction A updated:

```
ParkingTransaction

↓

Payment
```

Transaction B updated:

```
Payment

↓

ParkingTransaction
```

Solution

Developers modified both transactions to update tables in the same order:

```text
ParkingTransaction

↓

Payment
```

Result

- Deadlocks eliminated.
- Payment failures stopped.
- Peak-hour processing stabilized.
- User complaints dropped significantly.

---

# Daily DBA Checklist

- [ ] Monitor Extended Events
- [ ] Review blocking sessions
- [ ] Check wait statistics
- [ ] Review failed transactions
- [ ] Monitor application logs

---

# Weekly DBA Checklist

- [ ] Analyze deadlock graphs
- [ ] Review execution plans
- [ ] Check missing indexes
- [ ] Optimize frequently deadlocking queries

---

# Related Documentation

- Blocking
- SQL Server DMVs
- Wait Statistics
- Activity Monitor
- Execution Plans
- Query Optimization
- SQL Server Indexing Guide
- Performance Tuning Tutorial
- Extended Events

---

# Summary

| Topic | Description |
|--------|-------------|
| Blocking | One session waits for another |
| Deadlock | Sessions wait on each other |
| Deadlock Victim | Transaction terminated by SQL Server |
| Error Code | 1205 |
| Best Detection Tool | Extended Events |
| Prevention | Short transactions, proper indexing, consistent table access order |

---

# Deadlock Troubleshooting Workflow

```text
Application Reports Error 1205
            │
            ▼
Check Extended Events
            │
            ▼
Review Deadlock Graph
            │
            ▼
Identify Victim Process
            │
            ▼
Analyze SQL Statements
            │
            ▼
Check Table Access Order
            │
            ▼
Review Indexes
            │
            ▼
Optimize Queries
            │
            ▼
Implement Retry Logic
            │
            ▼
Monitor for Recurrence
```

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
