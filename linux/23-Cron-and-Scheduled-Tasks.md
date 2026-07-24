# Cron and Scheduled Tasks

## Crontab
```bash
crontab -e
```

Example:
```text
0 2 * * * /usr/local/bin/backup.sh
```

## systemd Timers
For modern Linux systems, systemd timers can provide better logging and dependency management.

## Best Practice
Log scheduled jobs and monitor failures.
