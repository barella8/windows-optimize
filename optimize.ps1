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
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -ne "Stopped") {
            Stop-Service $service -Force
        }
        Set-Service $service -StartupType Disabled
    }
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

#Disable Windows Copilot
Write-Host "Disabling Windows Copilot..."

$copilotRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
if (-not (Test-Path $copilotRegPath)) {
    New-Item -Path $copilotRegPath -Force | Out-Null
}

Set-ItemProperty `
    -Path $copilotRegPath `
    -Name "TurnOffWindowsCopilot" `
    -Value 1 `
    -Type DWord

#Disable Edge Copilot sidebar
$edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgeRegPath)) {
    New-Item -Path $edgeRegPath -Force | Out-Null
}

Set-ItemProperty `
    -Path $edgeRegPath `
    -Name "HubsSidebarEnabled" `
    -Value 0 `
    -Type DWord

#Xbox removal
Write-Host ""
Write-Host "Do you want to REMOVE Xbox related apps?" -ForegroundColor Yellow
Write-Host "This may affect Minecraft Bedrock, Xbox App and Game Pass." -ForegroundColor DarkYellow
$removeXbox = Read-Host "Type Y for YES, N for NO (default: N)"

if ([string]::IsNullOrWhiteSpace($removeXbox)) {
    $removeXbox = "N"
}

#Common bloat apps
$bloat = @("Bing","Solitaire","Zune","Skype","YourPhone")

Write-Host "Removing common bloatware..."
foreach ($app in $bloat) {
    Get-AppxPackage *$app* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
}
#Optional Xbox removal
if ($removeXbox -eq "Y" -or $removeXbox -eq "y") {
    Write-Host "Removing Xbox components..." -ForegroundColor Red
    Get-AppxPackage *Xbox* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
} else {
    Write-Host "Xbox components preserved." -ForegroundColor Green
}

#Clear recycle bin
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

Write-Host "Optimization complete. Restart recommended." -ForegroundColor Green
