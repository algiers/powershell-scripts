# Function to handle USB device operations using PnP utilities
function Reset-UsbDevice {
    param (
        [string]$instanceId,
        [string]$friendlyName
    )
    
    try {
        Write-Host "Processing device: $friendlyName" -ForegroundColor Cyan
        
        # Use rundll32 to disable and enable the device
        Write-Host "  Disabling..." -ForegroundColor Gray
        $null = & rundll32.exe devmgr.dll,DeviceManager_ExecuteAction 2 $instanceId
        Start-Sleep -Seconds 2
        
        Write-Host "  Enabling..." -ForegroundColor Gray
        $null = & rundll32.exe devmgr.dll,DeviceManager_ExecuteAction 1 $instanceId
        Start-Sleep -Seconds 2
        
        Write-Host "  Successfully reset" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  Failed to reset device: $_" -ForegroundColor Red
        return $false
    }
}

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
    
    # Get all USB devices using native PowerShell commands
    $devices = Get-PnpDevice -Class USB | Where-Object { $_.Status -eq "OK" }
    
    $successCount = 0
    $totalDevices = ($devices | Measure-Object).Count
    
    foreach ($device in $devices) {
        if (Reset-UsbDevice -instanceId $device.InstanceId -friendlyName $device.FriendlyName) {
            $successCount++
        }
    }
    
    Write-Host "`nReset complete! Successfully reset $successCount out of $totalDevices devices." -ForegroundColor Green
} catch {
    Write-Host "`nAn error occurred while processing devices: $_" -ForegroundColor Red
}

# Keep window open
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
