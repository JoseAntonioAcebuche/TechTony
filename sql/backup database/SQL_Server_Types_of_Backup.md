# 💾 Types of SQL Server Backup

**Author:** Jose Antonio "Tony" Acebuche  
**Category:** SQL Server Administration  
**Purpose:** To understand the different SQL Server backup types and determine when to use each one for effective disaster recovery and data protection.

---

# 📖 Overview

SQL Server provides several backup types designed for different recovery scenarios. Choosing the correct backup strategy is essential for protecting your databases and minimizing data loss.

---

# 1. Full Backup

## Description

A **Full Backup** contains the entire database, including:

- Data files (`.mdf`, `.ndf`)
- Enough transaction log information to recover the database
- Database objects (tables, views, stored procedures, indexes)

This is the foundation of every backup strategy.

### Use When

- Creating the first backup
- Before maintenance or upgrades
- Before applying patches
- Small to medium-sized databases
- Weekly scheduled backups

### Advantages

- Easy to restore
- Complete copy of the database
- Simplifies disaster recovery

### Disadvantages

- Largest backup size
- Takes the longest time to complete

---

# 2. Differential Backup

## Description

A **Differential Backup** stores only the data that has changed since the last **Full Backup**.

### Example

```text
Sunday      Full Backup
Monday      Differential
Tuesday     Differential
Wednesday   Differential
```

### Restore Process

1. Restore Sunday's Full Backup.
2. Restore Wednesday's Differential Backup.

### Advantages

- Faster than Full Backup
- Smaller backup size
- Faster restore than restoring multiple log backups

### Disadvantages

- Grows larger each day until the next Full Backup

---

# 3. Transaction Log Backup

## Description

Backs up only the transaction log records generated since the last transaction log backup.

**Requires one of the following recovery models:**

- Full Recovery Model
- Bulk-Logged Recovery Model

### Example

```text
08:00 Full Backup
09:00 Log Backup
10:00 Log Backup
11:00 Log Backup
```

### Advantages

- Minimal data loss
- Supports Point-in-Time Recovery
- Small backup files
- Frequent backups with minimal storage usage

### Disadvantages

- Cannot be restored by itself
- Requires a Full Backup first
- Requires the complete log backup chain

---

# 4. Copy-Only Backup

## Description

A **Copy-Only Backup** is a special Full or Transaction Log backup that does **not** affect the normal backup sequence.

Useful for temporary or one-time backups.

### Use When

- Before testing
- Before software upgrades
- Before troubleshooting
- Before data migration
- Before applying patches

### Advantages

- Does not break the backup chain
- Safe for ad hoc backups
- Ideal for temporary backups

---

# 5. File Backup

## Description

Backs up one or more individual database files instead of the entire database.

Typically used for **Very Large Databases (VLDB)**.

### Advantages

- Faster backup
- Smaller backup size
- Flexible restore options

### Common Use

Large enterprise databases with multiple data files.

---

# 6. Filegroup Backup

## Description

Backs up an entire SQL Server filegroup.

Useful when databases are divided into multiple filegroups.

### Advantages

- Backup only critical filegroups
- Reduces backup time
- Faster recovery of important data

---

# 7. Partial Backup

## Description

Backs up the:

- Primary filegroup
- Selected read/write filegroups

Typically used for databases containing read-only filegroups.

### Advantages

- Smaller backups
- Faster backup and restore
- Useful for very large databases

---

# 8. Tail-Log Backup

## Description

Captures the final portion of the transaction log before restoring a damaged database.

### Use When

- Database corruption
- Server crash
- Storage failure
- Before performing a database restore

### Purpose

Prevent losing the most recent transactions.

---

# 📊 Recovery Model Support

| Backup Type | Simple | Full | Bulk-Logged |
|-------------|:------:|:----:|:-----------:|
| Full | ✅ | ✅ | ✅ |
| Differential | ✅ | ✅ | ✅ |
| Transaction Log | ❌ | ✅ | ✅ |
| Copy-Only | ✅ | ✅ | ✅ |
| File | ✅ | ✅ | ✅ |
| Filegroup | ✅ | ✅ | ✅ |
| Partial | ✅ | ✅ | ✅ |
| Tail-Log | ❌ | ✅ | ✅ |

---

# 📅 Recommended Backup Strategy

| Frequency | Backup Type |
|-----------|-------------|
| Weekly | Full Backup |
| Daily | Differential Backup |
| Every 15–30 minutes | Transaction Log Backup |
| Before Maintenance | Copy-Only Backup |

---

# 🎯 Which Backup Should You Use?

| Scenario | Recommended Backup |
|----------|--------------------|
| Before maintenance | Full or Copy-Only Backup |
| Before software upgrade | Full Backup |
| Everyday protection | Differential Backup |
| Minimal data loss | Transaction Log Backup |
| Database corruption | Tail-Log Backup (if possible) |
| Large enterprise database | File or Filegroup Backup |
| Temporary backup | Copy-Only Backup |

---

# 📋 Backup Comparison

| Backup Type | Contains | Typical Size | Restore Speed |
|-------------|----------|--------------|---------------|
| Full | Entire database | Large | Fast |
| Differential | Changes since last Full Backup | Medium | Fast |
| Transaction Log | Transaction log records only | Small | Slower (requires backup chain) |
| Copy-Only | Independent Full or Log backup | Same as source type | Same as source type |
| File | Selected database files | Small | Moderate |
| Filegroup | Selected filegroups | Medium | Moderate |
| Partial | Primary + selected read/write filegroups | Medium | Moderate |
| Tail-Log | Final transaction log | Small | Used before restore |

---

# ✅ Best Practices

- Perform a **Full Backup** at least once per week.
- Schedule **Differential Backups** daily to reduce restore time.
- Perform **Transaction Log Backups** every 15–30 minutes for production databases using the Full Recovery Model.
- Create a **Copy-Only Backup** before major maintenance or upgrades.
- Periodically test your backups by performing restore operations in a non-production environment.
- Store backup files on separate storage or network locations whenever possible.
- Regularly monitor available disk space and backup job status.

---

**Documentation by:**  
**Jose Antonio "Tony" Acebuche**
