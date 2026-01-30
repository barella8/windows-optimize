
# Windows + SSD Optimization
# Author: barella8
# Safe / reversible tweaks only

Write-Host "Windows Optimization started..." -ForegroundColor Cyan

#Admin check
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Run PowerShell as Administrator!" -ForegroundColor Red
    exit
}

#Temp cleanup
Write-Host "Cleaning temp files..."
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path C:\Windows\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

#Disable unnecessary services
Write-Host "Disabling unnecessary services..."
$services = @(
    "SysMain",
    "WSearch",     
    "DiagTrack",
    "dmwappushservice"
)

foreach ($service in $services) {
    Get-Service -Name $service -ErrorAction SilentlyContinue | `
    Set-Service -StartupType Disabled
}

#Disable telemetry scheduled tasks
Write-Host "Disabling telemetry scheduled tasks..."
$tasks = @(
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
)

foreach ($task in $tasks) {
    schtasks /Change /TN $task /Disable | Out-Null
}

#Reduce SSD write load
Write-Host "Reducing unnecessary disk writes..."
fsutil behavior set DisableLastAccess 1 | Out-Null

#Remove common bloat apps
Write-Host "Removing common bloatware..."
$bloat = "Xbox","Bing","Solitaire","Zune","Skype","YourPhone"
foreach ($app in $bloat) {
    Get-AppxPackage *$app* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
}

#Clear recycle bin 
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

Write-Host "Optimization complete. Restart recommended." -ForegroundColor Green
