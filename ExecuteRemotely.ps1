# Bootstrap script to download and execute PowerShell Script Manager

# GitHub repository information
$repo = @{
    Owner = "algiers"
    Name = "powershell-scripts"
    Branch = "main"
}

# Function to safely create directory
function New-SafeDirectory {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            return $true
        } catch {
            Write-Host "Error creating directory $Path : $_" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

# Main execution block
try {
    # Create base paths
    $basePath = Join-Path $env:USERPROFILE "PowerShellScripts"
    $scriptsPath = Join-Path $basePath "Scripts"
    
    # Ensure directories exist
    if (-not (New-SafeDirectory $basePath) -or -not (New-SafeDirectory $scriptsPath)) {
        throw "Failed to create required directories"
    }

    # Download menu.ps1
    $menuUrl = "https://raw.githubusercontent.com/$($repo.Owner)/$($repo.Name)/$($repo.Branch)/menu.ps1"
    $menuPath = Join-Path $basePath "menu.ps1"
    
    Write-Host "Downloading script manager..." -ForegroundColor Yellow
    try {
        $menuContent = (Invoke-WebRequest -Uri $menuUrl -UseBasicParsing).Content
        if ([string]::IsNullOrWhiteSpace($menuContent)) {
            throw "Received empty content"
        }
        $menuContent | Out-File -FilePath $menuPath -Encoding UTF8 -Force
    } catch {
        throw "Failed to download menu script: $_"
    }

    Write-Host "Starting script manager..." -ForegroundColor Green
    & $menuPath

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
