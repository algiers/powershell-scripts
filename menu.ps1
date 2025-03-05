# menu.ps1

# GitHub API URL to list files in the Scripts folder
$apiUrl = "https://api.github.com/repos/algiers/powershell-scripts/contents/Scripts"

# Fetch scripts
try {
    $scripts = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop | Where-Object { $_.name -match '\.ps1$' }
} catch {
    Write-Host "Failed to fetch scripts: $_"
    exit
}

# Display menu
Write-Host "`n=== Available Scripts ===`n"
for ($i = 0; $i -lt $scripts.Count; $i++) {
    Write-Host "$($i+1). $($scripts[$i].name)"
}

# Get user input
try {
    $choice = Read-Host "`nEnter the number of the script to run"
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $scripts.Count) {
        throw "Invalid selection."
    }
    $selectedScript = $scripts[$index]
    
    # Download and execute the selected script
    $scriptUrl = $selectedScript.download_url
    $scriptContent = Invoke-RestMethod -Uri $scriptUrl -ErrorAction Stop
    Invoke-Expression -Command $scriptContent
} catch {
    Write-Host "Error: $_"
}
