# menu.ps1 - Modern PowerShell Script Manager (PowerShell 5.1 Compatible)
#requires -Version 5.0

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Determine base paths
$scriptPath = $MyInvocation.MyCommand.Path
$baseDir = if ($scriptPath) { 
    Split-Path $scriptPath -Parent 
} else { 
    Join-Path $env:USERPROFILE "PowerShellScripts" 
}

# Ensure Scripts directory exists
$scriptsDir = Join-Path $baseDir "Scripts"
if (-not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
}

# Configuration file path
$configFilePath = Join-Path $baseDir "script_paths.json"

# Default configuration
$config = @{
    Title       = "PowerShell Scripts Manager"
    ApiUrl      = "https://api.github.com/repos/algiers/powershell-scripts/contents/Scripts"
    RemoteSource = "GitHub"
    ScriptPaths = @(
        $scriptsDir  # Default local path
    )
    Colors      = @{
        Primary   = [System.ConsoleColor]::Cyan
        Secondary = [System.ConsoleColor]::DarkCyan
        Highlight = [System.ConsoleColor]::Green
        Warning   = [System.ConsoleColor]::Yellow
        Error     = [System.ConsoleColor]::Red
        Text      = [System.ConsoleColor]::White
        Header    = [System.ConsoleColor]::Magenta
    }
    Symbols     = @{
        Loading   = "-\|/"
        Selected  = ">"
        Bullet    = "*"
        Success   = "+"
        Error     = "x"
        Info      = "i"
    }
    WindowTitle = "PowerShell Script Manager"
}

# Function to load script paths from configuration file
function Load-ScriptPaths {
    if (Test-Path $configFilePath) {
        try {
            $savedConfig = Get-Content $configFilePath -Raw | ConvertFrom-Json
            if ($savedConfig.PSObject.Properties.Name -contains "ScriptPaths") {
                $config.ScriptPaths = $savedConfig.ScriptPaths
            } else {
                Write-Warning "Invalid script_paths.json structure. Resetting to defaults."
            }
        } catch {
            Write-Warning "Error loading script paths from ${configFilePath}: $_"
        }
    }
}

# Function to save script paths to configuration file
function Save-ScriptPaths {
    try {
        $configToSave = @{ ScriptPaths = $config.ScriptPaths }
        $configToSave | ConvertTo-Json -Depth 10 | Set-Content $configFilePath
    } catch {
        Write-Warning "Error saving script paths to ${configFilePath}: $_"
    }
}

# Set window title
$Host.UI.RawUI.WindowTitle = $config.WindowTitle

# Function to display a notification
function Show-Notification {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = $config.Colors.Text,
        [string]$Symbol = "*"
    )
    Write-Host "$Symbol $Message" -ForegroundColor $Color
}

# Function to get available scripts
function Get-Scripts {
    $allScripts = @()
    
    # Get local scripts
    foreach ($path in $config.ScriptPaths) {
        if (Test-Path $path) {
            Get-ChildItem -Path $path -Filter *.ps1 | ForEach-Object {
                $allScripts += @{
                    name        = $_.Name
                    location    = $_.DirectoryName
                    download_url= $_.FullName
                    isLocal     = $true
                }
            }
        }
    }

    # Get remote scripts if enabled
    if ($config.RemoteSource -eq "GitHub") {
        try {
            $githubContent = Invoke-RestMethod -Uri $config.ApiUrl -UseBasicParsing
            foreach ($item in $githubContent) {
                if ($item.name -match "\.ps1$") {
                    $allScripts += @{
                        name        = $item.name
                        location    = "GitHub"
                        download_url= $item.download_url
                        isLocal     = $false
                    }
                }
            }
        } catch {
            Write-Warning "Failed to fetch GitHub scripts: $_"
        }
    }

    # Combine local and remote scripts, ensuring no duplicates
    $localScripts = $allScripts | Where-Object { $_.isLocal }
    $remoteScripts = $allScripts | Where-Object { -not $_.isLocal }
    $combinedScripts = $localScripts + $remoteScripts | Sort-Object name -Unique
    return $combinedScripts
}

# Function to create a horizontal line
function New-HorizontalLine {
    param (
        [char]$Char = '-',
        [int]$Length = ($Host.UI.RawUI.WindowSize.Width - 2)
    )
    return ($Char * $Length)
}

# Function to execute a script
function Invoke-SelectedScript {
    param (
        [object]$Script
    )
    
    if ($null -eq $Script) {
        return
    }
    
    Clear-Host
    Show-Notification -Message "Executing: $($Script.name)" -Color $config.Colors.Header
    
    try {
        $scriptContent = if ($Script.isLocal) {
            Get-Content -Path $Script.download_url -Raw
        } else {
            Invoke-RestMethod -Uri $Script.download_url -ErrorAction Stop
        }
        
        Write-Host "Script downloaded successfully!" -ForegroundColor $config.Colors.Highlight
        
        # Create a temporary script file
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $scriptContent | Out-File -FilePath $tempFile -Encoding UTF8
        
        # Execute it
        & $tempFile
        
        # Cleanup
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        Show-Notification -Message "Script execution completed!" -Color $config.Colors.Success
    }
    catch {
        Show-Notification -Message "Error executing script: $_" -Color $config.Colors.Error
    }
    
    Write-Host "Press any key to return to the menu..." -ForegroundColor $config.Colors.Warning
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Function to display the menu
function Show-ScriptMenu {
    param([array]$Scripts)
    
    while ($true) {
        Clear-Host
        Write-Host "`n==== PowerShell Script Manager ====" -ForegroundColor $config.Colors.Header
        Write-Host "Select a script to execute:`n"
        
        for ($i = 0; $i -lt $Scripts.Count; $i++) {
            Write-Host "[$i] $($Scripts[$i].name) ($($Scripts[$i].location))"
        }
        
        Write-Host "`n[R] Refresh | [X] Exit"
        $choice = Read-Host "Enter selection"
        
        if ($choice -match "^\d+$") {
            $index = [int]$choice
            if ($index -ge 0 -and $index -lt $Scripts.Count) {
                Invoke-SelectedScript -Script $Scripts[$index]
            } else {
                Write-Host "Invalid selection." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        } elseif ($choice -eq "R") {
            return
        } elseif ($choice -eq "X") {
            Exit
        } else {
            Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

# Main function
function Start-Application {
    while ($true) {
        Clear-Host
        $scripts = Get-Scripts
        if (-not $scripts) { 
            Show-Notification -Message "No scripts available. Press Enter to retry or type X to exit..." -Color $config.Colors.Warning
            $key = Read-Host
            if ($key -eq "X") { Exit }
            continue
        }
        
        Show-ScriptMenu -Scripts $scripts
    }
}

# Initialize and start application
Load-ScriptPaths
Start-Application
