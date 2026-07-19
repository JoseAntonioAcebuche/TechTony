# 🐳 SQL Server 2022 on Docker Guide

**Author:** Jose Antonio "Tony" Acebuche

**Category:** SQL Server Administration

**Purpose:** Learn how to deploy, manage, back up, restore, and troubleshoot Microsoft SQL Server running in Docker for development and administration practice.

---

# 📖 Overview

Microsoft SQL Server can run inside a Docker container on Windows, Linux, or macOS. Docker provides a lightweight, portable, and isolated environment that is ideal for learning SQL Server Administration without installing SQL Server directly on the host.

---

# Why Use SQL Server in Docker?

- Fast deployment
- Easy reset and recreation
- Isolated environment
- Persistent storage using Docker Volumes
- Perfect for DBA labs and testing

---

# Prerequisites

- Docker Desktop (Windows/macOS) or Docker Engine (Linux)
- 4 GB RAM minimum
- Port 1433 available
- SSMS or Azure Data Studio

---

# Pull SQL Server Image

```bash
docker pull mcr.microsoft.com/mssql/server:2022-latest
```

---

# Create SQL Server Container

```bash
docker run -e "ACCEPT_EULA=Y" \
-e "MSSQL_SA_PASSWORD=YourStrong@Pass123" \
-p 1433:1433 \
--name sqlserver2022 \
-d mcr.microsoft.com/mssql/server:2022-latest
```

---

# Verify Container

```bash
docker ps
docker logs sqlserver2022
```

---

# Connect using SSMS

Server: localhost

Authentication: SQL Server Authentication

User: sa

Password: YourStrong@Pass123

---

# Test Connection

```sql
SELECT @@VERSION;
GO
SELECT DB_NAME();
GO
```

---

# Docker Compose

```yaml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sqlserver
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "YourStrong@Pass123"
    ports:
      - "1433:1433"
    restart: unless-stopped
    volumes:
      - sql_data:/var/opt/mssql

volumes:
  sql_data:
```

Start:

```bash
docker compose up -d
```

Stop:

```bash
docker compose down
```

---

# Backup Database

```sql
BACKUP DATABASE TestDB
TO DISK='/var/opt/mssql/backup/TestDB.bak';
```

---

# Restore Database

```sql
RESTORE DATABASE TestDB
FROM DISK='/var/opt/mssql/backup/TestDB.bak';
```

---

# Best Practices

- Use Docker Volumes for persistence.
- Use strong SA passwords.
- Back up databases regularly.
- Monitor container logs.
- Keep SQL Server image updated.

---

# Common Mistakes

- Forgetting to expose port 1433.
- Using weak passwords.
- Storing data without a persistent volume.
- Deleting the container without backups.

---

# Real-World Example

A DBA creates a disposable SQL Server container to test database upgrades before applying them to the production on-premises SQL Server, reducing risk and downtime.

---

# Daily Checklist

- [ ] Verify container is running
- [ ] Check logs
- [ ] Test SQL connectivity
- [ ] Verify backups
- [ ] Monitor disk usage

---

# Docker Troubleshooting Flow

```text
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
Verify SA Password
      │
      ▼
Connect Successfully
```

---

# Summary

| Topic | Description |
|-------|-------------|
| Docker | Container Platform |
| SQL Server Image | Microsoft SQL Server 2022 |
| Port | 1433 |
| Tool | SSMS / Azure Data Studio |
| Persistence | Docker Volumes |

---

**Documentation by:**

**Jose Antonio "Tony" Acebuche**
