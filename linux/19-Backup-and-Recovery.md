# Backup and Recovery

## Backup Concepts
- Full backup
- Incremental backup
- Differential backup
- Snapshot
- Offsite backup

## rsync Example
```bash
rsync -avh --delete /data/ /backup/data/
```

## Verification
A backup is not complete until restoration has been tested.

## Best Practice
Define RPO and RTO, maintain multiple backup copies, protect backups from unauthorized access, and periodically perform restore tests.
