# PowerShell Scripts Menu

A dynamic PowerShell script menu that allows executing scripts directly from GitHub.

## Usage

Run this one-liner to access the menu:

```powershell
iex (iwr "https://raw.githubusercontent.com/algiers/powershell-scripts/master/menu.ps1").Content
```

## Features

- Dynamically lists all .ps1 scripts in the repository
- Interactive menu for script selection
- Direct execution from GitHub
- Simple one-liner access

## Structure

- `menu.ps1` - Main menu script that lists and executes available scripts
- `/Scripts` - Directory containing PowerShell scripts
  - `hello.ps1` - Example script that displays a greeting and current time
  - `Reset-UsbDevices.ps1` - Script to reset all connected USB devices (Must be run as Administrator)
    - Automatically downloads and sets up required utilities
    - Smart device filtering (skips root hubs)
    - Reliable device management
    - Real-time progress tracking with color coding
    - Robust error handling per device
    - Safe sequential device reset process
  - `ManagePostgreSQLService.ps1` - PostgreSQL Service Registration and Startup Script
    - Registers PostgreSQL service using pg_ctl if not present
    - Verifies and manages service startup state
    - Provides comprehensive status verification
    - Clear error handling and reporting
    - Prerequisites:
      - PostgreSQL installed at: D:\CHIFAPLUS\PostgreSQL\9.3\
      - Administrative privileges required
      - Data directory: D:\CHIFAPLUS\PostgreSQL\9.3\data
  - `RegistryManagement.ps1` - Automated Registry Files Manager
    - 100% Automated registry file management
    - Auto-detects all .reg files in Registry folder
    - Interactive keyboard navigation menu
      - Up/Down arrows (↑ ↓) to navigate
      - ENTER to merge selected file
      - ESC to exit
    - Administrator mode detection
    - Comprehensive error handling
    - Compatible with older Windows 10 versions
    - Features:
      - Automatic .reg file download
      - Single or batch registry merging
      - Clear success/error feedback
      - Returns to menu after execution
  - `PrinterSharingSolver.ps1` - Print Service Configuration Script
    - Comprehensive print service setup and configuration
    - Feature Installation:
      - LPD Print Service
      - LPR Port Monitor
    - Registry Optimizations:
      - Named pipe protocol enablement
      - Kerberos authentication management
      - Security protocol adjustments
    - Print Spooler Management:
      - Spooler file cleanup
      - Service restart handling
    - Security Configurations:
      - RPC authentication adjustments
      - Enhanced compatibility settings
    - Requirements:
      - Administrator privileges required
      - Windows OS with print services

## Adding New Scripts

1. Create your PowerShell script (`.ps1` file)
2. Place it in the `/Scripts` directory
3. The menu will automatically detect and list it

## Security Note

Scripts are executed directly from GitHub. Always review scripts before running them in your environment.
