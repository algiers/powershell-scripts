# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

# Function to rename the computer
function Set-ComputerNameWithRestart {
    param (
        [Parameter(Mandatory=$true)]
        [string]$NewName
    )
    
    try {
        Write-Host "Attempting to rename computer to: $NewName" -ForegroundColor Yellow
        Rename-Computer -NewName $NewName -Force
        Write-Host "Computer renamed successfully. A restart will be required for changes to take effect." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to rename computer: $_" -ForegroundColor Red
        return $false
    }
}

# Function to set IP address and DNS
function Set-NetworkConfiguration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InterfaceAlias,
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,
        [Parameter(Mandatory=$true)]
        [int]$SubnetMask,
        [Parameter(Mandatory=$true)]
        [string]$Gateway,
        [Parameter(Mandatory=$true)]
        [string[]]$DNSServers
    )
    
    try {
        # Validate network interface exists
        $interface = Get-NetAdapter | Where-Object { $_.Name -eq $InterfaceAlias }
        if (-not $interface) {
            Write-Host "Network interface '$InterfaceAlias' not found. Available interfaces:" -ForegroundColor Red
            Get-NetAdapter | Format-Table Name, InterfaceDescription
            return $false
        }

        # Remove existing IP addresses
        Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false

        # Remove existing gateway
        Remove-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Confirm:$false

        # Set new IP configuration
        Write-Host "Configuring IP address and gateway..." -ForegroundColor Yellow
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $SubnetMask -DefaultGateway $Gateway

        # Set DNS servers
        Write-Host "Configuring DNS servers..." -ForegroundColor Yellow
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DNSServers

        Write-Host "Network configuration completed successfully." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to configure network settings: $_" -ForegroundColor Red
        return $false
    }
}

# Function to list available network interfaces
function Show-NetworkInterfaces {
    Write-Host "`nAvailable Network Interfaces:" -ForegroundColor Cyan
    Get-NetAdapter | Format-Table Name, InterfaceDescription, Status
}

# Main script
$restartNeeded = $false

# Menu system
do {
    Write-Host "`n=== PC Name and Network Configuration Tool ===" -ForegroundColor Cyan
    Write-Host "1. Rename Computer"
    Write-Host "2. Configure Network Settings"
    Write-Host "3. Show Network Interfaces"
    Write-Host "4. Exit"
    Write-Host "==========================================" -ForegroundColor Cyan

    $choice = Read-Host "`nEnter your choice (1-4)"

    switch ($choice) {
        "1" {
            $newName = Read-Host "`nEnter the new computer name"
            if (Set-ComputerNameWithRestart -NewName $newName) {
                $restartNeeded = $true
            }
        }
        "2" {
            Show-NetworkInterfaces
            $interfaceAlias = Read-Host "`nEnter the network interface name"
            $ipAddress = Read-Host "Enter the IP address"
            $subnetMask = Read-Host "Enter the subnet mask prefix length (e.g., 24 for 255.255.255.0)"
            $gateway = Read-Host "Enter the default gateway"
            $dns1 = Read-Host "Enter the primary DNS server"
            $dns2 = Read-Host "Enter the secondary DNS server (or press Enter to skip)"

            $dnsServers = @($dns1)
            if ($dns2) {
                $dnsServers += $dns2
            }

            Set-NetworkConfiguration -InterfaceAlias $interfaceAlias -IPAddress $ipAddress -SubnetMask $subnetMask -Gateway $gateway -DNSServers $dnsServers
        }
        "3" {
            Show-NetworkInterfaces
        }
        "4" {
            break
        }
        default {
            Write-Host "Invalid choice. Please enter a number between 1 and 4." -ForegroundColor Red
        }
    }
} while ($choice -ne "4")

# If computer was renamed, prompt for restart
if ($restartNeeded) {
    Write-Host "`nThe computer name has been changed and requires a restart to take effect." -ForegroundColor Yellow
    $restart = Read-Host "Would you like to restart now? (yes/no)"
    if ($restart -eq "yes") {
        Restart-Computer -Force
    }
}

Write-Host "`nScript execution completed." -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
