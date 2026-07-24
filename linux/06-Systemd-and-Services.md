# systemd and Services

## Service Operations
```bash
systemctl status sshd
sudo systemctl start sshd
sudo systemctl stop sshd
sudo systemctl restart sshd
sudo systemctl enable sshd
sudo systemctl disable sshd
```

## Troubleshooting
```bash
systemctl --failed
journalctl -u sshd
systemctl cat sshd
```

## Best Practice
Use systemd unit dependencies and logs to diagnose service failures instead of repeatedly restarting services without investigation.
