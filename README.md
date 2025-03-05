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
    - Simple and effective USB device management
    - Uses native PowerShell PnP commands
    - Clear device enumeration and status reporting
    - Real-time progress tracking with color coding
    - Robust error handling per device
    - Safe sequential device reset process

## Adding New Scripts

1. Create your PowerShell script (`.ps1` file)
2. Place it in the `/Scripts` directory
3. The menu will automatically detect and list it

## Security Note

Scripts are executed directly from GitHub. Always review scripts before running them in your environment.
