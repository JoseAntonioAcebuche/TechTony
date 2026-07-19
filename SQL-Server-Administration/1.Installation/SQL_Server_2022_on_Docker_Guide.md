# 🐳 SQL Server 2022 on Docker Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to deploy, manage, back up, restore, and troubleshoot Microsoft SQL Server running in Docker for development, testing, and DBA practice.

---

# 📖 Overview

Microsoft SQL Server can run inside a Docker container on **Linux, Windows, or macOS**. Docker provides a lightweight, portable, and isolated environment that allows DBAs and developers to build SQL Server labs without installing SQL Server directly on the host operating system.

## Why Use SQL Server in Docker?

- Fast deployment
- Easy reset and recreation
- Lightweight and isolated environment
- Persistent storage using Docker Volumes
- Ideal for development, testing, and DBA practice
- Consistent environment across multiple machines

---

# 📋 Prerequisites

- Docker Engine (Linux) or Docker Desktop (Windows/macOS)
- Docker Compose Plugin
- Minimum 4 GB RAM
- Port **1433** available
- SQL Server Management Studio (SSMS), Azure Data Studio, or DBeaver

Verify the installation:

```bash
docker --version
docker compose version
```

---

# 📁 Project Structure

```
mssql-server/
├── docker-compose.yml
├── backup/
├── README.md
```

The `backup` directory stores SQL Server backup files (`.bak`).

---

# 📥 Pull SQL Server Image

```bash
docker pull mcr.microsoft.com/mssql/server:2022-latest
```

---

# 🚀 Deploy SQL Server Using Docker Compose

Create a file named **docker-compose.yml**.

```yaml
version: "3.9"

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sqlserver

    restart: unless-stopped

    environment:
      ACCEPT_EULA: "Y"
      MSSQL_PID: "Developer"
      MSSQL_SA_PASSWORD: "YourStrong@Pass123"

    ports:
      - "1433:1433"

    volumes:
      - sql_data:/var/opt/mssql
      - ./backup:/backup

volumes:
  sql_data:
```

---

# ▶️ Start SQL Server

```bash
docker compose up -d
```

Check the running container.

```bash
docker ps
```

View container logs.

```bash
docker logs sqlserver
```

Expected message:

```
SQL Server is now ready for client connections.
```

---

# ⏹ Stop SQL Server

```bash
docker compose stop
```

Remove the container while preserving the database volume.

```bash
docker compose down
```

Remove everything, including the Docker volume.

```bash
docker compose down -v
```

> **Warning:** `docker compose down -v` permanently deletes all databases stored in the Docker volume.

---

# 🔌 Connect to SQL Server

| Property | Value |
|----------|-------|
| Server | localhost,1433 |
| Authentication | SQL Server Authentication |
| Username | sa |
| Password | YourStrong@Pass123 |

Supported clients:

- SQL Server Management Studio (SSMS)
- Azure Data Studio
- DBeaver

---

# ✅ Test the Connection

```sql
SELECT @@VERSION;
GO

SELECT DB_NAME();
GO
```

---

# 💾 Backup Database

Save the backup inside the mounted `backup` directory.

```sql
BACKUP DATABASE TestDB
TO DISK='/backup/TestDB.bak'
WITH INIT,
COMPRESSION,
STATS = 10;
GO
```

The backup file will be saved to:

```
backup/
└── TestDB.bak
```

---

# 📂 Restore Database

## Step 1 — Copy the Backup File

Place the `.bak` file inside the project `backup` directory.

```
backup/
└── AdventureWorks2022.bak
```

---

## Step 2 — Verify the Backup File

Enter the container.

```bash
docker exec -it sqlserver bash
```

Verify the file.

```bash
ls -lh /backup
```

---

## Step 3 — Display Logical File Names

```sql
RESTORE FILELISTONLY
FROM DISK='/backup/AdventureWorks2022.bak';
GO
```

Example output:

| Logical Name | Type |
|--------------|------|
| AdventureWorks2022 | D |
| AdventureWorks2022_log | L |

---

## Step 4 — Restore the Database

```sql
RESTORE DATABASE AdventureWorks2022
FROM DISK='/backup/AdventureWorks2022.bak'
WITH
MOVE 'AdventureWorks2022'
TO '/var/opt/mssql/data/AdventureWorks2022.mdf',

MOVE 'AdventureWorks2022_log'
TO '/var/opt/mssql/data/AdventureWorks2022_log.ldf',

REPLACE,
STATS = 10;
GO
```

---

## Step 5 — Verify the Restore

```sql
SELECT
    name,
    state_desc
FROM sys.databases;
GO
```

The restored database should appear with a status of **ONLINE**.

---

# 🔧 Useful Docker Commands

Display running containers.

```bash
docker ps
```

View logs.

```bash
docker logs sqlserver
```

Open a shell inside the container.

```bash
docker exec -it sqlserver bash
```

List Docker volumes.

```bash
docker volume ls
```

Inspect the SQL Server volume.

```bash
docker volume inspect sql_data
```

---

# ⚠️ Common Mistakes

- Forgetting to expose port **1433**
- Using a weak SA password
- Not using persistent storage
- Deleting containers without database backups
- Forgetting to mount the backup directory

---

# 🛠 Troubleshooting

## Cannot Connect to SQL Server

```
Cannot Connect
      │
      ▼
Check docker ps
      │
      ▼
Check docker logs
      │
      ▼
Verify Port 1433
      │
      ▼
Verify Firewall
      │
      ▼
Verify SA Password
      │
      ▼
Connect Successfully
```

---

# ✅ Best Practices

- Use Docker Volumes for database persistence.
- Store backup files outside the container.
- Use strong passwords.
- Back up databases regularly.
- Monitor SQL Server logs.
- Keep SQL Server images updated.
- Test backup and restore procedures regularly.

---

# 🌍 Real-World Example

A database administrator deploys a temporary SQL Server container to validate application upgrades and restore production backups before implementing changes in the production environment. This approach minimizes deployment risk and reduces downtime.

---

# 📋 Daily DBA Checklist

- Verify the SQL Server container is running.
- Review Docker and SQL Server logs.
- Test SQL connectivity.
- Verify scheduled backups.
- Monitor available disk space.
- Confirm database health.

---

# 📚 Summary

| Topic | Description |
|--------|-------------|
| Container Platform | Docker |
| SQL Server Version | SQL Server 2022 |
| Default Port | 1433 |
| Management Tools | SSMS, Azure Data Studio, DBeaver |
| Data Persistence | Docker Volumes |
| Backup Location | `/backup` |
| Database Files | `/var/opt/mssql/data` |

---

## Documentation

**Author:** Jose Antonio "Tony" Acebuche

**Version:** 1.0

**Last Updated:** July 2026
