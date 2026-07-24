# Linux Fundamentals

## Overview
Linux administration starts with the command line, shell navigation, system information, and basic file operations.

## Common Commands
```bash
pwd
ls -lah
cd /var/log
cp source.txt backup.txt
mv old.txt new.txt
rm file.txt
mkdir -p /opt/lab
cat /etc/os-release
uname -a
hostnamectl
```

## Practice
- Identify the Linux distribution.
- Check kernel and hostname information.
- Create, copy, move, and remove files.
- Navigate the filesystem using absolute and relative paths.

## Best Practice
Use `rm` carefully, verify the current directory with `pwd`, and prefer `rm -i` for interactive deletion.
