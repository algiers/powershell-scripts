# Script pour désactiver le pare-feu Windows sur tous les profils
# Requires -RunAsAdministrator

# Vérifier si le script est exécuté en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ce script nécessite des privilèges d'administrateur. Veuillez l'exécuter en tant qu'administrateur." -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 1
}

# Demander confirmation avant de désactiver le pare-feu
$confirmation = Read-Host "Êtes-vous sûr de vouloir désactiver le pare-feu Windows ? (O/N)"
if ($confirmation -ne "O") {
    Write-Host "Opération annulée." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour quitter"
    exit
}

try {
    # Désactiver le pare-feu sur tous les profils
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Write-Host "Le pare-feu Windows a été désactivé avec succès sur tous les profils." -ForegroundColor Green
} catch {
    Write-Host "Une erreur s'est produite lors de la désactivation du pare-feu :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Pause équivalent en PowerShell
Read-Host "Appuyez sur Entrée pour continuer"
