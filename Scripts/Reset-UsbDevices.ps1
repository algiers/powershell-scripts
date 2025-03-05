# Function to handle USB device operations using WMI
function Reset-UsbDevice {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceID,
        [string]$FriendlyName
    )
    
    try {
        Write-Host "Processing device: $FriendlyName" -ForegroundColor Cyan
        
        # Get WMI device instance
        $device = Get-WmiObject Win32_USBHub | Where-Object { $_.DeviceID -eq $DeviceID }
        
        if ($device) {
            Write-Host "  Disabling..." -ForegroundColor Gray
            $device.Disable() | Out-Null
            Start-Sleep -Seconds 2
            
            Write-Host "  Enabling..." -ForegroundColor Gray
            $device.Enable() | Out-Null
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
    
    # Get all USB devices using WMI
    $usbDevices = Get-WmiObject Win32_USBHub
    
    $successCount = 0
    $totalDevices = ($usbDevices | Measure-Object).Count
    
    if ($totalDevices -eq 0) {
        Write-Host "`nNo USB devices found." -ForegroundColor Yellow
    } else {
        foreach ($device in $usbDevices) {
            if (Reset-UsbDevice -DeviceID $device.DeviceID -FriendlyName $device.Description) {
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
