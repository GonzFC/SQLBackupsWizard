#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    SQL Server Backup Wizard - Single-File Installation & Configuration Tool

.DESCRIPTION
    Interactive wizard to configure automated SQL Server database backups with:
    - Full backups (weekly, Sunday 1:00 AM default)
    - Differential backups (every 4 hours)
    - 7-day intelligent retention (chain-aware)
    - Native compression
    - Idempotent design
    - Multi-database support

.EXAMPLE
    # Run directly from GitHub
    iwr -useb https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1 | iex

.EXAMPLE
    # Run locally
    .\Install-SQLBackupWizard.ps1

.NOTES
    Author: Your Infrastructure Team
    Version: 1.0.0
    Date: 2025-11-16
    Requires: Administrator privileges, SQL Server installed
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Install", "Manage", "Remove", "Status")]
    [string]$Action = "Install"
)

# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================

$script:Config = @{
    Version = "1.0.0"
    BasePath = "C:\ProgramData\SQLBackupWizard"
    ConfigFile = "C:\ProgramData\SQLBackupWizard\config\jobs.json"
    LogPath = "C:\ProgramData\SQLBackupWizard\logs"
    ScriptPath = "C:\ProgramData\SQLBackupWizard\scripts"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    $params = @{
        Object = $Message
        ForegroundColor = $Color
    }
    if ($NoNewline) { $params.Add("NoNewline", $true) }
    
    Write-Host @params
}

function Write-Header {
    param([string]$Title)
    
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════" -Color Cyan
    Write-ColorOutput "  $Title" -Color Cyan
    Write-ColorOutput "═══════════════════════════════════════════════════════════" -Color Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" -Color Green
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" -Color Red
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" -Color Yellow
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" -Color Cyan
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogFile = $null
    )
    
    if (-not $LogFile) {
        $LogFile = Join-Path $script:Config.LogPath "wizard\wizard-$(Get-Date -Format 'yyyyMMdd').log"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $LogFile -Value $logMessage
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-SQLServerModule {
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Warning "SqlServer PowerShell module not found."
        Write-Info "Installing SqlServer module..."
        
        try {
            Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
            Import-Module SqlServer -ErrorAction Stop
            Write-Success "SqlServer module installed successfully"
            return $true
        }
        catch {
            Write-Error "Failed to install SqlServer module: $_"
            return $false
        }
    }
    else {
        Import-Module SqlServer -ErrorAction SilentlyContinue
        return $true
    }
}

function Get-SQLServerInstances {
    try {
        $instances = @()

        # Method 1: Check registry for installed instances
        try {
            $reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
            $regKey = $reg.OpenSubKey("SOFTWARE\Microsoft\Microsoft SQL Server")

            if ($regKey) {
                $instanceNames = $regKey.GetValue("InstalledInstances")
                if ($instanceNames) {
                    foreach ($instance in $instanceNames) {
                        if ($instance -eq "MSSQLSERVER") {
                            $instances += "localhost"
                        }
                        else {
                            $instances += "localhost\$instance"
                        }
                    }
                }
            }
        }
        catch {
            # Registry method failed, continue to next method
        }

        # Method 2: Check for running SQL Server services
        if ($instances.Count -eq 0) {
            try {
                $sqlServices = Get-Service | Where-Object {
                    $_.Name -match '^MSSQL\$' -or $_.Name -eq 'MSSQLSERVER'
                } | Where-Object { $_.Status -eq 'Running' }

                foreach ($service in $sqlServices) {
                    if ($service.Name -eq 'MSSQLSERVER') {
                        $instances += "localhost"
                    }
                    else {
                        $instanceName = $service.Name -replace '^MSSQL\$', ''
                        $instances += "localhost\$instanceName"
                    }
                }
            }
            catch {
                # Service method failed
            }
        }

        # Method 3: Default fallback
        if ($instances.Count -eq 0) {
            Write-Warning "No SQL Server instances detected via registry or services. Using default 'localhost'."
            $instances += "localhost"
        }

        # Remove duplicates and return
        return $instances | Select-Object -Unique
    }
    catch {
        Write-Warning "Error detecting SQL Server instances: $_"
        return @("localhost")
    }
}

function Get-SQLServerDatabases {
    param([string]$ServerInstance)
    
    try {
        $query = @"
SELECT name 
FROM sys.databases 
WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')
  AND state_desc = 'ONLINE'
ORDER BY name
"@
        
        $databases = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query -ErrorAction Stop
        return $databases.name
    }
    catch {
        Write-Error "Failed to retrieve databases from $ServerInstance : $_"
        return @()
    }
}

function Get-SQLDefaultBackupPath {
    param([string]$ServerInstance)
    
    try {
        $query = @"
DECLARE @BackupPath NVARCHAR(500)
EXEC master.dbo.xp_instance_regread 
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @BackupPath OUTPUT
SELECT @BackupPath AS BackupPath
"@
        
        $result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query -ErrorAction Stop
        return $result.BackupPath
    }
    catch {
        Write-Error "Failed to get backup path: $_"
        return $null
    }
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

function Initialize-WizardEnvironment {
    Write-Info "Initializing environment..."
    
    # Create directory structure
    $directories = @(
        $script:Config.BasePath
        (Join-Path $script:Config.BasePath "config")
        (Join-Path $script:Config.BasePath "logs\wizard")
        (Join-Path $script:Config.BasePath "logs\backups")
        $script:Config.ScriptPath
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
    
    # Initialize config file if it doesn't exist
    if (-not (Test-Path $script:Config.ConfigFile)) {
        $initialConfig = @{
            version = $script:Config.Version
            configPath = $script:Config.BasePath
            jobs = @()
        }
        
        $initialConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $script:Config.ConfigFile
    }
    
    Write-Success "Environment initialized"
}

function Get-JobConfiguration {
    if (-not (Test-Path $script:Config.ConfigFile)) {
        return @{
            version = $script:Config.Version
            configPath = $script:Config.BasePath
            jobs = @()
        }
    }
    
    try {
        $config = Get-Content -Path $script:Config.ConfigFile -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Error "Failed to read configuration: $_"
        return $null
    }
}

function Save-JobConfiguration {
    param([object]$Config)
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:Config.ConfigFile
        return $true
    }
    catch {
        Write-Error "Failed to save configuration: $_"
        return $false
    }
}

function Find-ExistingJob {
    param(
        [string]$DatabaseName,
        [string]$ServerInstance
    )
    
    $config = Get-JobConfiguration
    $existingJob = $config.jobs | Where-Object { 
        $_.databaseName -eq $DatabaseName -and $_.serverInstance -eq $ServerInstance 
    }
    
    return $existingJob
}

# ============================================================================
# BACKUP SCRIPT GENERATION
# ============================================================================

function New-BackupScript {
    $scriptContent = @'
#Requires -Version 5.1
param(
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerInstance,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Full", "Differential")]
    [string]$BackupType,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath,
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 7
)

$ErrorActionPreference = "Stop"

function Write-BackupLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $logPath = "C:\ProgramData\SQLBackupWizard\logs\backups\$DatabaseName"
    if (-not (Test-Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    
    $logFile = Join-Path $logPath "backup-$(Get-Date -Format 'yyyyMMdd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

try {
    # Import SQL Server module
    Import-Module SqlServer -ErrorAction Stop
    
    Write-BackupLog "========================================" "INFO"
    Write-BackupLog "SQL Server Backup - $BackupType" "INFO"
    Write-BackupLog "========================================" "INFO"
    Write-BackupLog "Database: $DatabaseName" "INFO"
    Write-BackupLog "Instance: $ServerInstance" "INFO"
    Write-BackupLog "Type: $BackupType" "INFO"
    
    # Get backup path if not provided
    if (-not $BackupPath) {
        $query = @"
DECLARE @BackupPath NVARCHAR(500)
EXEC master.dbo.xp_instance_regread 
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @BackupPath OUTPUT
SELECT @BackupPath AS BackupPath
"@
        $result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
        $BackupPath = $result.BackupPath
    }
    
    Write-BackupLog "Backup path: $BackupPath" "INFO"
    
    # Generate backup filename
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupTypeShort = if ($BackupType -eq "Full") { "FULL" } else { "DIFF" }
    $backupFile = Join-Path $BackupPath "${DatabaseName}_${backupTypeShort}_${timestamp}.bak"
    
    Write-BackupLog "Backup file: $backupFile" "INFO"
    
    # For differential, verify full backup exists
    if ($BackupType -eq "Differential") {
        $checkQuery = @"
SELECT COUNT(*) AS BackupCount
FROM msdb.dbo.backupset
WHERE database_name = '$DatabaseName'
  AND type = 'D'
"@
        $result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $checkQuery
        
        if ($result.BackupCount -eq 0) {
            Write-BackupLog "No full backup found! Cannot perform differential backup." "ERROR"
            exit 1
        }
    }
    
    # Build backup command
    $backupQuery = @"
BACKUP DATABASE [$DatabaseName]
TO DISK = N'$backupFile'
WITH 
    $(if ($BackupType -eq "Differential") { "DIFFERENTIAL," })
    COMPRESSION,
    CHECKSUM,
    STATS = 10,
    INIT,
    NAME = N'$DatabaseName $BackupType Backup',
    DESCRIPTION = N'$BackupType backup created on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")'
"@
    
    # Execute backup
    $startTime = Get-Date
    Write-BackupLog "Starting backup..." "INFO"
    
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $backupQuery -QueryTimeout 3600 -Verbose 4>&1 | 
        ForEach-Object { Write-BackupLog $_.Message "INFO" }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    # Get file size
    if (Test-Path $backupFile) {
        $fileSize = (Get-Item $backupFile).Length / 1MB
        Write-BackupLog "Backup completed successfully!" "SUCCESS"
        Write-BackupLog "Duration: $([math]::Round($duration, 2)) seconds" "INFO"
        Write-BackupLog "File size: $([math]::Round($fileSize, 2)) MB" "INFO"
        
        # Verify backup
        Write-BackupLog "Verifying backup integrity..." "INFO"
        $verifyQuery = "RESTORE VERIFYONLY FROM DISK = N'$backupFile' WITH CHECKSUM"
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $verifyQuery -QueryTimeout 600
        Write-BackupLog "Backup verification passed!" "SUCCESS"
        
        exit 0
    }
    else {
        Write-BackupLog "Backup file not found after backup operation!" "ERROR"
        exit 1
    }
}
catch {
    Write-BackupLog "Backup failed: $_" "ERROR"
    Write-BackupLog "Error details: $($_.Exception.Message)" "ERROR"
    exit 1
}
'@

    $scriptPath = Join-Path $script:Config.ScriptPath "Invoke-SQLBackup.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force
    return $scriptPath
}

function New-CleanupScript {
    $scriptContent = @'
#Requires -Version 5.1
param(
    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerInstance,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath,
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionDays = 7
)

$ErrorActionPreference = "Stop"

function Write-CleanupLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $logPath = "C:\ProgramData\SQLBackupWizard\logs\backups\$DatabaseName"
    if (-not (Test-Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    
    $logFile = Join-Path $logPath "cleanup-$(Get-Date -Format 'yyyyMMdd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

try {
    Import-Module SqlServer -ErrorAction Stop
    
    Write-CleanupLog "========================================" "INFO"
    Write-CleanupLog "SQL Server Backup Cleanup (Chain-Aware)" "INFO"
    Write-CleanupLog "========================================" "INFO"
    Write-CleanupLog "Database: $DatabaseName" "INFO"
    Write-CleanupLog "Retention: $RetentionDays days" "INFO"
    
    # Get backup path
    if (-not $BackupPath) {
        $query = @"
DECLARE @BackupPath NVARCHAR(500)
EXEC master.dbo.xp_instance_regread 
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @BackupPath OUTPUT
SELECT @BackupPath AS BackupPath
"@
        $result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
        $BackupPath = $result.BackupPath
    }
    
    Write-CleanupLog "Backup path: $BackupPath" "INFO"
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    Write-CleanupLog "Cutoff date: $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" "INFO"
    
    # Get backup history from SQL Server with chain information
    $historyQuery = @"
WITH BackupChain AS (
    SELECT 
        bs.database_name,
        bmf.physical_device_name,
        bs.backup_start_date,
        bs.backup_finish_date,
        bs.type,
        bs.backup_set_id,
        bs.media_set_id,
        CASE bs.type 
            WHEN 'D' THEN 'Full'
            WHEN 'I' THEN 'Differential'
            WHEN 'L' THEN 'Log'
        END AS backup_type,
        -- Find the full backup this differential depends on
        (SELECT MAX(bs2.backup_finish_date) 
         FROM msdb.dbo.backupset bs2 
         WHERE bs2.database_name = bs.database_name 
           AND bs2.type = 'D' 
           AND bs2.backup_finish_date <= bs.backup_start_date) AS base_full_backup_date
    FROM msdb.dbo.backupset bs
    INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    WHERE bs.database_name = '$DatabaseName'
      AND bmf.physical_device_name LIKE '$BackupPath%'
)
SELECT *
FROM BackupChain
ORDER BY backup_finish_date DESC
"@
    
    $backupHistory = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $historyQuery
    
    if ($backupHistory.Count -eq 0) {
        Write-CleanupLog "No backup history found for $DatabaseName" "WARNING"
        exit 0
    }
    
    # Find the most recent full backup that we want to keep
    $fullBackupsToKeep = $backupHistory | 
        Where-Object { $_.type -eq 'D' -and $_.backup_finish_date -ge $cutoffDate } |
        Sort-Object backup_finish_date -Descending
    
    if ($fullBackupsToKeep.Count -eq 0) {
        # Keep at least the most recent full backup even if it's older than retention
        $fullBackupsToKeep = $backupHistory | 
            Where-Object { $_.type -eq 'D' } |
            Sort-Object backup_finish_date -Descending |
            Select-Object -First 1
        
        Write-CleanupLog "No recent full backups within retention. Keeping most recent: $($fullBackupsToKeep[0].physical_device_name)" "INFO"
    }
    
    # Determine which files can be safely deleted
    $filesToDelete = @()
    
    foreach ($backup in $backupHistory) {
        $shouldDelete = $false
        
        if ($backup.backup_finish_date -lt $cutoffDate) {
            if ($backup.type -eq 'D') {
                # This is a full backup older than retention
                # Only delete if it's not in our "keep" list
                $isKept = $fullBackupsToKeep | Where-Object { $_.backup_set_id -eq $backup.backup_set_id }
                if (-not $isKept) {
                    $shouldDelete = $true
                }
            }
            elseif ($backup.type -eq 'I') {
                # This is a differential backup older than retention
                # Check if its base full backup is being kept
                $baseFullIsKept = $fullBackupsToKeep | Where-Object { $_.backup_finish_date -eq $backup.base_full_backup_date }
                if (-not $baseFullIsKept) {
                    $shouldDelete = $true
                }
            }
        }
        
        if ($shouldDelete) {
            $filesToDelete += $backup.physical_device_name
        }
    }
    
    # Delete files
    $deletedCount = 0
    foreach ($file in $filesToDelete) {
        if (Test-Path $file) {
            try {
                Remove-Item -Path $file -Force
                Write-CleanupLog "Deleted: $file" "INFO"
                $deletedCount++
            }
            catch {
                Write-CleanupLog "Failed to delete: $file - $_" "WARNING"
            }
        }
        else {
            Write-CleanupLog "File not found (already deleted?): $file" "WARNING"
        }
    }
    
    Write-CleanupLog "Cleanup complete. Deleted $deletedCount file(s)" "SUCCESS"
    Write-CleanupLog "Kept $($fullBackupsToKeep.Count) full backup(s) and their dependent differentials" "INFO"
    
    exit 0
}
catch {
    Write-CleanupLog "Cleanup failed: $_" "ERROR"
    Write-CleanupLog "Error details: $($_.Exception.Message)" "ERROR"
    exit 1
}
'@

    $scriptPath = Join-Path $script:Config.ScriptPath "Remove-OldBackups.ps1"
    Set-Content -Path $scriptPath -Value $scriptContent -Force
    return $scriptPath
}

# ============================================================================
# TASK SCHEDULER MANAGEMENT
# ============================================================================

function New-ScheduledBackupTask {
    param(
        [string]$DatabaseName,
        [string]$ServerInstance,
        [string]$BackupPath,
        [hashtable]$Schedule
    )
    
    $backupScript = Join-Path $script:Config.ScriptPath "Invoke-SQLBackup.ps1"
    
    # Create Full Backup Task
    $fullTaskName = "SQLBackup-$DatabaseName-Full"
    $fullAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$backupScript`" -DatabaseName `"$DatabaseName`" -ServerInstance `"$ServerInstance`" -BackupType `"Full`" -BackupPath `"$BackupPath`""
    
    $fullTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Schedule.FullBackupDay -At $Schedule.FullBackupTime
    
    $fullSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
    $fullPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $fullTaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $fullTaskName -Confirm:$false
    }
    
    Register-ScheduledTask -TaskName $fullTaskName -Action $fullAction -Trigger $fullTrigger -Settings $fullSettings -Principal $fullPrincipal -Description "Weekly full backup for $DatabaseName with compression" | Out-Null
    
    # Create Differential Backup Task (Every 4 hours)
    $diffTaskName = "SQLBackup-$DatabaseName-Diff"
    $diffAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$backupScript`" -DatabaseName `"$DatabaseName`" -ServerInstance `"$ServerInstance`" -BackupType `"Differential`" -BackupPath `"$BackupPath`""
    
    # Create 6 triggers for every 4 hours
    $diffTriggers = @(
        New-ScheduledTaskTrigger -Daily -At "00:00"
        New-ScheduledTaskTrigger -Daily -At "04:00"
        New-ScheduledTaskTrigger -Daily -At "08:00"
        New-ScheduledTaskTrigger -Daily -At "12:00"
        New-ScheduledTaskTrigger -Daily -At "16:00"
        New-ScheduledTaskTrigger -Daily -At "20:00"
    )
    
    $diffSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
    $diffPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    $existingDiffTask = Get-ScheduledTask -TaskName $diffTaskName -ErrorAction SilentlyContinue
    if ($existingDiffTask) {
        Unregister-ScheduledTask -TaskName $diffTaskName -Confirm:$false
    }
    
    $task = Register-ScheduledTask -TaskName $diffTaskName -Action $diffAction -Trigger $diffTriggers[0] -Settings $diffSettings -Principal $diffPrincipal -Description "Differential backup every 4 hours for $DatabaseName"
    
    # Add additional triggers
    $taskObj = Get-ScheduledTask -TaskName $diffTaskName
    for ($i = 1; $i -lt $diffTriggers.Count; $i++) {
        $taskObj.Triggers += $diffTriggers[$i]
    }
    $taskObj | Set-ScheduledTask | Out-Null
    
    # Create Cleanup Task
    $cleanupScript = Join-Path $script:Config.ScriptPath "Remove-OldBackups.ps1"
    $cleanupTaskName = "SQLBackup-$DatabaseName-Cleanup"
    $cleanupAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$cleanupScript`" -DatabaseName `"$DatabaseName`" -ServerInstance `"$ServerInstance`" -BackupPath `"$BackupPath`" -RetentionDays 7"
    
    $cleanupTrigger = New-ScheduledTaskTrigger -Daily -At "03:00"
    $cleanupSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
    $cleanupPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    $existingCleanupTask = Get-ScheduledTask -TaskName $cleanupTaskName -ErrorAction SilentlyContinue
    if ($existingCleanupTask) {
        Unregister-ScheduledTask -TaskName $cleanupTaskName -Confirm:$false
    }
    
    Register-ScheduledTask -TaskName $cleanupTaskName -Action $cleanupAction -Trigger $cleanupTrigger -Settings $cleanupSettings -Principal $cleanupPrincipal -Description "Daily cleanup of old backups for $DatabaseName (7-day retention)" | Out-Null
    
    return @{
        FullTask = $fullTaskName
        DiffTask = $diffTaskName
        CleanupTask = $cleanupTaskName
    }
}

function Remove-ScheduledBackupTask {
    param(
        [string]$DatabaseName
    )
    
    $tasks = @(
        "SQLBackup-$DatabaseName-Full"
        "SQLBackup-$DatabaseName-Diff"
        "SQLBackup-$DatabaseName-Cleanup"
    )
    
    foreach ($taskName in $tasks) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Success "Removed task: $taskName"
        }
    }
}

# ============================================================================
# MAIN WIZARD FUNCTIONS
# ============================================================================

function Show-WelcomeScreen {
    Clear-Host
    Write-Host ""
    Write-ColorOutput "╔═══════════════════════════════════════════════════════════╗" -Color Cyan
    Write-ColorOutput "║                                                           ║" -Color Cyan
    Write-ColorOutput "║        SQL SERVER BACKUP WIZARD v$($script:Config.Version)            ║" -Color Cyan
    Write-ColorOutput "║                                                           ║" -Color Cyan
    Write-ColorOutput "║  Automated Database Backup Configuration Tool             ║" -Color Cyan
    Write-ColorOutput "║                                                           ║" -Color Cyan
    Write-ColorOutput "╚═══════════════════════════════════════════════════════════╝" -Color Cyan
    Write-Host ""
}

function Install-BackupJob {
    Show-WelcomeScreen
    
    Write-Info "Checking prerequisites..."
    
    # Check SQL Server module
    if (-not (Test-SQLServerModule)) {
        Write-Error "Failed to load SQL Server module. Cannot continue."
        return
    }
    
    Write-Success "Prerequisites check passed"
    Write-Host ""
    
    # Initialize environment
    Initialize-WizardEnvironment
    
    # Get SQL Server instance
    Write-Header "SQL SERVER INSTANCE SELECTION"
    
    $instances = Get-SQLServerInstances

    if (-not $instances -or $instances.Count -eq 0) {
        Write-Error "No SQL Server instances detected. Please ensure SQL Server is installed."
        return
    }

    if ($instances.Count -eq 1) {
        $selectedInstance = $instances[0]
        Write-Info "Detected instance: '$selectedInstance'"
    }
    else {
        Write-Info "Detected instances:"
        for ($i = 0; $i -lt $instances.Count; $i++) {
            Write-Host "  [$($i + 1)] $($instances[$i])"
        }
        Write-Host ""

        do {
            $selection = Read-Host "Select instance number (1-$($instances.Count))"
            $selectionInt = [int]$selection
        } while ($selectionInt -lt 1 -or $selectionInt -gt $instances.Count)

        $selectedInstance = $instances[$selectionInt - 1]
    }

    # Validate instance name
    if ([string]::IsNullOrWhiteSpace($selectedInstance)) {
        Write-Error "Instance name is empty or invalid"
        return
    }

    Write-Success "Selected instance: '$selectedInstance'"
    Write-Host ""
    
    # Test connection
    Write-Info "Testing connection to '$selectedInstance'..."
    try {
        $testQuery = "SELECT @@VERSION AS Version"
        $version = Invoke-Sqlcmd -ServerInstance $selectedInstance -Query $testQuery -ErrorAction Stop
        Write-Success "Connection successful"
        Write-Info "SQL Server version: $($version.Version.Split("`n")[0])"
        Write-Host ""
    }
    catch {
        Write-Error "Failed to connect to '$selectedInstance'"
        Write-Warning "Error details: $($_.Exception.Message)"
        Write-Host ""
        Write-Info "Troubleshooting tips:"
        Write-Host "  - Ensure SQL Server service is running"
        Write-Host "  - Check Windows Firewall settings"
        Write-Host "  - Verify SQL Server Browser service is running (for named instances)"
        Write-Host "  - Try using: localhost or .\INSTANCENAME or computername\INSTANCENAME"
        Write-Host ""
        return
    }
    
    # Get database list
    Write-Header "DATABASE SELECTION"
    
    $databases = Get-SQLServerDatabases -ServerInstance $selectedInstance
    
    if ($databases.Count -eq 0) {
        Write-Error "No user databases found on $selectedInstance"
        return
    }
    
    Write-Info "Available databases:"
    for ($i = 0; $i -lt $databases.Count; $i++) {
        # Check if job already exists
        $existing = Find-ExistingJob -DatabaseName $databases[$i] -ServerInstance $selectedInstance
        $status = if ($existing) { " [Already configured]" } else { "" }
        Write-Host "  [$($i + 1)] $($databases[$i])$status"
    }
    Write-Host ""
    
    do {
        $selection = Read-Host "Select database number (1-$($databases.Count))"
        $selectionInt = [int]$selection
    } while ($selectionInt -lt 1 -or $selectionInt -gt $databases.Count)
    
    $selectedDatabase = $databases[$selectionInt - 1]
    Write-Success "Selected database: $selectedDatabase"
    Write-Host ""
    
    # Check if job already exists
    $existingJob = Find-ExistingJob -DatabaseName $selectedDatabase -ServerInstance $selectedInstance
    if ($existingJob) {
        Write-Warning "A backup job already exists for this database."
        $response = Read-Host "Do you want to reconfigure it? (Y/N)"
        if ($response -ne 'Y' -and $response -ne 'y') {
            Write-Info "Operation cancelled."
            return
        }
    }
    
    # Get backup path
    Write-Header "BACKUP CONFIGURATION"
    
    $defaultBackupPath = Get-SQLDefaultBackupPath -ServerInstance $selectedInstance
    
    if ($defaultBackupPath) {
        Write-Info "SQL Server default backup path: $defaultBackupPath"
        Write-Info "Using default path (recommended)"
        $backupPath = $defaultBackupPath
    }
    else {
        Write-Warning "Could not determine default backup path"
        $backupPath = Read-Host "Enter backup path"
    }
    
    Write-Success "Backup path: $backupPath"
    Write-Host ""
    
    # Schedule configuration
    Write-Info "Schedule Configuration:"
    Write-Info "  • Full Backup: Weekly (default: Sunday at 1:00 AM)"
    Write-Info "  • Differential Backup: Every 4 hours"
    Write-Info "  • Retention: 7 days (chain-aware)"
    Write-Host ""
    
    $useDefaultSchedule = Read-Host "Use default schedule? (Y/N)"
    
    if ($useDefaultSchedule -eq 'Y' -or $useDefaultSchedule -eq 'y') {
        $schedule = @{
            FullBackupDay = "Sunday"
            FullBackupTime = "01:00"
        }
    }
    else {
        Write-Info "Full backup day options: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday"
        $schedule = @{
            FullBackupDay = Read-Host "Full backup day [Sunday]"
            FullBackupTime = Read-Host "Full backup time (HH:MM) [01:00]"
        }
        
        if ([string]::IsNullOrWhiteSpace($schedule.FullBackupDay)) {
            $schedule.FullBackupDay = "Sunday"
        }
        if ([string]::IsNullOrWhiteSpace($schedule.FullBackupTime)) {
            $schedule.FullBackupTime = "01:00"
        }
    }
    
    # Confirmation
    Write-Header "CONFIGURATION SUMMARY"
    Write-Host "Instance:           $selectedInstance"
    Write-Host "Database:           $selectedDatabase"
    Write-Host "Backup Path:        $backupPath"
    Write-Host "Full Backup:        $($schedule.FullBackupDay) at $($schedule.FullBackupTime)"
    Write-Host "Differential:       Every 4 hours"
    Write-Host "Retention:          7 days (chain-aware)"
    Write-Host "Compression:        Enabled"
    Write-Host "Verification:       Enabled"
    Write-Host ""
    
    $confirm = Read-Host "Create backup job? (Y/N)"
    
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Info "Operation cancelled."
        return
    }
    
    # Create backup scripts
    Write-Header "CREATING BACKUP JOB"
    
    Write-Info "Generating backup scripts..."
    $backupScript = New-BackupScript
    $cleanupScript = New-CleanupScript
    Write-Success "Scripts generated"
    
    # Create scheduled tasks
    Write-Info "Creating scheduled tasks..."
    $tasks = New-ScheduledBackupTask -DatabaseName $selectedDatabase -ServerInstance $selectedInstance -BackupPath $backupPath -Schedule $schedule
    Write-Success "Scheduled tasks created:"
    Write-Success "  • $($tasks.FullTask)"
    Write-Success "  • $($tasks.DiffTask)"
    Write-Success "  • $($tasks.CleanupTask)"
    
    # Save configuration
    Write-Info "Saving configuration..."
    $config = Get-JobConfiguration
    
    # Remove existing job if present
    if ($existingJob) {
        $config.jobs = $config.jobs | Where-Object { $_.jobId -ne $existingJob.jobId }
    }
    
    $newJob = @{
        jobId = [guid]::NewGuid().ToString()
        databaseName = $selectedDatabase
        serverInstance = $selectedInstance
        backupPath = $backupPath
        schedules = @{
            fullBackup = @{
                frequency = "Weekly"
                dayOfWeek = $schedule.FullBackupDay
                time = $schedule.FullBackupTime
                taskName = $tasks.FullTask
            }
            differentialBackup = @{
                frequency = "Every4Hours"
                taskName = $tasks.DiffTask
            }
            cleanup = @{
                frequency = "Daily"
                time = "03:00"
                taskName = $tasks.CleanupTask
            }
        }
        retention = @{
            days = 7
            strategy = "ChainAware"
        }
        compression = $true
        verification = $true
        created = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        lastModified = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        enabled = $true
    }
    
    $config.jobs += $newJob
    
    if (Save-JobConfiguration -Config $config) {
        Write-Success "Configuration saved"
    }
    
    Write-Host ""
    Write-Header "BACKUP JOB CREATED SUCCESSFULLY!"
    
    Write-Info "Next Steps:"
    Write-Info "  1. Run initial full backup now (recommended)"
    Write-Info "  2. Monitor scheduled task execution"
    Write-Info "  3. Check logs in: C:\ProgramData\SQLBackupWizard\logs"
    Write-Host ""
    
    $runNow = Read-Host "Run initial full backup now? (Y/N)"
    
    if ($runNow -eq 'Y' -or $runNow -eq 'y') {
        Write-Info "Starting initial backup..."
        Start-ScheduledTask -TaskName $tasks.FullTask
        Write-Success "Backup task started. Check logs for progress."
    }
    
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════" -Color Green
    Write-ColorOutput "  Backup job configured successfully!" -Color Green
    Write-ColorOutput "═══════════════════════════════════════════════════════════" -Color Green
    Write-Host ""
}

function Show-JobStatus {
    Show-WelcomeScreen
    
    $config = Get-JobConfiguration
    
    if ($config.jobs.Count -eq 0) {
        Write-Warning "No backup jobs configured yet."
        Write-Info "Run: iwr -useb <your-github-url> | iex"
        return
    }
    
    Write-Header "CONFIGURED BACKUP JOBS"
    
    foreach ($job in $config.jobs) {
        Write-Host ""
        Write-ColorOutput "Database: $($job.databaseName)" -Color Cyan
        Write-Host "Instance:     $($job.serverInstance)"
        Write-Host "Backup Path:  $($job.backupPath)"
        Write-Host "Status:       $(if ($job.enabled) { 'Enabled' } else { 'Disabled' })"
        Write-Host "Created:      $($job.created)"
        Write-Host ""
        Write-Host "Schedule:"
        Write-Host "  Full Backup:        $($job.schedules.fullBackup.dayOfWeek) at $($job.schedules.fullBackup.time)"
        Write-Host "  Differential:       Every 4 hours"
        Write-Host "  Cleanup:            Daily at $($job.schedules.cleanup.time)"
        Write-Host ""
        Write-Host "Tasks:"
        
        # Check task status
        $fullTask = Get-ScheduledTask -TaskName $job.schedules.fullBackup.taskName -ErrorAction SilentlyContinue
        $diffTask = Get-ScheduledTask -TaskName $job.schedules.differentialBackup.taskName -ErrorAction SilentlyContinue
        $cleanupTask = Get-ScheduledTask -TaskName $job.schedules.cleanup.taskName -ErrorAction SilentlyContinue
        
        if ($fullTask) {
            $fullInfo = Get-ScheduledTaskInfo -TaskName $job.schedules.fullBackup.taskName
            Write-Host "  Full:         $(if ($fullTask.State -eq 'Ready') { '✓' } else { '✗' }) $($fullTask.State) - Next: $($fullInfo.NextRunTime)"
        }
        
        if ($diffTask) {
            $diffInfo = Get-ScheduledTaskInfo -TaskName $job.schedules.differentialBackup.taskName
            Write-Host "  Differential: $(if ($diffTask.State -eq 'Ready') { '✓' } else { '✗' }) $($diffTask.State) - Next: $($diffInfo.NextRunTime)"
        }
        
        if ($cleanupTask) {
            $cleanupInfo = Get-ScheduledTaskInfo -TaskName $job.schedules.cleanup.taskName
            Write-Host "  Cleanup:      $(if ($cleanupTask.State -eq 'Ready') { '✓' } else { '✗' }) $($cleanupTask.State) - Next: $($cleanupInfo.NextRunTime)"
        }
        
        Write-ColorOutput "───────────────────────────────────────────────────────────" -Color Gray
    }
    
    Write-Host ""
}

function Manage-BackupJobs {
    Show-WelcomeScreen
    
    $config = Get-JobConfiguration
    
    if ($config.jobs.Count -eq 0) {
        Write-Warning "No backup jobs configured yet."
        return
    }
    
    Write-Header "MANAGE BACKUP JOBS"
    
    Write-Info "Configured jobs:"
    for ($i = 0; $i -lt $config.jobs.Count; $i++) {
        $job = $config.jobs[$i]
        $status = if ($job.enabled) { "Enabled" } else { "Disabled" }
        Write-Host "  [$($i + 1)] $($job.databaseName) on $($job.serverInstance) [$status]"
    }
    Write-Host ""
    
    do {
        $selection = Read-Host "Select job number (1-$($config.jobs.Count)) or 0 to cancel"
        $selectionInt = [int]$selection
    } while ($selectionInt -lt 0 -or $selectionInt -gt $config.jobs.Count)
    
    if ($selectionInt -eq 0) {
        return
    }
    
    $selectedJob = $config.jobs[$selectionInt - 1]
    
    Write-Host ""
    Write-ColorOutput "Selected: $($selectedJob.databaseName)" -Color Cyan
    Write-Host ""
    Write-Host "Actions:"
    Write-Host "  [1] View Details"
    Write-Host "  [2] Enable Job"
    Write-Host "  [3] Disable Job"
    Write-Host "  [4] Run Full Backup Now"
    Write-Host "  [5] Remove Job"
    Write-Host "  [0] Cancel"
    Write-Host ""
    
    $action = Read-Host "Select action"
    
    switch ($action) {
        "1" {
            Write-Host ""
            $selectedJob | ConvertTo-Json -Depth 10 | Write-Host
        }
        "2" {
            $selectedJob.enabled = $true
            $selectedJob.lastModified = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            Save-JobConfiguration -Config $config
            Write-Success "Job enabled"
        }
        "3" {
            $selectedJob.enabled = $false
            $selectedJob.lastModified = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            Save-JobConfiguration -Config $config
            Write-Success "Job disabled"
        }
        "4" {
            Write-Info "Starting full backup..."
            Start-ScheduledTask -TaskName $selectedJob.schedules.fullBackup.taskName
            Write-Success "Backup task started"
        }
        "5" {
            Write-Warning "This will remove the backup job and all scheduled tasks."
            $confirm = Read-Host "Are you sure? (Y/N)"
            if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                Remove-ScheduledBackupTask -DatabaseName $selectedJob.databaseName
                $config.jobs = $config.jobs | Where-Object { $_.jobId -ne $selectedJob.jobId }
                Save-JobConfiguration -Config $config
                Write-Success "Job removed successfully"
            }
        }
    }
}

function Remove-AllJobs {
    Show-WelcomeScreen
    
    Write-Header "REMOVE ALL BACKUP JOBS"
    
    Write-Warning "This will remove ALL backup jobs and scheduled tasks."
    Write-Warning "Backup files will NOT be deleted."
    Write-Host ""
    
    $confirm = Read-Host "Are you sure you want to continue? (Y/N)"
    
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Info "Operation cancelled."
        return
    }
    
    $config = Get-JobConfiguration
    
    foreach ($job in $config.jobs) {
        Write-Info "Removing job for: $($job.databaseName)..."
        Remove-ScheduledBackupTask -DatabaseName $job.databaseName
    }
    
    # Reset configuration
    $config.jobs = @()
    Save-JobConfiguration -Config $config
    
    Write-Success "All jobs removed successfully"
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

function Main {
    # Check if running as admin
    if (-not (Test-Administrator)) {
        Write-Error "This script requires Administrator privileges."
        Write-Info "Right-click PowerShell and select 'Run as Administrator'"
        exit 1
    }
    
    switch ($Action) {
        "Install" {
            Install-BackupJob
        }
        "Manage" {
            Manage-BackupJobs
        }
        "Remove" {
            Remove-AllJobs
        }
        "Status" {
            Show-JobStatus
        }
        default {
            Install-BackupJob
        }
    }
}

# Run the wizard
Main
