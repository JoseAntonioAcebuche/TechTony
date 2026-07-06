# 💾 Types of SQL Server Restore Operations

SQL Server supports several restore operations depending on the recovery scenario. Understanding each restore type helps ensure the correct recovery method is used while minimizing downtime and data loss.

---

# 1. Complete Database Restore

## Description

Restores the **entire database** from a Full Backup.

### Use When

- Recovering from database corruption
- Server failure
- Hardware replacement
- Database migration
- Restoring a database to another server

### Requirements

- Full Backup (.bak)

### Example

```sql
RESTORE DATABASE ParkingDB
FROM DISK = 'C:\Backup\ParkingDB_Full.bak'
WITH RECOVERY;
```

---

# 2. Differential Restore

## Description

Restores changes made since the last Full Backup.

A Differential Restore is always restored **after** a Full Backup.

### Restore Sequence

```
Full Backup
↓

Differential Backup
```

### Requirements

- Full Backup
- Differential Backup

### Example

```sql
RESTORE DATABASE ParkingDB
FROM DISK = 'C:\Backup\ParkingDB_Full.bak'
WITH NORECOVERY;

RESTORE DATABASE ParkingDB
FROM DISK = 'C:\Backup\ParkingDB_Diff.bak'
WITH RECOVERY;
```

---

# 3. Transaction Log Restore

## Description

Restores transaction log backups to recover the database up to a specific point in time.

Requires the database to use:

- Full Recovery Model
- Bulk-Logged Recovery Model

### Restore Sequence

```
Full Backup
↓

Differential Backup (Optional)
↓

Transaction Log Backup(s)
```

### Example

```sql
RESTORE LOG ParkingDB
FROM DISK = 'C:\Backup\ParkingDB_Log.trn'
WITH RECOVERY;
```

### Advantages

- Point-in-Time Recovery
- Minimal data loss

---

# 4. Point-in-Time Restore

## Description

Restores the database to an exact date and time.

Useful when accidental deletion or data corruption occurred.

### Example

Recover the database to:

```
2025-06-27 09:30 AM
```

```sql
RESTORE LOG ParkingDB
FROM DISK = 'C:\Backup\ParkingDB_Log.trn'
WITH STOPAT = '2025-06-27T09:30:00',
RECOVERY;
```

---

# 5. File Restore

## Description

Restores one or more individual database files instead of the entire database.

Typically used for Very Large Databases (VLDB).

### Advantages

- Faster restore
- Less downtime

---

# 6. Filegroup Restore

## Description

Restores an entire SQL Server filegroup.

Useful when databases are divided into multiple filegroups.

---

# 7. Page Restore

## Description

Restores only damaged database pages instead of the whole database.

### Use When

- Page corruption
- Disk errors affecting a few pages

### Advantages

- Minimal downtime
- Faster than full database restore

---

# 8. Piecemeal Restore

## Description

Restores the database one filegroup at a time.

Allows critical filegroups to become available before the entire database has finished restoring.

### Common Use

Large enterprise databases with multiple filegroups.

---

# 9. Tail-Log Restore

## Description

Restores the final transaction log backup captured after a database failure.

Usually performed after taking a Tail-Log Backup.

### Purpose

Recover the latest transactions before bringing the database online.

---

# 📊 Restore Order

## Full Backup Only

```
Full Backup
      ↓
 Restore
```

---

## Full + Differential

```
Full Backup
      ↓
Differential Backup
      ↓
 Restore
```

---

## Full + Differential + Transaction Logs

```
Full Backup
      ↓
Differential Backup
      ↓
Log Backup 1
      ↓
Log Backup 2
      ↓
Log Backup 3
      ↓
RECOVERY
```

---

# 📋 Restore Comparison

| Restore Type | Required Backup | Typical Use |
|---------------|-----------------|-------------|
| Complete Database Restore | Full Backup | Restore entire database |
| Differential Restore | Full + Differential | Faster recovery after Full Backup |
| Transaction Log Restore | Full + Log Backups | Recover recent transactions |
| Point-in-Time Restore | Full + Log Backups | Recover to a specific time |
| File Restore | File Backup | Restore selected database files |
| Filegroup Restore | Filegroup Backup | Restore selected filegroups |
| Page Restore | Full + Log Backups | Repair corrupted pages |
| Piecemeal Restore | Filegroup Backups | Large enterprise databases |
| Tail-Log Restore | Tail-Log Backup | Recover final transactions after failure |

---

# ✅ Best Practices

- Always restore backups in the correct sequence.
- Use **WITH NORECOVERY** until the final restore.
- Use **WITH RECOVERY** only on the last restore operation.
- Verify backup integrity before restoring.
- Test restores regularly in a non-production environment.
- Document every restore operation for auditing and disaster recovery.
