# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

try {
    Write-Host "Scanning USB devices..." -ForegroundColor Yellow
    $devices = Get-PnpDevice -Class USB -Status OK
    $totalDevices = ($devices | Measure-Object).Count
    
    if ($totalDevices -eq 0) {
        Write-Host "`nNo active USB devices found." -ForegroundColor Yellow
        exit
    }
    
    Write-Host "`nFound $totalDevices USB device(s)" -ForegroundColor Cyan
    Write-Host "Starting reset process..." -ForegroundColor Yellow
    
    $successCount = 0
    foreach ($device in $devices) {
        Write-Host "`nProcessing: $($device.FriendlyName)" -ForegroundColor Cyan
        try {
            Write-Host "  Disabling..." -ForegroundColor Gray
            Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            Write-Host "  Enabling..." -ForegroundColor Gray
            Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            Write-Host "  Successfully reset" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "  Failed to reset device: $_" -ForegroundColor Red
            continue
        }
    }
    
    Write-Host "`nReset process complete!" -ForegroundColor Green
    Write-Host "Successfully reset $successCount out of $totalDevices devices" -ForegroundColor $(if ($successCount -eq $totalDevices) { "Green" } else { "Yellow" })
} catch {
    Write-Host "`nAn error occurred while processing devices: $_" -ForegroundColor Red
}

# Keep window open
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
