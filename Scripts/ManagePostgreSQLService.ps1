# Configuration
$serviceName = "postgresql-9.3"
$pgBinPath = "D:\CHIFAPLUS\PostgreSQL\9.3\bin"
$dataDir = "D:\CHIFAPLUS\PostgreSQL\9.3\data"
$serviceUser = "NT AUTHORITY\NetworkService"

# Change directory to PostgreSQL bin folder
Set-Location -Path $pgBinPath

# Function to test service existence (uses approved verb "Test")
function Test-ServiceExistence {
    param ($name)
    try {
        return Get-Service -Name $name -ErrorAction Stop
    } catch {
        Write-Host "Service '$name' does not exist"
        return $null
    }
}

# Check if service exists
$existingService = Test-ServiceExistence -name $serviceName

if (-not $existingService) {
    Write-Host "Registering PostgreSQL service..."
    
    # Register the service using pg_ctl
    & .\pg_ctl.exe register `
        -N $serviceName `
        -U $serviceUser `
        -D $dataDir `
        -w
    
    # Check registration result
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Service registration failed with exit code $LASTEXITCODE"
        exit 1
    }
    
    Write-Host "Service registered successfully"
} else {
    Write-Host "Service '$serviceName' already exists"
}

# Check service status after registration
$service = Test-ServiceExistence -name $serviceName

if ($service.Status -ne 'Running') {
    Write-Host "Starting PostgreSQL service..."
    
    # Attempt to start the service
    Start-Service -Name $serviceName -ErrorAction Stop
    
    # Wait for service to start (up to 30 seconds)
    $service.WaitForStatus('Running', '00:00:30')
    
    if ($service.Status -ne 'Running') {
        Write-Error "Service failed to start"
        exit 1
    }
    
    Write-Host "Service started successfully"
} else {
    Write-Host "Service is already running"
}

# Final verification
$finalStatus = (Get-Service -Name $serviceName).Status
Write-Host "Final service status: $finalStatus"