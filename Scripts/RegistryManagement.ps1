# Registry Merge Menu - Fetch and Apply .reg Files from GitHub

# Define GitHub API URLs
$apiUrl = "https://api.github.com/repos/algiers/powershell-scripts/contents/Scripts/Registry"

# Function to check if running as Administrator
function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "⚠️ This script requires Administrator privileges. Restarting as Admin..." -ForegroundColor Yellow
        $proc = Start-Process PowerShell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs -PassThru
        $proc.WaitForExit()
        exit
    }
}

# Function to fetch .reg files from GitHub
function Get-RegFiles {
    Write-Host "`nFetching registry files, please wait..." -ForegroundColor Yellow

    $loadingChars = @("-", "\", "|", "/")
    
    $job = Start-Job -ScriptBlock { 
        # Try local files first
        $localRegPath = Join-Path $using:PSScriptRoot "Registry"
        if (Test-Path $localRegPath) {
            $localFiles = Get-ChildItem -Path $localRegPath -Filter "*.reg"
            if ($localFiles) {
                return $localFiles | ForEach-Object {
                    @{
                        name = $_.Name
                        download_url = $_.FullName
                        isLocal = $true
                    }
                }
            }
        }
        
        # Try GitHub if no local files
        $regFiles = Invoke-RestMethod -Uri $using:apiUrl
        if ($regFiles) {
            return $regFiles | Where-Object { $_.name -match '\.reg$' }
        }
        return $null
    }
    
    $i = 0
    while ($job.State -eq 'Running') {
        Write-Host -NoNewline "`r$($loadingChars[$i])"
        Start-Sleep -Milliseconds 200
        $i = ($i + 1) % $loadingChars.Length
    }

    $result = Receive-Job -Job $job -Wait -AutoRemoveJob
    Write-Host "`r " -NoNewline  # Clear loading animation

    if ($null -eq $result) {
        Write-Host "`n❌ No registry files found locally or on GitHub!" -ForegroundColor Red
        Read-Host "Press ENTER to return to the main menu"
        return @()
    }

    return $result
}

# Function to display the registry file menu
function Show-Menu {
    param([array]$regFiles)

    $selectedIndex = 0
    $maxIndex = $regFiles.Count  # +1 for "Merge All" option

    while ($true) {
        Clear-Host
        Write-Host "============================" -ForegroundColor Cyan
        Write-Host "   GitHub Registry Merger   " -ForegroundColor Cyan
        Write-Host "============================" -ForegroundColor Cyan
        Write-Host "`nUse ↑ ↓ arrow keys to navigate, ENTER to merge, or ESC to exit.`n"

        # Option to merge all .reg files
        if ($selectedIndex -eq $maxIndex) {
            Write-Host " ➜ [ALL] Merge ALL registry files" -ForegroundColor Green
        } else {
            Write-Host "   [ALL] Merge ALL registry files" -ForegroundColor White
        }

        # Display individual files
        for ($i = 0; $i -lt $regFiles.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host " ➜ [$($i+1)] $($regFiles[$i].name)" -ForegroundColor Green
            } else {
                Write-Host "   [$($i+1)] $($regFiles[$i].name)" -ForegroundColor White
            }
        }

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }  # Up Arrow
            40 { if ($selectedIndex -lt $maxIndex) { $selectedIndex++ } }  # Down Arrow
            13 { return $selectedIndex }  # Enter Key
            27 { exit }  # Escape Key
        }
    }
}

# Function to merge a single registry file
function Merge-RegFile {
    param(
        [string]$regUrl,
        [string]$regFileName,
        [bool]$isLocal = $false
    )

    try {
        $regFilePath = if ($isLocal) {
            $regUrl  # For local files, regUrl is actually the full path
        } else {
            $tempRegFile = "$env:TEMP\$regFileName"
            Write-Host "`nDownloading registry file: $regFileName..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $regUrl -OutFile $tempRegFile -ErrorAction Stop
            Write-Host "✅ Registry file downloaded successfully!" -ForegroundColor Green
            $tempRegFile
        }

        Write-Host "`nMerging $regFileName into the registry..." -ForegroundColor Yellow
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$regFilePath`"" -Wait -NoNewWindow
        Write-Host "✅ Registry file merged successfully!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error merging registry file: $_" -ForegroundColor Red
    }

    Read-Host "Press ENTER to return to the menu"
}

# Function to merge all registry files
function Merge-AllRegFiles {
    param([array]$regFiles)

    Write-Host "`nMerging all available registry files..." -ForegroundColor Yellow

    foreach ($regFile in $regFiles) {
        Merge-RegFile -regUrl $regFile.download_url -regFileName $regFile.name -isLocal:$regFile.isLocal
    }

    Write-Host "`n✅ All registry files have been merged successfully!" -ForegroundColor Green
    Read-Host "Press ENTER to return to the menu"
}

# Ensure the script runs as Administrator
Test-Admin

# Main loop to return to menu after execution
while ($true) {
    # Fetch .reg files
    $regFiles = Get-RegFiles
    if (-not $regFiles) { continue }

    # Show menu and get user selection
    $selectedIndex = Show-Menu -regFiles $regFiles

    # If "Merge All" option is selected
    if ($selectedIndex -eq $regFiles.Count) {
        Merge-AllRegFiles -regFiles $regFiles
    } else {
        # Merge the selected .reg file
        $selectedRegFile = $regFiles[$selectedIndex]
        Merge-RegFile -regUrl $selectedRegFile.download_url -regFileName $selectedRegFile.name -isLocal:$selectedRegFile.isLocal
    }
}
