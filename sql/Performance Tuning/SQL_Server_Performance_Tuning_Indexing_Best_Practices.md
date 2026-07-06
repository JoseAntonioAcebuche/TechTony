# SQL Server Performance Tuning, Indexing, and Best Practices

Author: Jose Antonio "Tony" Acebuche

This guide covers performance tuning, indexing, monitoring, and SQL Server administration best practices.

## Performance Tuning
- Optimize queries
- Avoid SELECT *
- Update statistics
- Rebuild/Reorganize indexes
- Monitor CPU, memory, disk I/O, waits, blocking, and deadlocks.

```sql
UPDATE STATISTICS dbo.Customers;
ALTER INDEX ALL ON dbo.Customers REBUILD;
SELECT * FROM sys.dm_exec_requests;
```

## Indexing
- Clustered Index
- Nonclustered Index
- Unique Index
- Composite Index
- Filtered Index
- Columnstore Index

```sql
CREATE NONCLUSTERED INDEX IX_LastName ON Employees(LastName);
```

## Best Practices
- Weekly Full Backup
- Daily Differential Backup
- Frequent Transaction Log Backups
- Run DBCC CHECKDB monthly
- Update statistics weekly
- Test restores regularly
