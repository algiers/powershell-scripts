# Function to handle USB device operations using WMI
function Reset-UsbDevice {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceID,
        [string]$FriendlyName
    )
    
    try {
        Write-Host "Processing device: $FriendlyName" -ForegroundColor Cyan
        
        # Get the device from PnPEntity
        $query = "SELECT * FROM Win32_PnPEntity WHERE DeviceID='$DeviceID'"
        $device = Get-WmiObject -Query $query
        
        if ($device) {
            Write-Host "  Disabling..." -ForegroundColor Gray
            # Use built-in disable method
            $result = $device.SetPowerState(0, 1)
            Start-Sleep -Seconds 2
            
            Write-Host "  Enabling..." -ForegroundColor Gray
            # Use built-in enable method
            $result = $device.SetPowerState(1, 1)
            Start-Sleep -Seconds 2
            
            Write-Host "  Successfully reset" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Device not found" -ForegroundColor Red
            return $false
        }
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
    
    # Get all USB devices using PnPEntity
    $usbDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPClass -eq "USB" }
    
    $successCount = 0
    $totalDevices = ($usbDevices | Measure-Object).Count
    
    if ($totalDevices -eq 0) {
        Write-Host "`nNo USB devices found." -ForegroundColor Yellow
    } else {
        foreach ($device in $usbDevices) {
            if (Reset-UsbDevice -DeviceID $device.DeviceID -FriendlyName $device.Name) {
                $successCount++
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
