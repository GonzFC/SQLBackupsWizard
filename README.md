# SQL Server Backup Wizard 🧙‍♂️

**One-command automated SQL Server backup configuration**

Inspired by Chris Titus Tech's Windows Utility, this wizard provides a simple, interactive way to configure enterprise-grade SQL Server backups.

## Quick Start

```powershell
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
```

**Alternative method:**
```powershell
irm https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
```

## Features

- ✅ **Interactive Wizard** - No SQL expertise required
- ✅ **Full Backups** - Weekly (Sunday 1:00 AM default)
- ✅ **Differential Backups** - Every 4 hours
- ✅ **Native Compression** - 50-80% space savings
- ✅ **7-Day Retention** - Chain-aware intelligent cleanup
- ✅ **Multi-Database Support** - Configure backups for multiple databases
- ✅ **Idempotent Design** - Safe to run multiple times
- ✅ **Automatic Verification** - CHECKSUM validation on all backups
- ✅ **Comprehensive Logging** - Track every backup operation
- ✅ **Job Management** - Enable, disable, or remove jobs easily

## What It Does

1. **Detects** your SQL Server instances and databases
2. **Creates** compressed full and differential backups
3. **Schedules** automatic backups via Windows Task Scheduler
4. **Maintains** 7-day retention with chain-aware cleanup
5. **Tracks** all configured jobs in a JSON configuration file

## Architecture

```
Weekly Full Backup (Sunday 1 AM)
         ↓
  Differential Backups
    (Every 4 Hours)
         ↓
  Chain-Aware Cleanup
    (Daily at 3 AM)
```

**Backup Chain Example:**
```
Sunday:  FULL backup     ← BASE
Monday:  DIFF (depends on Sunday FULL)
Tuesday: DIFF (depends on Sunday FULL)
...
Next Sunday: New FULL    ← NEW BASE
Old FULL + old DIFFs deleted (chain-aware)
```

## Prerequisites

- Windows Server 2012 R2+ or Windows 8.1+
- SQL Server (any edition: Express, Standard, Enterprise)
- Administrator privileges
- PowerShell 5.1+

## Installation Modes

### Install Mode (Default)
Configure a new backup job interactively:
```powershell
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
```

### Status Mode
View all configured backup jobs:
```powershell
# Download first
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 -OutFile wizard.ps1

# Run status check
.\wizard.ps1 -Action Status
```

### Manage Mode
Manage existing backup jobs:
```powershell
.\wizard.ps1 -Action Manage
```

Options:
- View job details
- Enable/disable jobs
- Run backup immediately
- Remove jobs

### Remove Mode
Remove all backup jobs:
```powershell
.\wizard.ps1 -Action Remove
```

## Configuration

All configuration is stored in:
```
C:\ProgramData\SQLBackupWizard\
├── config\jobs.json          # Job configurations
├── logs\                     # Execution logs
└── scripts\                  # Generated backup scripts
```

Backups are stored in SQL Server's default backup directory (typically):
```
C:\Program Files\Microsoft SQL Server\MSSQL##.{INSTANCE}\MSSQL\Backup\
```

## Backup Schedule

| Type | Frequency | Default Time |
|------|-----------|--------------|
| **Full Backup** | Weekly | Sunday 1:00 AM |
| **Differential Backup** | Every 4 Hours | 00:00, 04:00, 08:00, 12:00, 16:00, 20:00 |
| **Cleanup** | Daily | 3:00 AM |

## Retention Policy

**7-Day Chain-Aware Retention:**
- Keeps at least one full backup
- Keeps all differentials that depend on kept full backup
- Deletes old full backups only after new full succeeds
- Ensures you can always restore

**Why Chain-Aware?**
- Faster restore (only need: most recent full + most recent diff)
- More reliable (never breaks restore capability)
- Space efficient (removes only truly obsolete backups)

## Restore Example

To restore from the most recent backup:

```sql
-- Find latest backups
SELECT TOP 5
    database_name,
    CASE type 
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
    END AS backup_type,
    backup_finish_date,
    physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE database_name = 'YourDatabase'
ORDER BY backup_finish_date DESC

-- Restore full backup (with NORECOVERY)
RESTORE DATABASE [YourDatabase_Restored]
FROM DISK = N'C:\...\YourDatabase_FULL_20251116_010000.bak'
WITH 
    MOVE 'YourDatabase' TO 'C:\...\YourDatabase_Restored.mdf',
    MOVE 'YourDatabase_log' TO 'C:\...\YourDatabase_Restored_log.ldf',
    NORECOVERY

-- Restore most recent differential (with RECOVERY)
RESTORE DATABASE [YourDatabase_Restored]
FROM DISK = N'C:\...\YourDatabase_DIFF_20251116_120000.bak'
WITH RECOVERY
```

## Logs

Logs are organized by database:

```
C:\ProgramData\SQLBackupWizard\logs\
├── wizard\
│   └── wizard-20251116.log
└── backups\
    ├── ProductionDB\
    │   ├── backup-20251116.log
    │   └── cleanup-20251116.log
    └── TestDB\
        └── backup-20251116.log
```

Sample log entry:
```
[2025-11-16 14:30:15] [INFO] Starting full backup for database: ProductionDB
[2025-11-16 14:30:16] [INFO] Backup path: C:\Program Files\...\Backup
[2025-11-16 14:30:16] [INFO] Compression: Enabled
[2025-11-16 14:30:45] [SUCCESS] Backup completed: ProductionDB_FULL_20251116_143016.bak
[2025-11-16 14:30:45] [INFO] File size: 1.2 GB (compressed from 3.5 GB)
[2025-11-16 14:30:46] [SUCCESS] Backup verification passed!
```

## Troubleshooting

### SQL Server Module Not Found
The wizard automatically installs the SqlServer module. If it fails:
```powershell
Install-Module -Name SqlServer -Force -AllowClobber
```

### Permission Errors
Ensure you're running PowerShell as Administrator:
```powershell
# Check if admin
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

### Task Not Running
Check Task Scheduler:
```
Task Scheduler → Task Scheduler Library → SQLBackup-{DatabaseName}-*
```

View task history and last run result.

### View Backup History
```sql
SELECT TOP 20
    database_name,
    CASE type 
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
    END AS backup_type,
    backup_start_date,
    backup_finish_date,
    DATEDIFF(SECOND, backup_start_date, backup_finish_date) AS duration_sec,
    CAST(backup_size / 1024 / 1024 AS DECIMAL(10,2)) AS size_mb,
    CAST(compressed_backup_size / 1024 / 1024 AS DECIMAL(10,2)) AS compressed_mb
FROM msdb.dbo.backupset
WHERE database_name = 'YourDatabase'
ORDER BY backup_finish_date DESC
```

## Why This Wizard?

**Traditional Approach:**
- Write T-SQL backup scripts
- Create SQL Server Agent jobs (not available in Express)
- Configure maintenance plans
- Set up cleanup jobs
- Test and debug

**This Wizard:**
- One command
- Interactive prompts
- Automatic configuration
- Works with all editions
- Idempotent design

## Security Notes

- Scheduled tasks run as SYSTEM account
- Backups use SQL Server service account permissions
- No credentials stored in configuration
- Logs may contain database names (adjust permissions if sensitive)

## Comparison

| Feature | SQL Agent | This Wizard |
|---------|-----------|-------------|
| **SQL Express Support** | ❌ No | ✅ Yes |
| **One-Command Install** | ❌ No | ✅ Yes |
| **Idempotent** | ❌ No | ✅ Yes |
| **Chain-Aware Retention** | ❌ Manual | ✅ Automatic |
| **External Config** | ❌ msdb | ✅ JSON |
| **Easy Management** | ⚠️ SSMS | ✅ CLI |

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - Use freely in personal and commercial projects

## Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: This README + inline comments

## Roadmap

Future enhancements:
- [ ] Email notifications
- [ ] Remote SQL Server support
- [ ] Custom retention policies (monthly, yearly)
- [ ] Backup to cloud storage (Azure Blob, S3)
- [ ] GUI version
- [ ] Transaction log backups (for Full recovery model)

## Credits

Inspired by:
- [Chris Titus Tech's Windows Utility](https://github.com/ChrisTitusTech/winutil)
- SQL Server DBA best practices
- PowerShell community

## Author

**Your Name**  
GitHub: [@GonzFC](https://github.com/GonzFC)

---

**⭐ If this wizard helps you, please star the repository!**

## Quick Links

- [Installation](#quick-start)
- [Features](#features)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Restore Example](#restore-example)
