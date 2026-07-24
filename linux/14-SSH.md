# SSH Administration

## Key Authentication
```bash
ssh-keygen -t ed25519
ssh-copy-id user@server
ssh user@server
```

## Hardening
- Disable direct root login.
- Prefer key authentication.
- Restrict administrative access.
- Use firewall rules.
- Monitor authentication logs.

## Troubleshooting
```bash
ssh -vvv user@server
journalctl -u sshd
```
