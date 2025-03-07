# PowerShell Script Manager

A modern PowerShell script management tool that allows you to run scripts from both local paths and GitHub.

## Quick Start

Run this command to download and start the Script Manager:

```powershell
iex (iwr "https://raw.githubusercontent.com/algiers/powershell-scripts/main/ExecuteRemotely.ps1" -UseBasicParsing).Content
```

## Features

- Run scripts from local paths and GitHub
- Manage multiple script locations
- Modern, interactive UI with keyboard navigation
- Registry file management
- Local files take precedence over GitHub versions
- Easy path management

## Installation

1. **Quick Install (Temporary)**
   ```powershell
   iex (iwr "https://raw.githubusercontent.com/algiers/powershell-scripts/main/ExecuteRemotely.ps1" -UseBasicParsing).Content
   ```

2. **Manual Installation**
   - Clone the repository:
     ```powershell
     git clone https://github.com/algiers/powershell-scripts.git
     cd powershell-scripts
     ```
   - Run the menu script:
     ```powershell
     .\menu.ps1
     ```

## Usage

### Script Manager (menu.ps1)
- Use Up/Down arrows or j/k to navigate
- Enter to select and run a script
- Press 'P' to manage script paths
- ESC to exit

### Registry Manager (RegistryManagement.ps1)
- Requires Administrator privileges
- Use Up/Down arrows to navigate
- Enter to merge registry files
- Press 'P' to manage registry paths
- ESC to exit

## Path Management

Both tools support managing multiple paths:
1. Press 'P' to open the path manager
2. Use 'A' to add new paths
3. Use 'D' to delete selected paths
4. Local files take precedence over GitHub versions

## File Locations

- Scripts are stored in `%USERPROFILE%\PowerShellScripts` by default
- Path configurations are saved in:
  - `script_paths.json` for PowerShell scripts
  - `registry_paths.json` for Registry files

## Requirements

- PowerShell 5.1 or later
- Internet connection for GitHub features (optional)
- Administrator rights for registry operations

## Notes

- Local files with the same name as GitHub files take precedence
- All paths are remembered between sessions
- Registry operations require elevation to Administrator
