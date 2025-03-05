# Function to download devcon.exe if not present
function Get-Devcon {
    $devconPath = "$env:TEMP\devcon.exe"
    if (-not (Test-Path $devconPath)) {
        Write-Host "Downloading devcon.exe..." -ForegroundColor Yellow
        $url = "https://download.microsoft.com/download/7/D/D/7DD48DE6-8BDA-47C0-854A-539A800FAA90/wdk/Installers/787bee96dbd26371076b37b13c405890.cab"
        $cabPath = "$env:TEMP\devcon.cab"
        
        try {
            Invoke-WebRequest -Uri $url -OutFile $cabPath
            expand.exe $cabPath -F:devcon.exe $env:TEMP
            Remove-Item $cabPath -Force
        } catch {
            Write-Host "Failed to download devcon.exe: $_" -ForegroundColor Red
            exit
        }
    }
    return $devconPath
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
    # Get devcon.exe
    $devcon = Get-Devcon
    
    Write-Host "Resetting USB devices..." -ForegroundColor Yellow
    
    # Get list of USB devices
    $usbDevices = & $devcon find "USB\*" | Where-Object { $_ -match '^USB' }
    
    foreach ($device in $usbDevices) {
        $deviceId = ($device -split ': ')[0]
        $deviceName = ($device -split ': ')[1]
        
        Write-Host "Processing device: $deviceName" -ForegroundColor Cyan
        try {
            Write-Host "  Disabling..." -ForegroundColor Gray
            & $devcon disable "@$deviceId" | Out-Null
            Start-Sleep -Seconds 2
            
            Write-Host "  Enabling..." -ForegroundColor Gray
            & $devcon enable "@$deviceId" | Out-Null
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
