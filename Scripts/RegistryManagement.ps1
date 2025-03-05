# Registry Merge Menu - Fetch and Apply .reg Files from GitHub

# Define GitHub API URL to list .reg files in the Registry folder
$apiUrl = "https://api.github.com/repos/algiers/powershell-scripts/contents/Registry"

# Function to check if running as Administrator (Renamed to Test-Admin)
function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "⚠️  Please run this script as Administrator to apply registry changes!" -ForegroundColor Red
        exit
    }
}

# Function to fetch .reg files with a loading animation
function Get-RegFiles {
    Write-Host "`nFetching registry files, please wait..." -ForegroundColor Yellow
    $loadingChars = @("-", "\", "|", "/")
    
    $job = Start-Job -ScriptBlock { Invoke-RestMethod -Uri $using:apiUrl }
    $i = 0

    while ($job.State -eq 'Running') {
        Write-Host -NoNewline "`r$($loadingChars[$i])"
        Start-Sleep -Milliseconds 200
        $i = ($i + 1) % $loadingChars.Length
    }

    $result = Receive-Job -Job $job -Wait -AutoRemoveJob
    if ($null -eq $result) {
        Write-Host "`n❌ Failed to fetch registry files. Check your internet connection!" -ForegroundColor Red
        exit
    }

    return $result | Where-Object { $_.name -match '\.reg$' }
}

# Function to display the registry file menu with keyboard navigation
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
    param([string]$regUrl, [string]$regFileName)

    $tempRegFile = "$env:TEMP\$regFileName"

    try {
        Write-Host "`nDownloading registry file: $regFileName..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $regUrl -OutFile $tempRegFile -ErrorAction Stop
        Write-Host "✅ Registry file downloaded successfully!" -ForegroundColor Green

        Write-Host "`nMerging $regFileName into the registry..." -ForegroundColor Yellow
        Start-Process "regedit.exe" -ArgumentList "/s `"$tempRegFile`"" -Wait -NoNewWindow
        Write-Host "✅ Registry file merged successfully!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error merging registry file: $_" -ForegroundColor Red
    }
}

# Function to merge all registry files
function Merge-AllRegFiles {
    param([array]$regFiles)

    Write-Host "`nMerging all available registry files..." -ForegroundColor Yellow

    foreach ($regFile in $regFiles) {
        Merge-RegFile -regUrl $regFile.download_url -regFileName $regFile.name
    }

    Write-Host "`n✅ All registry files have been merged successfully!" -ForegroundColor Green
}

# Check if the script is running as Administrator
Test-Admin

# Main loop to return to menu after execution
while ($true) {
    # Fetch .reg files
    $regFiles = Get-RegFiles
    if (-not $regFiles) { exit }

    # Show menu and get user selection
    $selectedIndex = Show-Menu -regFiles $regFiles

    # If "Merge All" option is selected
    if ($selectedIndex -eq $regFiles.Count) {
        Merge-AllRegFiles -regFiles $regFiles
    } else {
        # Download and merge the selected .reg file
        $selectedRegFile = $regFiles[$selectedIndex]
        Merge-RegFile -regUrl $selectedRegFile.download_url -regFileName $selectedRegFile.name
    }

    # Wait for user before returning to menu
    Write-Host "`nPress any key to return to the menu..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
