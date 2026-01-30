#Optional RAM cleanup
Write-Host ""
Write-Host "Do you want to CLEAN unused RAM (standby cache)?" -ForegroundColor Yellow
Write-Host "This is SAFE and temporary. Windows will refill RAM when needed." -ForegroundColor DarkYellow
$cleanRam = Read-Host "Type Y for YES, N for NO (default: N)"

if ([string]::IsNullOrWhiteSpace($cleanRam)) {
    $cleanRam = "N"
}

if ($cleanRam -eq "Y" -or $cleanRam -eq "y") {
    Write-Host "Cleaning standby memory..." -ForegroundColor Cyan

    # Call Windows API to trim working sets
    Get-Process | Where-Object { $_.WorkingSet -gt 0 } | ForEach-Object {
        try {
            $sig = @"
using System;
using System.Runtime.InteropServices;
public class RamCleaner {
    [DllImport("kernel32.dll")]
    public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
}
"@
            Add-Type $sig -ErrorAction SilentlyContinue
            [RamCleaner]::SetProcessWorkingSetSize($_.Handle, -1, -1) | Out-Null
        } catch {}
    }

    Write-Host "RAM cleanup completed." -ForegroundColor Green
} else {
    Write-Host "RAM cleanup skipped." -ForegroundColor Green
}
