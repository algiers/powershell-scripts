# Print Flush - 1.3 - By Brad Kovach
# Requires -RunAsAdministrator

# Vérifier si le script est exécuté en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ce script nécessite des privilèges d'administrateur. Veuillez l'exécuter en tant qu'administrateur." -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 1
}

Write-Host ('-' * 34) -ForegroundColor Cyan
Write-Host "Print Flush - 1.3 - By Brad Kovach" -ForegroundColor Cyan
Write-Host ('-' * 34) -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Stop the Print Spooler
    Write-Host "Step 1: Stopping the Print Spooler..." -ForegroundColor Yellow
    Stop-Service -Name Spooler -Force
    Write-Host "Spooler service stopped." -ForegroundColor Green
    Write-Host ""

    # Step 1.5: Reassigning Print Spooler Dependencies
    Write-Host "Step 1.5: Reassigning Print Spooler Dependencies..." -ForegroundColor Yellow
    Write-Host "This step is important if you have a Lexmark printer which may interfere with service startup." -ForegroundColor Gray
    sc.exe config spooler depend= RPCSS
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dependencies reassigned successfully." -ForegroundColor Green
    } else {
        Write-Host "Warning: Could not reassign dependencies. Error code: $LASTEXITCODE" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 2: Clearing Junk Printer Documents
    Write-Host "Step 2: Removing junk printer documents..." -ForegroundColor Yellow
    $spoolerPath = "$env:SystemRoot\System32\Spool\Printers\*"
    if (Test-Path $spoolerPath) {
        Remove-Item -Path $spoolerPath -Force -Recurse
        Write-Host "Spooler directory cleared successfully." -ForegroundColor Green
    } else {
        Write-Host "No junk documents found." -ForegroundColor Green
    }
    Write-Host ""

    # Step 3: Restarting the Print Spooler
    Write-Host "Step 3: Restarting the Print Spooler..." -ForegroundColor Yellow
    Start-Service -Name Spooler
    $spoolerStatus = Get-Service -Name Spooler
    if ($spoolerStatus.Status -eq 'Running') {
        Write-Host "Print Spooler restarted successfully." -ForegroundColor Green
    } else {
        Write-Host "Warning: Print Spooler service is not running. Status: $($spoolerStatus.Status)" -ForegroundColor Yellow
    }
    Write-Host ""

    # Step 4: Completion Message
    Write-Host "Step 4: Print Flush completed successfully. You can now try printing again." -ForegroundColor Green
} catch {
    Write-Host "An error occurred during the Print Flush process:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Read-Host "Appuyez sur Entrée pour continuer"
