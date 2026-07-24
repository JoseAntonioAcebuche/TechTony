# Bash Scripting

## Example
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Hostname: $(hostname)"
echo "Disk usage:"
df -h /
```

## Best Practices
Use `set -euo pipefail`, quote variables, validate input, return meaningful exit codes, and log important actions.
