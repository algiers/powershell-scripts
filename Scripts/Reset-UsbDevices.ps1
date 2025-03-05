# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

try {
    Write-Host "Resetting USB devices..." -ForegroundColor Yellow
    
    # Get all USB devices that are currently enabled
    $usbDevices = Get-PnpDevice -Class USB -Status OK
    
    $successCount = 0
    $totalDevices = ($usbDevices | Measure-Object).Count
    
    if ($totalDevices -eq 0) {
        Write-Host "`nNo USB devices found." -ForegroundColor Yellow
    } else {
        foreach ($device in $usbDevices) {
            Write-Host "Processing device: $($device.FriendlyName)" -ForegroundColor Cyan
            try {
                Write-Host "  Disabling..." -ForegroundColor Gray
                $disableResult = & pnputil.exe /disable-device "$($device.InstanceId)" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to disable device: $disableResult"
                }
                Start-Sleep -Seconds 2
                
                Write-Host "  Enabling..." -ForegroundColor Gray
                $enableResult = & pnputil.exe /enable-device "$($device.InstanceId)" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to enable device: $enableResult"
                }
                Start-Sleep -Seconds 2
                
                Write-Host "  Successfully reset" -ForegroundColor Green
                $successCount++
            }
            catch {
                Write-Host "  Failed to reset device: $_" -ForegroundColor Red
            }
        }
        
        Write-Host "`nReset complete! Successfully reset $successCount out of $totalDevices devices." -ForegroundColor Green
    }
} catch {
    Write-Host "`nAn error occurred while processing devices: $_" -ForegroundColor Red
}

# Keep window open
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
