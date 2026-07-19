# Rsync Tutorial (Linux)

## What is rsync?

`rsync` is a command-line utility used to efficiently copy and synchronize files and directories. It is commonly used for:

- File and directory backups
- Synchronizing folders
- Local and remote file transfers
- Incremental backups (copies only changed files)

Unlike `cp`, `rsync` transfers only the differences between the source and destination, making it much faster for repeated backups.

---

# Basic Syntax

```bash
rsync [OPTIONS] SOURCE DESTINATION
```

Example:

```bash
rsync -av source/ destination/
```

---

# Common Options

| Option | Description |
|---------|-------------|
| `-a` | Archive mode (preserves permissions, ownership, timestamps, symbolic links, etc.) |
| `-v` | Verbose output |
| `-h` | Human-readable file sizes |
| `--progress` | Display file transfer progress |
| `--delete` | Delete files in the destination that no longer exist in the source |
| `-z` | Compress data during transfer (useful for remote backups) |
| `-n` | Dry run (simulate the operation without copying files) |

A commonly used combination is:

```bash
rsync -avh
```

---

# Example 1 - Back Up the /etc Directory

Create a backup directory:

```bash
mkdir -p ~/backup
```

Copy the entire `/etc` directory:

```bash
sudo rsync -avh /etc/ ~/backup/etc/
```

Directory structure after backup:

```
~/backup/
└── etc/
    ├── passwd
    ├── shadow
    ├── hostname
    ├── hosts
    └── ...
```

---

# Example 2 - Display Transfer Progress

```bash
sudo rsync -avh --progress /etc/ ~/backup/etc/
```

Example output:

```
passwd
      2.1K 100%   25MB/s

hosts
      410B 100%

shadow
      1.6K 100%
```

---

# Example 3 - Dry Run

Simulate the backup without copying any files.

```bash
sudo rsync -avhn /etc/ ~/backup/etc/
```

This command displays which files would be copied.

---

# Example 4 - Incremental Backup

Run the same command again after making changes to `/etc`.

```bash
sudo rsync -avh /etc/ ~/backup/etc/
```

Only new or modified files are copied.

---

# Example 5 - Mirror the Source Directory

```bash
sudo rsync -avh --delete /etc/ ~/backup/etc/
```

> **Warning**
>
> The `--delete` option removes files from the destination that no longer exist in the source. Use it carefully.

---

# Example 6 - Back Up to an External Drive

Assume your external drive is mounted at:

```
/media/tony/BackupDrive
```

Run:

```bash
sudo rsync -avh /etc/ /media/tony/BackupDrive/etc/
```

---

# Example 7 - Remote Backup Using SSH

Copy the `/etc` directory to a remote Linux server.

```bash
rsync -avh /etc/ user@192.168.1.100:/backup/etc/
```

---

# Example 8 - Back Up a Single File

```bash
sudo rsync -avh /etc/hosts ~/backup/
```

---

# Comparing cp and rsync

## Using cp

```bash
cp -r /etc ~/backup/
```

- Copies all files every time
- No incremental synchronization

---

## Using rsync

```bash
rsync -avh /etc/ ~/backup/etc/
```

- Copies only new or modified files
- Faster for repeated backups
- Preserves file metadata

---

# Restoring a Backup

Restore the backup to the original location:

```bash
sudo rsync -avh ~/backup/etc/ /etc/
```

> **Warning**
>
> Restoring files to `/etc` may overwrite important system configuration files. Ensure you have a current backup before restoring.

---

# Verify the Backup

List the backed-up files:

```bash
ls ~/backup/etc
```

Check the total directory size:

```bash
du -sh ~/backup/etc
```

Count the total number of files:

```bash
find ~/backup/etc | wc -l
```

---

# Real-World Example

Back up the `/etc` directory before modifying SSH configuration.

Create the backup:

```bash
mkdir -p ~/backup
sudo rsync -avh /etc/ ~/backup/etc/
```

Edit the configuration file:

```bash
sudo nano /etc/ssh/sshd_config
```

If a mistake occurs, restore the backup:

```bash
sudo rsync -avh ~/backup/etc/ /etc/
```

---

# Best Practices

- Always use `-a` (archive mode) for backups.
- Add `--progress` for large file transfers.
- Use `-n` (dry run) before running commands with `--delete`.
- Create backups before modifying system configuration files.
- Test your restore procedure regularly to ensure backups are usable.
- Store backups on a separate disk or remote server for disaster recovery.

---

# Cheat Sheet

```bash
# Local backup
sudo rsync -avh /etc/ ~/backup/etc/

# Backup with progress
sudo rsync -avh --progress /etc/ ~/backup/etc/

# Dry run
sudo rsync -avhn /etc/ ~/backup/etc/

# Mirror source to destination
sudo rsync -avh --delete /etc/ ~/backup/etc/

# Restore backup
sudo rsync -avh ~/backup/etc/ /etc/

# Remote backup over SSH
rsync -avh /etc/ user@server:/backup/etc/

# Backup a single file
sudo rsync -avh /etc/hosts ~/backup/

# Check backup size
du -sh ~/backup/etc

# Count backed-up files
find ~/backup/etc | wc -l
```
