# Python Automation

## Use Cases
- Parse logs
- Check disk usage
- Query APIs
- Automate user management
- Validate backups
- Generate reports

## Example
```python
import shutil

total, used, free = shutil.disk_usage("/")
print(f"Free space: {free / total:.1%}")
```

Python is useful when shell scripts become complex or require structured data processing.
