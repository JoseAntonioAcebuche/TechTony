# Firewall Administration

## firewalld
```bash
sudo firewall-cmd --state
sudo firewall-cmd --list-all
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
```

## Best Practice
Allow only required ports and services. Document every production firewall rule.
