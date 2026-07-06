# 📈 SQL Server Execution Plans Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how SQL Server executes queries by reading Execution Plans, identifying performance bottlenecks, and optimizing queries for better database performance.

---

# 📖 Overview

An **Execution Plan** is a graphical or textual representation of how SQL Server executes a query.

It shows:

- Which indexes are used
- Which tables are scanned
- Join methods
- Operator costs
- Estimated and actual row counts
- Missing index recommendations

Execution Plans are one of the most valuable tools for SQL Server performance tuning.

---

# Why Execution Plans Matter

Execution Plans help you:

- Identify slow queries
- Detect table scans
- Find missing indexes
- Optimize JOIN operations
- Reduce CPU usage
- Reduce Disk I/O
- Improve query response time

---

# Types of Execution Plans

| Type | Description |
|------|-------------|
| Estimated Execution Plan | Generated without running the query |
| Actual Execution Plan | Generated while executing the query |
| Live Query Statistics | Shows query progress in real time |

---

# Estimated Execution Plan

## Description

Displays how SQL Server **plans** to execute the query without actually running it.

### Generate in SSMS

```
Query

↓

Display Estimated Execution Plan

Shortcut: Ctrl + L
```

---

# Actual Execution Plan

## Description

Displays how SQL Server **actually executed** the query.

Includes:

- Actual rows processed
- Actual execution cost
- Warnings
- Runtime information

### Generate in SSMS

```
Query

↓

Include Actual Execution Plan

Shortcut: Ctrl + M

↓

Execute Query (F5)
```

---

# Reading an Execution Plan

Execution Plans are read:

```
Right

↓

Left
```

The right-most operator is executed first.

---

# Understanding Operator Cost

Each operator displays an estimated percentage cost.

Example

```
Index Seek

15%

↓

Nested Loop

20%

↓

Sort

65%
```

Higher percentages indicate areas that may require optimization.

---

# Common Execution Plan Operators

---

# 1. Table Scan

## Description

Reads every row in the table.

```
Entire Table

↓

Read Every Row
```

### Causes

- Missing index
- Small table
- Poor WHERE clause

### Performance

❌ Slow on large tables

---

# 2. Clustered Index Scan

Reads every row of the clustered index.

Better than a table scan but still expensive for large tables.

---

# 3. Index Scan

Reads the entire index.

Usually indicates SQL Server cannot efficiently locate specific rows.

---

# 4. Index Seek

The most efficient lookup method.

```
Index

↓

Locate Matching Rows

↓

Return Result
```

Performance

✅ Fast

---

# 5. Key Lookup

Occurs when SQL Server finds rows using a Nonclustered Index but must retrieve additional columns from the Clustered Index.

Example

```sql
SELECT CustomerID,
       CustomerName,
       Address
FROM Customers
WHERE CustomerID = 100;
```

If **Address** is not included in the index, SQL Server performs a Key Lookup.

Possible Solution

Create a Covering Index.

---

# 6. RID Lookup

Occurs on heaps (tables without a Clustered Index).

Generally indicates a Clustered Index may improve performance.

---

# 7. Nested Loop Join

Best for:

- Small datasets
- Indexed tables

Performance

✅ Fast

---

# 8. Merge Join

Best for:

- Large sorted datasets

Requires both inputs to be sorted.

---

# 9. Hash Match

Best for:

- Large unsorted datasets

Uses more memory.

Can indicate missing indexes.

---

# 10. Sort

Sorts rows before returning results.

Large sorts can consume:

- CPU
- Memory
- TempDB

---

# 11. Compute Scalar

Calculates expressions.

Example

```sql
Price * Quantity
```

Normally inexpensive.

---

# 12. Filter

Applies WHERE conditions.

---

# Warnings in Execution Plans

Look for:

⚠ Missing Index

⚠ Implicit Conversion

⚠ Sort Warning

⚠ Spill to TempDB

⚠ Hash Warning

These warnings often indicate optimization opportunities.

---

# Missing Index Recommendation

Execution Plans sometimes display:

```
Missing Index

Estimated Improvement

98%
```

Review recommendations before creating indexes. Avoid creating duplicate or unnecessary indexes.

---

# Actual vs Estimated Rows

Example

Estimated Rows

```
100
```

Actual Rows

```
500,000
```

Large differences usually indicate outdated statistics or parameter sniffing issues.

---

# Example Query

```sql
SELECT
TicketNumber,
PlateNumber
FROM ParkingTransaction
WHERE TicketNumber='240000123';
```

Possible Execution Plan

```
Index Seek

↓

Key Lookup

↓

SELECT
```

Optimization

Create a Covering Index to eliminate the Key Lookup.

---

# Save Execution Plan

In SSMS:

```
Execution Plan

↓

Right Click

↓

Save Execution Plan As...

File Type

.sqlplan
```

Useful for documentation and performance analysis.

---

# Execution Plan Troubleshooting

| Operator | Possible Issue | Recommended Action |
|-----------|----------------|--------------------|
| Table Scan | Missing Index | Create appropriate index |
| Index Scan | Poor selectivity | Improve index or query |
| Key Lookup | Extra page reads | Create Covering Index |
| Hash Match | Missing indexes | Review joins and indexes |
| Sort | ORDER BY cost | Create supporting index |
| RID Lookup | Heap table | Consider Clustered Index |

---

# Best Practices

✅ Always review Actual Execution Plans for slow queries.

✅ Investigate Table Scans on large tables.

✅ Update statistics regularly.

✅ Avoid SELECT *.

✅ Create indexes based on workload.

✅ Monitor Key Lookups.

✅ Use Covering Indexes where appropriate.

---

# Common Mistakes

❌ Ignoring execution plans.

❌ Creating every suggested missing index.

❌ Focusing only on operator cost percentages.

❌ Ignoring warnings.

❌ Never updating statistics.

---

# Real-World Example

## Parking Management System

### Problem

Cashiers reported that searching by Ticket Number took approximately **6 seconds**.

Execution Plan

```
Table Scan

↓

Filter

↓

SELECT
```

Cause

No index existed on **TicketNumber**.

Solution

```sql
CREATE NONCLUSTERED INDEX IX_TicketNumber
ON ParkingTransaction(TicketNumber);
```

New Execution Plan

```
Index Seek

↓

SELECT
```

Performance Improvement

| Before | After |
|---------|-------|
| 6.0 seconds | 0.02 seconds |
| Table Scan | Index Seek |
| High CPU | Low CPU |
| High Disk I/O | Minimal Disk I/O |

---

# Performance Checklist

When reviewing an Execution Plan:

- [ ] Look for Table Scans
- [ ] Check for Index Seeks
- [ ] Review Key Lookups
- [ ] Check estimated vs actual rows
- [ ] Review warnings
- [ ] Evaluate join types
- [ ] Check sort operations
- [ ] Verify missing index recommendations
- [ ] Update statistics if necessary

---

# Related Documentation

- SQL Server Performance Tuning
- SQL Server Indexing Guide
- Query Optimization Guide
- Query Store Guide
- Statistics and Query Optimizer
- SQL Server DMVs

---

# Summary

| Operator | Performance |
|----------|-------------|
| Index Seek | ⭐⭐⭐⭐⭐ Excellent |
| Nested Loop | ⭐⭐⭐⭐⭐ Excellent |
| Merge Join | ⭐⭐⭐⭐ Good |
| Index Scan | ⭐⭐⭐ Moderate |
| Hash Match | ⭐⭐⭐ Moderate |
| Clustered Index Scan | ⭐⭐ Fair |
| Table Scan | ⭐ Poor |
| Key Lookup | Depends on frequency |
| RID Lookup | Usually needs optimization |

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
