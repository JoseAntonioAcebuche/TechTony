# 🚀 SQL Server Query Optimization Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to write efficient SQL queries that reduce execution time, CPU usage, memory consumption, and disk I/O while improving overall database performance.

---

# 📖 Overview

Query Optimization is the process of improving SQL statements so SQL Server can retrieve data with the least amount of work.

A poorly written query can consume excessive:

- CPU
- Memory
- Disk I/O
- Network bandwidth

while slowing down the entire application.

The SQL Server Query Optimizer automatically chooses an execution plan, but writing efficient queries helps it generate better plans.

---

# Query Optimization Workflow

```text
Slow Query Reported
        │
        ▼
Check Execution Plan
        │
        ▼
Identify Table Scan / Index Scan
        │
        ▼
Review WHERE Clause
        │
        ▼
Check Missing Indexes
        │
        ▼
Update Statistics
        │
        ▼
Optimize SQL Statement
        │
        ▼
Retest Performance
```

---

# 1. Avoid SELECT *

## ❌ Bad

```sql
SELECT *
FROM Customers;
```

SQL Server retrieves every column even when only a few are needed.

---

## ✅ Good

```sql
SELECT CustomerID,
       CustomerName
FROM Customers;
```

Advantages

- Less Disk I/O
- Less Memory
- Less Network Traffic
- Faster Execution

---

# 2. Use WHERE Clause

## ❌ Bad

```sql
SELECT *
FROM Orders;
```

---

## ✅ Good

```sql
SELECT *
FROM Orders
WHERE OrderID = 1001;
```

---

# 3. Return Only Needed Rows

Instead of

```sql
SELECT *
FROM Orders;
```

Use

```sql
SELECT TOP 100 *
FROM Orders;
```

or

```sql
SELECT *
FROM Orders
ORDER BY OrderDate DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;
```

---

# 4. Avoid Functions in WHERE

## ❌ Bad

```sql
SELECT *
FROM Orders
WHERE YEAR(OrderDate)=2025;
```

SQL Server cannot efficiently use an index.

---

## ✅ Good

```sql
SELECT *
FROM Orders
WHERE OrderDate >= '2025-01-01'
AND OrderDate < '2026-01-01';
```

This is a **SARGable** query.

---

# 5. Write SARGable Queries

SARGable means **Search ARGument Able**.

SQL Server can use indexes efficiently.

Example

```sql
WHERE CustomerID = 100
```

instead of

```sql
WHERE CustomerID + 1 = 101
```

---

# 6. Use Proper JOINs

## Good Example

```sql
SELECT
c.CustomerName,
o.OrderDate
FROM Customers c
INNER JOIN Orders o
ON c.CustomerID=o.CustomerID;
```

Index the JOIN columns whenever possible.

---

# 7. EXISTS vs IN

Prefer **EXISTS** when checking large tables.

```sql
SELECT *
FROM Customers c
WHERE EXISTS
(
SELECT 1
FROM Orders o
WHERE o.CustomerID=c.CustomerID
);
```

---

# 8. UNION vs UNION ALL

## UNION

Removes duplicate rows.

```sql
SELECT Name FROM A
UNION
SELECT Name FROM B;
```

---

## UNION ALL

Returns all rows.

```sql
SELECT Name FROM A
UNION ALL
SELECT Name FROM B;
```

Use **UNION ALL** when duplicate removal is unnecessary because it is generally faster.

---

# 9. Use Appropriate Data Types

Avoid comparing mismatched data types.

## ❌ Bad

```sql
WHERE CustomerID='100'
```

---

## ✅ Good

```sql
WHERE CustomerID=100
```

---

# 10. Avoid Unnecessary DISTINCT

## ❌ Bad

```sql
SELECT DISTINCT CustomerName
FROM Customers;
```

Use DISTINCT only when duplicates must be removed.

---

# 11. Avoid Cursors When Possible

Cursors process one row at a time.

Prefer set-based operations.

## ❌ Cursor

```sql
DECLARE cursor_name CURSOR
FOR
SELECT CustomerID
FROM Customers;
```

## ✅ Set-Based

```sql
UPDATE Customers
SET Status='Active'
WHERE LastLogin >= DATEADD(day,-30,GETDATE());
```

---

# 12. Use Indexes

Find Missing Indexes

```sql
SELECT *
FROM sys.dm_db_missing_index_details;
```

---

# 13. Update Statistics

```sql
UPDATE STATISTICS dbo.Customers;
```

or

```sql
EXEC sp_updatestats;
```

---

# 14. Review Execution Plans

Enable Actual Execution Plan

```text
Ctrl + M
```

Look for

- Table Scan
- Index Scan
- Index Seek
- Missing Index
- Key Lookup
- Hash Match

---

# 15. Parameter Sniffing

SQL Server caches execution plans.

Sometimes the cached plan is inefficient.

Possible solutions

- OPTION (RECOMPILE)
- OPTIMIZE FOR
- Local variables
- Query Store plan forcing

Example

```sql
SELECT *
FROM Orders
WHERE CustomerID=@CustomerID
OPTION (RECOMPILE);
```

---

# Common Query Problems

| Problem | Solution |
|----------|----------|
| Table Scan | Create Index |
| Index Scan | Improve Index |
| Slow WHERE | Make Query SARGable |
| High CPU | Optimize SQL |
| High I/O | Reduce Returned Rows |
| Blocking | Short Transactions |
| Missing Index | Create Appropriate Index |

---

# Performance Checklist

Before deploying a query

- [ ] No SELECT *
- [ ] WHERE clause used
- [ ] Correct indexes exist
- [ ] Statistics updated
- [ ] Execution plan reviewed
- [ ] SARGable predicates
- [ ] Appropriate JOIN type
- [ ] LIMIT/TOP used when applicable

---

# Real-World Example

## Parking Management System

### Problem

Cashiers reported that ticket searches were taking **5–6 seconds** during peak hours.

Original Query

```sql
SELECT *
FROM ParkingTransaction
WHERE TicketNumber='240001245';
```

Execution Plan

```text
Table Scan
```

Solution

```sql
CREATE NONCLUSTERED INDEX IX_TicketNumber
ON ParkingTransaction(TicketNumber);
```

Optimized Query

```sql
SELECT
TicketNumber,
PlateNumber,
EntryTime,
ExitTime
FROM ParkingTransaction
WHERE TicketNumber='240001245';
```

Result

| Before | After |
|----------|-------|
| 5.8 sec | 0.02 sec |
| Table Scan | Index Seek |
| High CPU | Low CPU |
| High Disk I/O | Low Disk I/O |

---

# Best Practices

- Return only required columns.
- Filter data using indexed columns.
- Keep queries SARGable.
- Avoid unnecessary sorting.
- Use proper JOINs.
- Monitor execution plans regularly.
- Keep statistics updated.
- Review Query Store for regressions.

---

# Related Documentation

- SQL Server Performance Tuning
- SQL Server Indexing Guide
- Execution Plans
- Statistics and Query Optimizer
- SQL Server DMVs
- Database Maintenance Plan

---

**Documentation by:**  
**Jose Antonio "Tony" Acebuche**
