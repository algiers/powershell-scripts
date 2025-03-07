# Registry Merge Menu - Fetch and Apply .reg Files from GitHub

# Configuration file path
$configFilePath = Join-Path $PSScriptRoot "registry_paths.json"

# Configuration
$config = @{
    ApiUrl      = "https://api.github.com/repos/algiers/powershell-scripts/contents/Scripts/Registry"
    # Array of paths to search for registry files
    RegistryPaths = @(
        (Join-Path $PSScriptRoot "Registry")  # Default local path
    )
}

# Function to load registry paths from configuration file
function Load-RegistryPaths {
    if (Test-Path $configFilePath) {
        $savedPaths = Get-Content $configFilePath -Raw | ConvertFrom-Json
        $config.RegistryPaths = $savedPaths
    }
}

# Function to save registry paths to configuration file
function Save-RegistryPaths {
    $config.RegistryPaths | ConvertTo-Json | Set-Content $configFilePath
}

# Function to add a new registry path
function Add-RegistryPath {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "Path does not exist: $Path"
    }
    
    if (-not ($config.RegistryPaths -contains $Path)) {
        $config.RegistryPaths += $Path
        Save-RegistryPaths
        return $true
    }
    return $false
}

# Function to remove a registry path
function Remove-RegistryPath {
    param([string]$Path)
    
    $config.RegistryPaths = $config.RegistryPaths | Where-Object { $_ -ne $Path }
    Save-RegistryPaths
}

# Function to check if running as Administrator
function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "! This script requires Administrator privileges. Restarting as Admin..." -ForegroundColor Yellow
        $proc = Start-Process PowerShell -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs -PassThru
        $proc.WaitForExit()
        exit
    }
}

# Function to manage registry paths
function Show-PathManager {
    $selectedIndex = 0
    
    try {
        while ($true) {
            Clear-Host
            Write-Host "===== Registry Path Manager =====" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Current registry paths:" -ForegroundColor Yellow
            Write-Host "(Local files take precedence over GitHub files)" -ForegroundColor DarkGray
            
            for ($i = 0; $i -lt $config.RegistryPaths.Count; $i++) {
                if ($i -eq $selectedIndex) {
                    Write-Host " > " -NoNewline -ForegroundColor Green
                } else {
                    Write-Host "   " -NoNewline
                }
                Write-Host "$($config.RegistryPaths[$i])"
            }
            
            Write-Host "`nControls:" -ForegroundColor Yellow
            Write-Host "  [A] Add new path"
            Write-Host "  [D] Delete selected path"
            Write-Host "  [ESC] Return to main menu"
            
            $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode
            
            switch ($key) {
                38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }                    # Up Arrow
                40 { if ($selectedIndex -lt ($config.RegistryPaths.Count - 1)) { $selectedIndex++ } } # Down Arrow
                65 { # 'A' key - Add path
                    Clear-Host
                    Write-Host "Enter new registry path (or press Enter to cancel):" -ForegroundColor Yellow
                    $newPath = Read-Host
                    if ($newPath) {
                        try {
                            if (Add-RegistryPath $newPath) {
                                Write-Host "Path added successfully!" -ForegroundColor Green
                            } else {
                                Write-Host "Path already exists." -ForegroundColor Yellow
                            }
                            Start-Sleep -Seconds 1
                        } catch {
                            Write-Host "Error: $_" -ForegroundColor Red
                            Start-Sleep -Seconds 2
                        }
                    }
                }
                68 { # 'D' key - Delete path
                    if ($config.RegistryPaths.Count -gt 1 -and $selectedIndex -lt $config.RegistryPaths.Count) {
                        Remove-RegistryPath $config.RegistryPaths[$selectedIndex]
                        if ($selectedIndex -ge $config.RegistryPaths.Count) {
                            $selectedIndex = $config.RegistryPaths.Count - 1
                        }
                    }
                }
                27 { return }  # ESC key - Return to main menu
            }
        }
    }
    finally {
        $Host.UI.RawUI.CursorVisible = $true
    }
}

# Function to fetch .reg files
function Get-RegFiles {
    Write-Host "`nFetching registry files, please wait..." -ForegroundColor Yellow

    $loadingChars = @("-", "\", "|", "/")
    
    $job = Start-Job -ScriptBlock { 
        try {
            # Initialize unique files dictionary
            $uniqueFiles = @{}
            
            # First check local paths (they take precedence)
            foreach ($path in $using:config.RegistryPaths) {
                if (Test-Path $path) {
                    $localFiles = Get-ChildItem -Path $path -Filter "*.reg" -Recurse -ErrorAction SilentlyContinue
                    if ($localFiles) {
                        $localFiles | ForEach-Object {
                            # Only add if not already present
                            if (-not $uniqueFiles.ContainsKey($_.Name)) {
                                $uniqueFiles[$_.Name] = @{
                                    name = $_.Name
                                    download_url = $_.FullName
                                    isLocal = $true
                                    location = $_.DirectoryName
                                }
                            }
                        }
                    }
                }
            }
            
            # Then check GitHub for any additional files
            try {
                $apiUrl = $using:config.ApiUrl
                $files = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
                if ($files) {
                    $files | Where-Object { $_.name -match '\.reg$' } | ForEach-Object {
                        # Only add if we don't already have a local version
                        if (-not $uniqueFiles.ContainsKey($_.name)) {
                            $_ | Add-Member -NotePropertyName isLocal -NotePropertyValue $false -PassThru
                            $_ | Add-Member -NotePropertyName location -NotePropertyValue "GitHub" -PassThru
                            $uniqueFiles[$_.name] = $_
                        }
                    }
                }
            } catch {
                Write-Warning "Could not fetch GitHub registry files: $_"
            }
            
            # Convert dictionary values to array
            return @($uniqueFiles.Values)
        }
        catch {
            Write-Warning "Error fetching registry files: $_"
            return $null
        }
    }
    
    $i = 0
    while ($job.State -eq 'Running') {
        Write-Host -NoNewline "`r$($loadingChars[$i])"
        Start-Sleep -Milliseconds 200
        $i = ($i + 1) % $loadingChars.Length
    }

    $result = Receive-Job -Job $job -Wait -AutoRemoveJob
    Write-Host "`r " -NoNewline  # Clear loading animation

    if ($null -eq $result -or $result.Count -eq 0) {
        Write-Host "`nx No registry files found locally or on GitHub!" -ForegroundColor Red
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
        Write-Host "   Registry File Manager   " -ForegroundColor Cyan
        Write-Host "============================" -ForegroundColor Cyan
        Write-Host "`nUse Up/Down arrows to navigate, Enter to merge, P to manage paths, or ESC to exit.`n"

        # Option to merge all .reg files
        if ($selectedIndex -eq $maxIndex) {
            Write-Host " > [ALL] Merge ALL registry files" -ForegroundColor Green
        } else {
            Write-Host "   [ALL] Merge ALL registry files" -ForegroundColor White
        }

        # Display individual files
        for ($i = 0; $i -lt $regFiles.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host " > [$($i+1)] $($regFiles[$i].name)" -ForegroundColor Green
                Write-Host "   Location: $($regFiles[$i].location)" -ForegroundColor DarkGray
            } else {
                Write-Host "   [$($i+1)] $($regFiles[$i].name)" -ForegroundColor White
            }
        }

        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode
        switch ($key) {
            38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }  # Up Arrow
            40 { if ($selectedIndex -lt $maxIndex) { $selectedIndex++ } }  # Down Arrow
            13 { return $selectedIndex }  # Enter Key
            27 { return -1 }  # Escape Key - Return to main menu
            80 { Show-PathManager; return -2 }  # 'P' key - Show path manager
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
            Write-Host "+ Registry file downloaded successfully!" -ForegroundColor Green
            $tempRegFile
        }

        Write-Host "`nMerging $regFileName into the registry..." -ForegroundColor Yellow
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$regFilePath`"" -Wait -NoNewWindow
        Write-Host "+ Registry file merged successfully!" -ForegroundColor Green
    } catch {
        Write-Host "x Error merging registry file: $_" -ForegroundColor Red
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

    Write-Host "`n+ All registry files have been merged successfully!" -ForegroundColor Green
    Read-Host "Press ENTER to return to the menu"
}

# Initialize configuration
Load-RegistryPaths

# Ensure the script runs as Administrator
Test-Admin

# Main loop to return to menu after execution
while ($true) {
    # Fetch .reg files
    $regFiles = Get-RegFiles
    if (-not $regFiles) { continue }

    # Show menu and get user selection
    $selectedIndex = Show-Menu -regFiles $regFiles
    
    if ($selectedIndex -eq -2) {
        # User accessed path manager, refresh files
        continue
    }
    
    # Check if user wants to return to main menu
    if ($selectedIndex -eq -1) {
        Write-Host "`nReturning to main menu..." -ForegroundColor Yellow
        break
    }
    
    # If "Merge All" option is selected
    if ($selectedIndex -eq $regFiles.Count) {
        Merge-AllRegFiles -regFiles $regFiles
    } else {
        # Merge the selected .reg file
        $selectedRegFile = $regFiles[$selectedIndex]
        Merge-RegFile -regUrl $selectedRegFile.download_url -regFileName $selectedRegFile.name -isLocal:$selectedRegFile.isLocal
    }
}
