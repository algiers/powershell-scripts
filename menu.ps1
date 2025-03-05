# menu.ps1 - Improved UX/UI with Auto-Return to Menu

# Define GitHub API URL to list files in the Scripts folder
$apiUrl = "https://api.github.com/repos/algiers/powershell-scripts/contents/Scripts"

# Function to fetch scripts with a loading animation
function Get-Scripts {
    Write-Host "`nFetching scripts, please wait..." -ForegroundColor Yellow
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
        Write-Host "`n❌ Failed to fetch scripts. Check your internet connection!" -ForegroundColor Red
        exit
    }

    return $result | Where-Object { $_.name -match '\.ps1$' }
}

# Function to display the script menu with keyboard navigation
function Show-Menu {
    param([array]$scripts)

    $selectedIndex = 0
    $maxIndex = $scripts.Count - 1

    while ($true) {
        Clear-Host
        Write-Host "============================" -ForegroundColor Cyan
        Write-Host "   GitHub PowerShell Menu   " -ForegroundColor Cyan
        Write-Host "============================" -ForegroundColor Cyan
        Write-Host "`nUse ↑ ↓ arrow keys to navigate, ENTER to run, or ESC to exit.`n"

        for ($i = 0; $i -lt $scripts.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host " ➜ [$($i+1)] $($scripts[$i].name)" -ForegroundColor Green
            } else {
                Write-Host "   [$($i+1)] $($scripts[$i].name)" -ForegroundColor White
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

# Main loop to return to menu after execution
while ($true) {
    # Fetch scripts
    $scripts = Get-Scripts
    if (-not $scripts) { exit }

    # Show menu and get user selection
    $selectedIndex = Show-Menu -scripts $scripts
    $selectedScript = $scripts[$selectedIndex]

    # Download and execute the selected script
    Write-Host "`nDownloading and executing $($selectedScript.name)..." -ForegroundColor Yellow
    try {
        $scriptContent = Invoke-RestMethod -Uri $selectedScript.download_url -ErrorAction Stop
        Invoke-Expression -Command $scriptContent
    } catch {
        Write-Host "❌ Error executing script: $_" -ForegroundColor Red
    }

    # Wait for user before returning to menu
    Write-Host "`nPress any key to return to the menu..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
