Get-PnpDevice -Class USB | Where-Object { $_.Status -eq "OK" } | ForEach-Object {
    $deviceId = $_.InstanceId
    Disable-PnpDevice -InstanceId $deviceId -Confirm:$false
    Start-Sleep -Seconds 1
    Enable-PnpDevice -InstanceId $deviceId -Confirm:$false
    Start-Sleep -Seconds 1
}