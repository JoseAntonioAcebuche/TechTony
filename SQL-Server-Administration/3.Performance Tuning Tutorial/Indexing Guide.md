# 📚 SQL Server Indexing Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how SQL Server indexes work, when to use each index type, and how to maintain indexes for optimal database performance.

---

# 📖 Overview

An **Index** is a database object that improves the speed of data retrieval operations.

Think of an index like the **index of a book**.

Without an index, SQL Server must scan the entire table.

With an index, SQL Server can quickly locate the required rows.

---

# Why Indexes Matter

Indexes help SQL Server:

- Retrieve rows faster
- Reduce Disk I/O
- Reduce CPU usage
- Improve JOIN performance
- Improve ORDER BY
- Improve GROUP BY
- Improve WHERE clause searches

---

# How SQL Server Reads Data

## Without an Index

```text
Customer Table

Row 1
Row 2
Row 3
...
Row 1,000,000

↓

Table Scan
```

SQL Server reads every row.

---

## With an Index

```text
CustomerID Index

1001
1002
1003
1004

↓

Index Seek

↓

Requested Row
```

Only the required rows are read.

---

# Types of SQL Server Indexes

| Index Type | Purpose |
|-------------|---------|
| Clustered | Sorts the table physically |
| Nonclustered | Separate lookup structure |
| Unique | Prevent duplicate values |
| Composite | Multiple indexed columns |
| Filtered | Index only selected rows |
| Covering | Includes additional columns |
| Columnstore | Analytics and reporting |
| XML | XML data |
| Full-Text | Text searching |

---

# 1. Clustered Index

## Description

A Clustered Index determines the physical order of rows inside the table.

A table can have only **one** Clustered Index.

---

### Example

```sql
CREATE CLUSTERED INDEX IX_OrderID
ON Orders(OrderID);
```

---

### Advantages

- Fast range searches
- Efficient sorting
- Efficient primary key lookups

---

### Disadvantages

- Only one per table
- Slower INSERT operations on heavily modified tables

---

# 2. Nonclustered Index

## Description

Stores indexed values separately from the data pages.

Contains pointers to the actual rows.

---

### Example

```sql
CREATE NONCLUSTERED INDEX IX_LastName
ON Employees(LastName);
```

---

### Advantages

- Multiple indexes per table
- Excellent for WHERE clauses
- Improves JOIN performance

---

### Disadvantages

- Consumes storage
- Slightly slows INSERT, UPDATE, and DELETE operations

---

# 3. Unique Index

## Description

Ensures duplicate values cannot exist.

---

### Example

```sql
CREATE UNIQUE INDEX IX_Email
ON Users(Email);
```

---

# 4. Composite Index

## Description

Indexes multiple columns together.

---

### Example

```sql
CREATE INDEX IX_NameDepartment
ON Employees
(
LastName,
Department
);
```

---

### Best Practice

Place the most selective column first.

---

# 5. Covering Index

## Description

Contains all columns required by a query.

SQL Server can retrieve data directly from the index without accessing the table.

---

### Example

```sql
CREATE INDEX IX_Sales
ON Sales(CustomerID)
INCLUDE
(
OrderDate,
Amount
);
```

---

# 6. Filtered Index

## Description

Indexes only rows matching a condition.

---

### Example

```sql
CREATE INDEX IX_ActiveCustomers
ON Customers(Status)
WHERE Status='Active';
```

---

### Advantages

- Smaller index
- Faster queries
- Reduced storage

---

# 7. Columnstore Index

## Description

Stores data by columns instead of rows.

Optimized for:

- Reporting
- Data Warehousing
- Analytics

---

### Example

```sql
CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales
ON Sales;
```

---

# Index Seek vs Index Scan vs Table Scan

## Index Seek

Reads only matching rows.

✅ Fastest

---

## Index Scan

Reads the entire index.

⚠ Medium performance

---

## Table Scan

Reads every row in the table.

❌ Slowest

---

# Find Missing Indexes

```sql
SELECT *
FROM sys.dm_db_missing_index_details;
```

---

# Check Index Usage

```sql
SELECT *
FROM sys.dm_db_index_usage_stats;
```

---

# Check Index Fragmentation

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

# Reorganize Index

Recommended for **5%–30% fragmentation**.

```sql
ALTER INDEX ALL
ON dbo.Customers
REORGANIZE;
```

---

# Rebuild Index

Recommended for **greater than 30% fragmentation**.

```sql
ALTER INDEX ALL
ON dbo.Customers
REBUILD;
```

---

# Update Statistics After Rebuild

```sql
UPDATE STATISTICS dbo.Customers;
```

or

```sql
EXEC sp_updatestats;
```

---

# Best Practices

✅ Create indexes on frequently searched columns.

✅ Index JOIN columns.

✅ Index WHERE clause columns.

✅ Monitor fragmentation regularly.

✅ Remove unused indexes.

✅ Update statistics regularly.

✅ Use covering indexes for expensive queries.

---

# Common Mistakes

❌ Creating too many indexes.

❌ Indexing very small tables.

❌ Ignoring fragmentation.

❌ Never updating statistics.

❌ Using duplicate indexes.

❌ Forgetting to monitor index usage.

---

# Real-World Example

## Parking Management System

The POS application searches parking tickets by **TicketNumber** thousands of times every day.

Without an index:

```text
Table Scan

↓

Reads 5 million rows
```

Execution time:

```text
4.8 seconds
```

After creating a Nonclustered Index:

```sql
CREATE NONCLUSTERED INDEX IX_TicketNumber
ON ParkingTransaction(TicketNumber);
```

Execution plan changes to:

```text
Index Seek
```

Execution time:

```text
0.02 seconds
```

The application becomes significantly faster while reducing CPU and Disk I/O.

---

# Index Maintenance Schedule

## Daily

- Monitor slow queries
- Review missing index recommendations

---

## Weekly

- Check fragmentation
- Reorganize fragmented indexes
- Update statistics

---

## Monthly

- Rebuild heavily fragmented indexes
- Remove unused indexes
- Review duplicate indexes

---

# Index Selection Guide

| Scenario | Recommended Index |
|----------|-------------------|
| Primary Key | Clustered |
| Frequently searched column | Nonclustered |
| Prevent duplicates | Unique |
| Multiple WHERE columns | Composite |
| Reporting | Columnstore |
| Frequently filtered rows | Filtered |
| Expensive SELECT queries | Covering |

---

# Related Documentation

- Performance Tuning Tutorial
- Query Optimization
- Execution Plans
- Statistics and Query Optimizer
- SQL Server DMVs
- Database Maintenance Plan

---

**Documentation by:**  
**Jose Antonio "Tony" Acebuche**
