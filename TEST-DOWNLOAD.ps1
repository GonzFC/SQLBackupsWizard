# SQL Backup Wizard - Download Test Script
# Run this on your Windows production computer to verify download

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "SQL Backup Wizard - Download Test" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check Internet Connectivity
Write-Host "[Test 1] Checking GitHub connectivity..." -ForegroundColor Yellow
try {
    $connection = Test-NetConnection -ComputerName raw.githubusercontent.com -Port 443 -InformationLevel Quiet
    if ($connection) {
        Write-Host "  ✓ Can reach raw.githubusercontent.com" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Cannot reach raw.githubusercontent.com" -ForegroundColor Red
        Write-Host "  Check firewall/proxy settings" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ⚠ Network test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Test 2: Try to download the script
Write-Host "[Test 2] Attempting to download script..." -ForegroundColor Yellow
$url = "https://raw.githubusercontent.com/GonzFC/SQLBackupsWizard/main/Install-SQLBackupWizard.ps1"
$outputPath = "$env:TEMP\Install-SQLBackupWizard-test.ps1"

try {
    Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
    Write-Host "  ✓ Download successful!" -ForegroundColor Green

    # Verify file
    $file = Get-Item $outputPath
    Write-Host "  ✓ File size: $([math]::Round($file.Length/1KB, 2)) KB" -ForegroundColor Green
    Write-Host "  ✓ Location: $outputPath" -ForegroundColor Green

} catch {
    Write-Host "  ✗ Download failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host ""
        Write-Host "  Possible reasons for 404:" -ForegroundColor Yellow
        Write-Host "  - Repository might be private (it should be public)" -ForegroundColor Yellow
        Write-Host "  - URL typo (check case sensitivity)" -ForegroundColor Yellow
        Write-Host "  - DNS cache issue (try: ipconfig /flushdns)" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host ""

# Test 3: Verify file content
Write-Host "[Test 3] Verifying PowerShell syntax..." -ForegroundColor Yellow
try {
    $content = Get-Content $outputPath -Raw

    # Check for PowerShell header
    if ($content -match '#Requires -Version') {
        Write-Host "  ✓ Valid PowerShell script detected" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Invalid file content" -ForegroundColor Red
        exit 1
    }

    # Check for key functions
    if ($content -match 'SQL Server Backup Wizard') {
        Write-Host "  ✓ Correct script downloaded" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Wrong file downloaded" -ForegroundColor Red
        exit 1
    }

    # Show first few lines
    Write-Host ""
    Write-Host "  First 5 lines of downloaded script:" -ForegroundColor Cyan
    (Get-Content $outputPath | Select-Object -First 5) | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }

} catch {
    Write-Host "  ✗ File verification failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "All Tests Passed! ✓" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The script is ready to use. You can run it with:" -ForegroundColor White
Write-Host ""
Write-Host "  $outputPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or use the one-liner:" -ForegroundColor White
Write-Host ""
Write-Host "  iwr -useb $url | iex" -ForegroundColor Yellow
Write-Host ""

# Cleanup option
Write-Host "Press any key to delete test file or Ctrl+C to keep it..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Remove-Item $outputPath -Force
Write-Host "Test file removed." -ForegroundColor Green
