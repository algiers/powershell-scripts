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
    
    # Get the network adapter device IDs for USB controllers
    $usbAdapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*USB*" }
    
    $successCount = 0
    $totalDevices = ($usbAdapters | Measure-Object).Count
    
    if ($totalDevices -eq 0) {
        Write-Host "`nNo USB network adapters found." -ForegroundColor Yellow
    } else {
        foreach ($adapter in $usbAdapters) {
            Write-Host "Processing device: $($adapter.InterfaceDescription)" -ForegroundColor Cyan
            try {
                Write-Host "  Disabling..." -ForegroundColor Gray
                $null = netsh interface set interface "$($adapter.Name)" disable
                Start-Sleep -Seconds 2
                
                Write-Host "  Enabling..." -ForegroundColor Gray
                $null = netsh interface set interface "$($adapter.Name)" enable
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

    # Additionally reset USB root hubs
    Write-Host "`nResetting USB Root Hubs..." -ForegroundColor Yellow
    Get-PnpDevice -Class USB -Status OK | Where-Object { $_.FriendlyName -like "*Root Hub*" } | ForEach-Object {
        Write-Host "Processing root hub: $($_.FriendlyName)" -ForegroundColor Cyan
        try {
            Stop-Service -Name "USBSTOR" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name "USBSTOR" -ErrorAction SilentlyContinue
            Write-Host "  Successfully cycled USB storage service" -ForegroundColor Green
        }
        catch {
            Write-Host "  Failed to cycle USB storage service: $_" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "`nAn error occurred while processing devices: $_" -ForegroundColor Red
}

# Keep window open
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
