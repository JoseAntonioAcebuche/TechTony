# File Permissions

## Permission Model
Linux permissions include owner, group, and others.

```bash
ls -l file.txt
chmod 640 file.txt
chown alice:linuxadmins file.txt
```

## Numeric Permissions
- `7` = read/write/execute
- `6` = read/write
- `5` = read/execute
- `4` = read

## Advanced
Learn setuid, setgid, sticky bit, ACLs, and `umask`.

```bash
getfacl file.txt
setfacl -m u:alice:r file.txt
```
