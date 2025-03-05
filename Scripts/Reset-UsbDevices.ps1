# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

# Define Devcon.exe path
$devconPath = "$env:SystemRoot\System32\devcon.exe"

# URL to Devcon.exe (Direct Download Link)
$devconUrl = "http://www.youcef.xyz/files/devcon.exe"

# Function to download Devcon.exe
function Download-Devcon {
    Write-Host "Downloading Devcon.exe..." -ForegroundColor Yellow
    $tempDevcon = "$env:TEMP\devcon.exe"

    try {
        Invoke-WebRequest -Uri $devconUrl -OutFile $tempDevcon
        Move-Item -Path $tempDevcon -Destination $devconPath -Force
        Write-Host "Devcon.exe installed successfully in C:\Windows\System32." -ForegroundColor Green
    } catch {
        Write-Host "Failed to download Devcon.exe. Please check the internet connection or install it manually from: $devconUrl" -ForegroundColor Red
        exit
    }
}

# Check if Devcon.exe exists, download if missing
if (-not (Test-Path $devconPath)) {
    Download-Devcon
}

# Scan for USB devices
Write-Host "Scanning USB devices..." -ForegroundColor Yellow
$devices = Get-PnpDevice -Class USB -Status OK

$totalDevices = ($devices | Measure-Object).Count
if ($totalDevices -eq 0) {
    Write-Host "No active USB devices found." -ForegroundColor Yellow
    exit
}

Write-Host "`nFound $totalDevices USB device(s)" -ForegroundColor Cyan
Write-Host "Starting reset process..." -ForegroundColor Yellow

$successCount = 0
foreach ($device in $devices) {
    # Skip non-resettable devices (Root Hub, Host Controller)
    if ($device.FriendlyName -match "Host Controller|Root Hub") {
        Write-Host "Skipping: $($device.FriendlyName) (not resettable)" -ForegroundColor Magenta
        continue
    }

    Write-Host "`nProcessing: $($device.FriendlyName)" -ForegroundColor Cyan

    try {
        Write-Host "  Disabling device..." -ForegroundColor Gray
        Start-Process -FilePath $devconPath -ArgumentList "disable `"$($device.InstanceId)`"" -NoNewWindow -Wait
        Start-Sleep -Seconds 2

        Write-Host "  Enabling device..." -ForegroundColor Gray
        Start-Process -FilePath $devconPath -ArgumentList "enable `"$($device.InstanceId)`"" -NoNewWindow -Wait
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

# Keep window open
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            catch {
                Write-Host "  Failed to reset device: $_" -ForegroundColor Red
                continue
            }
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
