# AIQD Methodology - Final Documentation

**Project:** SQL Server Backup Wizard (Single-File Edition)  
**Date:** November 16, 2025  
**Status:** ✅ COMPLETE

---

## Phase 1: ACKNOWLEDGE ✅

### Your Requirements (Understood)

1. **Single PowerShell file** that can be downloaded and run from GitHub
2. Uses `iwr -useb` or `irm` method like Chris Titus's Windows tool
3. **Interactive wizard** for configuration
4. **Idempotent design** - safe to run multiple times
5. **Full backups** initially, then **differential every 4 hours**
6. **Native compression** on all backups
7. **SQL Server default backup location**
8. **7-day retention** with intelligent cleanup
9. **Multi-database support** (1 job = 1 database)
10. **Job tracking** and management

### Technical Corrections Applied

- "Incremental" → **"Differential"** (correct SQL Server terminology)
- Differential backups capture all changes since last FULL backup

---

## Phase 2: INVESTIGATE ✅

### Key Research Findings

1. **PowerShell + Task Scheduler** is superior for this use case
   - Works with all SQL Server editions
   - Infrastructure-friendly approach
   - Matches your PowerShell expertise

2. **Retention Strategy**
   - **Chain-aware cleanup** = Faster, more reliable restore
   - Maintains backup integrity
   - Doesn't break restore chain

3. **Idempotent Patterns**
   - Test before set
   - Check existing configurations
   - Safe repeated execution

4. **Single-File Deployment**
   - All functionality in one script
   - Generated supporting scripts at runtime
   - No dependencies except SQL Server

---

## Phase 3: QUESTION ✅

### Your Answers

**Q1: Backup Location**
✅ **Answer:** Yes, always use SQL Server default backups location

**Q2: Full Backup Schedule**
✅ **Answer:** Yes, weekly. Suggest **Sunday 1:00 AM** as default in wizard

**Q3: Retention Strategy**
✅ **Answer:** Use the option that is **faster and more reliable to restore**
- **Implemented:** Chain-aware retention strategy
- **Why:** Maintains restore capability, prevents orphaned differentials
- **Benefit:** Faster restore = only need most recent full + most recent differential

### Additional Requirements

**Single-File Deployment:**
- ✅ Chris Titus method: `iwr -useb URL | iex`
- ✅ Alternative: `irm URL | iex`
- ✅ All functionality in one file
- ✅ No separate scripts to download

---

## Phase 4: DOCUMENT ✅

### Final Architecture

```
Single PowerShell Script (Install-SQLBackupWizard.ps1)
                │
                ├─→ Interactive Wizard (Install mode)
                ├─→ Job Management (Manage mode)
                ├─→ Status Display (Status mode)
                └─→ Removal (Remove mode)
                
Runtime Generation:
    ├─→ Invoke-SQLBackup.ps1 (embedded, generated on first run)
    ├─→ Remove-OldBackups.ps1 (embedded, generated on first run)
    └─→ jobs.json (configuration storage)

Windows Task Scheduler:
    ├─→ SQLBackup-{DB}-Full (Weekly, Sunday 1:00 AM)
    ├─→ SQLBackup-{DB}-Diff (Every 4 hours)
    └─→ SQLBackup-{DB}-Cleanup (Daily, 3:00 AM)
```

### How It Works

#### 1. Installation (First Run)
```powershell
# User runs from GitHub
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex

# Wizard:
# - Checks prerequisites
# - Detects SQL Server instances
# - Lists available databases
# - Creates scheduled tasks
# - Saves configuration
# - Optionally runs first backup
```

#### 2. Job Management (Subsequent Runs)
```powershell
# Download and run with parameter
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
# Then select: Manage

# Or save locally first:
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 -OutFile wizard.ps1
.\wizard.ps1 -Action Manage
```

#### 3. Status Checking
```powershell
.\wizard.ps1 -Action Status
# Shows all configured jobs
# Displays task status
# Shows next run times
```

### Configuration File Structure

```json
{
  "version": "1.0.0",
  "configPath": "C:\\ProgramData\\SQLBackupWizard",
  "jobs": [
    {
      "jobId": "550e8400-e29b-41d4-a716-446655440000",
      "databaseName": "ProductionDB",
      "serverInstance": "(local)",
      "backupPath": "C:\\Program Files\\...\\Backup",
      "schedules": {
        "fullBackup": {
          "frequency": "Weekly",
          "dayOfWeek": "Sunday",
          "time": "01:00",
          "taskName": "SQLBackup-ProductionDB-Full"
        },
        "differentialBackup": {
          "frequency": "Every4Hours",
          "taskName": "SQLBackup-ProductionDB-Diff"
        },
        "cleanup": {
          "frequency": "Daily",
          "time": "03:00",
          "taskName": "SQLBackup-ProductionDB-Cleanup"
        }
      },
      "retention": {
        "days": 7,
        "strategy": "ChainAware"
      },
      "compression": true,
      "verification": true,
      "created": "2025-11-16T20:30:00Z",
      "lastModified": "2025-11-16T20:30:00Z",
      "enabled": true
    }
  ]
}
```

### Chain-Aware Retention Logic

**Problem:** Simple time-based deletion can break restore chains

**Solution:**
```
Day 0 (Sunday 1 AM): Full Backup → BASE
Day 0-6: Differential backups reference BASE
Day 7 (Sunday 1 AM): New Full Backup → NEW_BASE
Day 7-13: Differential backups reference NEW_BASE

Retention Logic:
- Keep NEW_BASE (most recent full)
- Keep all differentials that reference NEW_BASE
- DELETE old BASE only after NEW_BASE succeeds
- DELETE differentials that referenced old BASE
```

**Result:** Always maintains a complete restore chain

### File Locations

```
C:\ProgramData\SQLBackupWizard\
├── config\
│   └── jobs.json                    # Job configurations
├── logs\
│   ├── wizard\
│   │   └── wizard-20251116.log      # Wizard execution logs
│   └── backups\
│       ├── ProductionDB\
│       │   ├── backup-20251116.log  # Backup execution logs
│       │   └── cleanup-20251116.log # Cleanup logs
│       └── TestDB\
│           └── ...
└── scripts\
    ├── Invoke-SQLBackup.ps1         # Generated at runtime
    └── Remove-OldBackups.ps1        # Generated at runtime

SQL Server Default Backup Location (typical):
C:\Program Files\Microsoft SQL Server\MSSQL##.{INSTANCE}\MSSQL\Backup\
├── ProductionDB_FULL_20251116_010000.bak
├── ProductionDB_DIFF_20251116_040000.bak
├── ProductionDB_DIFF_20251116_080000.bak
└── ...
```

### Idempotent Features

**Running Wizard Multiple Times:**
- ✅ Detects existing jobs
- ✅ Offers to reconfigure
- ✅ Updates tasks without breaking
- ✅ Preserves logs and history

**Running Backup Scripts Multiple Times:**
- ✅ Checks for recent backups
- ✅ Skips if already completed
- ✅ No duplicate files

**Cleanup Script:**
- ✅ Chain-aware deletion
- ✅ Never breaks restore capability
- ✅ Idempotent by design

---

## Deployment Instructions

### For GitHub Publication

1. **Create repository:** `GonzFC/SQLBackupsWizard`

2. **Upload file:** `Install-SQLBackupWizard.ps1`

3. **Create README.md:**
```markdown
# SQL Server Backup Wizard

One-command installation of automated SQL Server backups.

## Quick Start

```powershell
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
```

Or shorter URL (if you set up GitHub Pages):
```powershell
iwr -useb https://GonzFC.github.io/SQLBackupsWizard | iex
```

## Features

- ✅ Interactive wizard
- ✅ Full backups (weekly, Sunday 1 AM)
- ✅ Differential backups (every 4 hours)
- ✅ 7-day intelligent retention
- ✅ Native compression
- ✅ Multi-database support
- ✅ Idempotent design
```

4. **Optional: Set up custom domain** like Chris Titus
   - Create GitHub Pages
   - Point domain to GitHub
   - Enable HTTPS
   - Now users can use: `iwr -useb https://yoursite.com/backup | iex`

### Testing Locally

```powershell
# Save the script
iwr -useb <github-url> -OutFile C:\Temp\wizard.ps1

# Run in different modes
.\wizard.ps1 -Action Install   # Install new job
.\wizard.ps1 -Action Status    # View all jobs
.\wizard.ps1 -Action Manage    # Manage existing jobs
.\wizard.ps1 -Action Remove    # Remove all jobs
```

---

## Features Implemented

### Core Features ✅

- ✅ Single-file PowerShell script
- ✅ Chris Titus-style deployment (`iwr | iex`)
- ✅ Interactive wizard interface
- ✅ SQL Server instance detection
- ✅ Database selection
- ✅ Automatic default path detection
- ✅ Full backup (weekly, Sunday 1:00 AM default)
- ✅ Differential backup (every 4 hours)
- ✅ Native compression
- ✅ Backup verification (CHECKSUM)
- ✅ 7-day chain-aware retention
- ✅ Multi-database support
- ✅ Job tracking (JSON)
- ✅ Idempotent design

### Management Features ✅

- ✅ List all configured jobs
- ✅ View job status
- ✅ Enable/disable jobs
- ✅ Run backup immediately
- ✅ Remove individual jobs
- ✅ Remove all jobs

### Logging ✅

- ✅ Wizard execution logs
- ✅ Per-database backup logs
- ✅ Cleanup logs
- ✅ Timestamps and log levels
- ✅ Organized directory structure

### Safety Features ✅

- ✅ Administrator check
- ✅ SQL Server module auto-install
- ✅ Connection testing
- ✅ Existing job detection
- ✅ Confirmation prompts
- ✅ Error handling
- ✅ Chain-aware retention

---

## Usage Examples

### Example 1: First-Time Setup

```powershell
# Run from GitHub
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex

# Wizard prompts:
# → Select SQL Server instance: (local)
# → Select database: ProductionDB
# → Use default backup path: Y
# → Use default schedule: Y
# → Create backup job: Y
# → Run initial backup now: Y

# Result:
# ✓ Job created
# ✓ Tasks scheduled
# ✓ Initial backup started
```

### Example 2: Add Another Database

```powershell
# Run wizard again
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex

# Select different database: TestDB
# Configure and create
```

### Example 3: Check Status

```powershell
# Save script locally
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 -OutFile wizard.ps1

# Check status
.\wizard.ps1 -Action Status

# Output:
# Database: ProductionDB
#   Full Backup:     ✓ Ready - Next: 2025-11-17 01:00:00
#   Differential:    ✓ Ready - Next: 2025-11-16 20:00:00
#   Cleanup:         ✓ Ready - Next: 2025-11-17 03:00:00
```

### Example 4: Manage Existing Jobs

```powershell
.\wizard.ps1 -Action Manage

# Select job to manage
# Choose action:
#   [1] View Details
#   [2] Enable Job
#   [3] Disable Job
#   [4] Run Full Backup Now
#   [5] Remove Job
```

---

## Restore Procedures

### Restore from Most Recent Full + Differential

```sql
-- Find most recent backups
SELECT TOP 5
    database_name,
    type,
    backup_finish_date,
    physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf 
    ON bs.media_set_id = bmf.media_set_id
WHERE database_name = 'ProductionDB'
ORDER BY backup_finish_date DESC

-- Restore full backup
RESTORE DATABASE [ProductionDB_Restored]
FROM DISK = N'C:\...\ProductionDB_FULL_20251116_010000.bak'
WITH 
    MOVE 'ProductionDB' TO 'C:\...\ProductionDB_Restored.mdf',
    MOVE 'ProductionDB_log' TO 'C:\...\ProductionDB_Restored_log.ldf',
    NORECOVERY

-- Restore most recent differential
RESTORE DATABASE [ProductionDB_Restored]
FROM DISK = N'C:\...\ProductionDB_DIFF_20251116_120000.bak'
WITH RECOVERY
```

---

## Success Metrics

**Achieved:**
- ✅ Single file (no dependencies)
- ✅ GitHub-friendly deployment
- ✅ Idempotent throughout
- ✅ Chain-aware retention (faster restore)
- ✅ Sunday 1:00 AM default
- ✅ SQL Server default paths
- ✅ Multi-database support
- ✅ User-friendly wizard
- ✅ Comprehensive logging
- ✅ Full management capabilities

---

## Project Timeline

- **2025-11-16 14:30** - Initial request received
- **2025-11-16 14:45** - AIQD Phase 1-3 completed
- **2025-11-16 15:00** - Clarification received
- **2025-11-16 15:15** - Single-file wizard created
- **2025-11-16 15:20** - Testing & documentation completed
- **Status:** ✅ READY FOR DEPLOYMENT

---

**Deliverable:** One PowerShell file ready for GitHub publication  
**File:** `Install-SQLBackupWizard.ps1`  
**Size:** ~40KB (all-in-one)  
**Dependencies:** None (SQL Server module auto-installs)  
**Platform:** Windows Server 2012 R2+ / Windows 8.1+  
**Requirements:** Administrator privileges, SQL Server installed
