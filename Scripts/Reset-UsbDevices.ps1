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
    $devices = Get-PnpDevice -Class USB | Where-Object { $_.Status -eq "OK" }
    
    foreach ($device in $devices) {
        Write-Host "Processing device: $($device.FriendlyName)" -ForegroundColor Cyan
        try {
            Write-Host "  Disabling..." -ForegroundColor Gray
            Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            Write-Host "  Enabling..." -ForegroundColor Gray
            Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            Write-Host "  Successfully reset" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to reset device: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nUSB device reset complete!" -ForegroundColor Green
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

# Keep window open
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
