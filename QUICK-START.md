# Quick Start Guide

## Installation Commands (Verified Working ✓)

### Method 1: One-Line Install (Recommended)
```powershell
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
```

### Method 2: Alternative One-Liner
```powershell
irm https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
```

### Method 3: Download First (Most Secure)
```powershell
# Download
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 -OutFile Install-SQLBackupWizard.ps1

# Inspect (optional)
notepad Install-SQLBackupWizard.ps1

# Run
.\Install-SQLBackupWizard.ps1
```

---

## Test the Download on Your Production Computer

Run this test script to verify everything works:

```powershell
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/TEST-DOWNLOAD.ps1 -OutFile test.ps1
.\test.ps1
```

This will:
- ✓ Check GitHub connectivity
- ✓ Download the wizard script
- ✓ Verify file integrity
- ✓ Show you the first few lines

---

## Troubleshooting 404 Errors

If you get a 404 error:

### 1. Check URL (copy/paste exactly)
```
https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1
```

### 2. Clear DNS Cache
```powershell
ipconfig /flushdns
```

### 3. Test GitHub Connection
```powershell
Test-NetConnection raw.githubusercontent.com -Port 443
```

### 4. Try with Verbose Output
```powershell
iwr https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 -OutFile wizard.ps1 -Verbose
```

### 5. Check Proxy Settings (Corporate Networks)
```powershell
# View current proxy
netsh winhttp show proxy

# Bypass proxy for GitHub
$env:no_proxy = "raw.githubusercontent.com"
iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex
```

---

## After Installation

### Check Status of All Jobs
```powershell
.\Install-SQLBackupWizard.ps1 -Action Status
```

### Manage Existing Jobs
```powershell
.\Install-SQLBackupWizard.ps1 -Action Manage
```

### Add Another Database
```powershell
.\Install-SQLBackupWizard.ps1 -Action Install
```

---

## Repository Info

- **GitHub Repo**: https://github.com/GonzFC/SQLBackupsWizard
- **Raw Script URL**: https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1
- **File Size**: 41 KB
- **Status**: ✅ Public & Accessible

---

## Quick Facts

| What | Details |
|------|---------|
| **Full Backups** | Weekly, Sunday 1:00 AM |
| **Differential Backups** | Every 4 hours |
| **Retention** | 7 days (chain-aware) |
| **Compression** | Native SQL Server |
| **Works With** | SQL Express, Standard, Enterprise |
| **Platform** | Windows Server 2012 R2+ |
| **Requirements** | Administrator, SQL Server |

---

**Ready to go!** 🚀
