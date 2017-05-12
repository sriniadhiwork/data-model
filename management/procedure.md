# Procedures for getting audit data 

## Exract all audit logs
```sh
cd /path/to/auditQuery.sql
psql -Upulse -f auditQuery.sql pulse
```

## Create post-activation report package
```sh
cd /path/to/exportAuditReports.sh
./exportAuditReports.sh --host=localhost --user=user --start=YYYY-MM-DD --end=YYYY-MM-DD
```
All arguments are optional.
