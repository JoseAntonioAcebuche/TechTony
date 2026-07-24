# Linux File System

## Overview
Linux uses a hierarchical filesystem beginning at `/`.

## Important Directories
- `/etc` - system configuration
- `/var` - logs and changing application data
- `/home` - user home directories
- `/opt` - optional applications
- `/usr` - user applications and libraries
- `/tmp` - temporary files
- `/boot` - boot files
- `/dev` - device files
- `/proc` - process and kernel information
- `/sys` - kernel and hardware information

## Useful Commands
```bash
find /var -type f -name "*.log"
du -sh /var/*
df -h
ls -lah /etc
```

## Troubleshooting
When storage is consumed unexpectedly, start with `df -h`, then use `du` to locate large directories.
