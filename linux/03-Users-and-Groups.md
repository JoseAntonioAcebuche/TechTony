# Users and Groups

## User Management
```bash
sudo useradd -m alice
sudo passwd alice
sudo usermod -aG wheel alice
id alice
getent passwd alice
```

## Group Management
```bash
sudo groupadd linuxadmins
sudo usermod -aG linuxadmins alice
getent group linuxadmins
```

## Administration
Review `/etc/passwd`, `/etc/shadow`, and `/etc/group`.

## Best Practices
Use groups for access control instead of assigning permissions individually to every user. Apply least privilege.
