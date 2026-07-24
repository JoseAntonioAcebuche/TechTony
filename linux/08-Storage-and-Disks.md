# Storage and Disk Administration

## Identify Storage
```bash
lsblk
sudo fdisk -l
sudo blkid
df -h
du -sh /var/*
```

## Disk Troubleshooting
Check capacity with `df -h`, identify large directories with `du`, and inspect kernel messages with `dmesg`.

## Administration
Learn partitioning, mount points, UUIDs, filesystem creation, and disk health monitoring.
