# SELinux

## Modes
```bash
getenforce
sestatus
```

Modes include Enforcing, Permissive, and Disabled.

## Useful Commands
```bash
ls -Z
restorecon -Rv /var/www
semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
```

## Troubleshooting
Use audit logs and `ausearch` or `audit2why` to understand denials. Do not disable SELinux as the first troubleshooting step.
