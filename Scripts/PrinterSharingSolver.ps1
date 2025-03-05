# Enable required Windows features without restart
Enable-WindowsOptionalFeature -Online `
    -FeatureName "Printing-Foundation-LPDPrintService" `
    -NoRestart -WarningAction SilentlyContinue

Enable-WindowsOptionalFeature -Online `
    -FeatureName "Printing-Foundation-LPRPortMonitor" `
    -NoRestart -WarningAction SilentlyContinue

# Configure Print RPC settings
$rpcKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"

# Create registry path if it doesn't exist
if (-not (Test-Path $rpcKeyPath)) {
    New-Item -Path $rpcKeyPath -Force | Out-Null
}

# Set registry values
$registrySettings = @{
    RpcUseNamedPipeProtocol = 1
    RpcAuthentication       = 0
    RpcProtocols            = 7
    ForceKerberosForRpc     = 0
    RpcTcpPort              = 0
}

foreach ($setting in $registrySettings.GetEnumerator()) {
    Set-ItemProperty -Path $rpcKeyPath `
        -Name $setting.Key `
        -Value $setting.Value `
        -Type DWord `
        -Force
}

# Clear print spooler files
$spoolerDir = "$env:windir\System32\spool\PRINTERS\"
Remove-Item -Path "$spoolerDir*" -Recurse -Force -ErrorAction SilentlyContinue

# Stop print spooler service
Stop-Service -Name "Spooler" -Force -ErrorAction Stop

# Configure additional print security setting
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" `
    -Name "RpcAuthnLevelPrivacyEnabled" `
    -Value 0 `
    -Type DWord `
    -Force

# Restart print spooler service
Start-Service -Name "Spooler" -ErrorAction Stop

# Clear spooler files again after restart
Remove-Item -Path "$spoolerDir*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Registry keys and print services configured successfully"