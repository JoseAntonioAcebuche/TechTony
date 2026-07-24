# Process Management

## Commands
```bash
ps aux
top
pgrep nginx
pstree
kill PID
kill -9 PID
jobs
bg
fg
```

## Troubleshooting
Find high CPU or memory processes with `top` or `ps`.

## Best Practice
Use normal termination signals first. Reserve `kill -9` for processes that do not respond to graceful termination.
