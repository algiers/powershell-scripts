# PowerShell Scripts Menu

A dynamic PowerShell script menu that allows executing scripts directly from GitHub.

## Recent Updates

### Visual Enhancements

- Used Unicode box-drawing characters to create clean, modern borders
- Added color-coded UI elements with a consistent color scheme
- Implemented centered text and proper spacing for a more professional look
- Created text boxes with titles for better organization
- Added smooth animated loading indicators (spinner animation)

### Usability Improvements

- Added vim-style navigation (j/k keys) in addition to arrow keys
- Implemented scrolling for large script lists with indicators
- Added pagination controls (Page Up/Down, Home/End)
- Improved status and information displays
- Better error handling with clear visual indicators
- Added script count and position indicators
- Enhanced window title for better task management

### Technical Improvements

- Used proper PowerShell namespace declarations for better type safety
- Organized configuration settings into a centralized structure
- Created reusable UI functions for consistent display
- Implemented safer script execution by using temporary files
- Added proper error handling throughout the application
- Improved loading animations with dynamic feedback

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
    - Smart device filtering (skips root hubs, keyboards, mice)
    - Reliable device management with enhanced error handling
    - Real-time progress tracking with color coding
    - Detailed success/failure reporting per device
    - Safe sequential device reset process
    - Improved device identification and status tracking
  - `renamePC_IP_DNS.ps1` - Computer Name and Network Configuration Tool
    - Interactive menu-driven interface
    - Computer renaming with restart management
    - Network interface configuration:
      - IP address setup
      - Subnet mask configuration
      - Default gateway assignment
      - Primary and secondary DNS configuration
    - Features:
      - Network interface listing and validation
      - Automatic removal of existing configurations
      - Color-coded status messages
      - Comprehensive error handling
      - Administrative privilege verification
    - Requirements:
      - Administrator privileges required
      - Windows OS with network adapter
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
    - Latest Improvements:
      - Enhanced error handling for registry file fetching
      - Menu return option when no .reg files found
      - Graceful handling of GitHub API issues
      - Persistent operation - stays open after file merging
      - Better user experience with clear status messages
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

  - `DisableFirewall.ps1` - Windows Firewall Management Script
    - Safe and controlled firewall management
    - Features:
      - Disables firewall across all profiles (Domain, Public, Private)
      - Interactive confirmation prompt
      - Color-coded status messages
      - Comprehensive error handling
    - Security Features:
      - Administrator privilege verification
      - Execution confirmation prompt
      - Safe exit on unauthorized access
    - Requirements:
      - Administrator privileges required
      - Windows OS with Windows Firewall

## Adding New Scripts

1. Create your PowerShell script (`.ps1` file)
2. Place it in the `/Scripts` directory
3. The menu will automatically detect and list it

## Security Note

Scripts are executed directly from GitHub. Always review scripts before running them in your environment.
