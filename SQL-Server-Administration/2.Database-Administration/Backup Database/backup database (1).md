# 💾 SQL Server Manual Database Backup Procedure

**Author:** Jose Antonio Acebuche  
**Purpose:** To safely perform a manual backup of a SQL Server database  
**Use Case:** Backup of parking system databases before troubleshooting or maintenance

---

## 🧰 Requirements:
- SQL Server Management Studio (SSMS)
- Administrator or sufficient SQL Server access
- Target location with available storage (e.g., Drive C: or D:)

---

## 📝 Step-by-Step Procedure

### 1. Launch SQL Server Management Studio (SSMS)
- Open SSMS and connect to the local server instance where the database is hosted.

---

### 2. Select the Database
- In the **Object Explorer**, expand the `Databases` node.
- Right-click the target database (e.g., `LocalDB`) → **Tasks** → **Back Up...**

---

### 3. Configure the Backup
- In the **Back Up Database** window:
  - **Backup Type**: Select `Full`
  - **Backup Component**: Database
  - **Destination**:  
    - Click **Remove** to clear any old paths  
    - Click **Add** and select a path like:  
      `C:\DB_Backup_YYYYMMDD.bak`

---

### 4. Execute the Backup
- Click **OK** to start the backup.
- Wait for confirmation:  
  **"The backup of database 'YourDB' completed successfully."**

---

## ✅ Verification
- Navigate to the backup location (`C:\`) and confirm the `.bak` file exists.
- Check file size — a zero-byte file usually means the backup failed.

---

## 📌 Notes
- Replace `YYYYMMDD` with the current date for easy identification.
- Always ensure there’s enough disk space before starting.
- For large databases, consider storing on external or dedicated drives (e.g., `D:\`).

---

## 📂 Example Output:
C:\DB_Backup_20250627.bak
