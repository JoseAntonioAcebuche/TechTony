# Filesystems and fstab

## Mount a Filesystem
```bash
sudo mount /dev/sdb1 /mnt/data
sudo umount /mnt/data
```

## Persistent Mount
Use the UUID in `/etc/fstab`.

```bash
sudo blkid
sudo mount -a
```

## Best Practice
Always run `mount -a` after editing `/etc/fstab` before rebooting. A bad entry can prevent normal boot.
