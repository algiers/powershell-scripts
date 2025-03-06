# menu.ps1 - Modern PowerShell Menu with Enhanced UI (PowerShell 5.1 Compatible)
#requires -Version 5.0

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Configuration
$config = @{
    Title       = "GitHub PowerShell Scripts"
    ApiUrl      = "https://api.github.com/repos/algiers/powershell-scripts/contents/Scripts"
    Colors      = @{
        Primary   = [System.ConsoleColor]::Cyan
        Secondary = [System.ConsoleColor]::DarkCyan
        Highlight = [System.ConsoleColor]::Green
        Warning   = [System.ConsoleColor]::Yellow
        Error     = [System.ConsoleColor]::Red
        Text      = [System.ConsoleColor]::White
        Header    = [System.ConsoleColor]::Magenta
    }
    Symbols     = @{
        Loading  = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        Selected = "►"
        Bullet   = "○"
        Success  = "✓"
        Error    = "✗"
        Info     = "ℹ"
    }
    WindowTitle = "PowerShell Script Manager"
}

# Set window title
$Host.UI.RawUI.WindowTitle = $config.WindowTitle

# Function to safely manage cursor visibility
function Set-CursorVisible {
    param([bool]$Visible)
    try {
        $Host.UI.RawUI.CursorVisible = $Visible
        return $true
    } catch {
        return $false
    }
}

# Function to create a horizontal line
function New-HorizontalLine {
    param (
        [string]$Char = '─',
        [int]$Length = ($Host.UI.RawUI.WindowSize.Width - 2)
    )
    return (-join ($Char * $Length))
}

# Function to center text
function Get-CenteredText {
    param (
        [string]$Text,
        [int]$Width = ($Host.UI.RawUI.WindowSize.Width)
    )
    $padding = [Math]::Max(0, ($Width - $Text.Length) / 2)
    return (-join (' ' * [Math]::Floor($padding))) + $Text
}

# Function to show a notification
function Show-Notification {
    param (
        [string]$Message,
        [System.ConsoleColor]$Color = $config.Colors.Text,
        [string]$Symbol = "",
        [switch]$NoNewLine
    )
    
    if ($Symbol) {
        Write-Host "$Symbol " -NoNewline -ForegroundColor $Color
    }
    
    if ($NoNewLine) {
        Write-Host $Message -NoNewline -ForegroundColor $Color
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Function to display an animated loading indicator
function Show-LoadingAnimation {
    param (
        [scriptblock]$ScriptBlock,
        [string]$LoadingText = "Loading"
    )
    
    $cursorSupported = Set-CursorVisible $false
    $job = Start-Job -ScriptBlock $ScriptBlock
    
    $symbols = $config.Symbols.Loading.ToCharArray()
    $i = 0
    $dots = ""
    
    try {
        while ($job.State -eq 'Running') {
            $dots += "."
            if ($dots.Length -gt 3) { $dots = "." }
            
            Write-Host "`r$($symbols[$i]) $LoadingText$dots" -NoNewline -ForegroundColor $config.Colors.Warning
            
            Start-Sleep -Milliseconds 100
            $i = ($i + 1) % $symbols.Length
        }
        
        Write-Host "`r                      `r" -NoNewline
        
        $result = Receive-Job -Job $job -Wait -AutoRemoveJob
        return $result
    }
    finally {
        if ($cursorSupported) {
            Set-CursorVisible $true
        }
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to fetch scripts with a loading animation
function Get-Scripts {
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        $result = Show-LoadingAnimation -LoadingText "Fetching scripts" -ScriptBlock {
            try {
                $apiUrl = $using:config.ApiUrl
                $scripts = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
                return $scripts | Where-Object { $_.name -match '\.ps1$' }
            }
            catch {
                # Return the error instead of null
                return @{ Error = $_ }
            }
        }
        
        # Check if we got an error object back
        if ($result -is [hashtable] -and $result.ContainsKey('Error')) {
            $retryCount++
            if ($retryCount -ge $maxRetries) {
                Clear-Host
                Show-Notification -Message "Failed to fetch scripts after $maxRetries attempts." -Color $config.Colors.Error -Symbol $config.Symbols.Error
                Write-Host ""
                Show-Notification -Message "Error details: $($result.Error.Message)" -Color $config.Colors.Error
                Write-Host ""
                Show-Notification -Message "Press any key to retry or Esc to exit..." -Color $config.Colors.Warning
                $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 27) { 
                    return $null 
                }
                $retryCount = 0  # Reset retry count if user wants to try again
            }
            else {
                Show-Notification -Message "Connection attempt $retryCount failed. Retrying in 2 seconds..." -Color $config.Colors.Warning
                Start-Sleep -Seconds 2
            }
        }
        elseif ($null -eq $result -or $result.Count -eq 0) {
            Show-Notification -Message "No PowerShell scripts found in the repository." -Color $config.Colors.Warning -Symbol $config.Symbols.Info
            Start-Sleep -Seconds 2
            
            Write-Host ""
            Show-Notification -Message "Press any key to retry or Esc to exit..." -Color $config.Colors.Warning
            $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            if ($key.VirtualKeyCode -eq 27) { 
                return $null 
            }
            $retryCount = 0  # Reset retry count if user wants to try again
        }
        else {
            # Success - return the scripts
            return $result
        }
    }
    
    # If we've exhausted all retries and user chose not to continue
    return $null
}

# Function to draw a box around text
function Show-TextBox {
    param (
        [string]$Title,
        [string[]]$Content
    )
    
    $width = ($Host.UI.RawUI.WindowSize.Width - 4)
    $contentWidth = $width - 2
    
    # Calculate spacing
    $titlePadding = [Math]::Max(0, ($width - $Title.Length - 2) / 2)
    $titleLeft = [Math]::Floor($titlePadding)
    
    # Top border with title
    Write-Host "  ┌" -NoNewline -ForegroundColor $config.Colors.Primary
    Write-Host (-join ("─" * $titleLeft)) -NoNewline -ForegroundColor $config.Colors.Primary
    Write-Host " $Title " -NoNewline -ForegroundColor $config.Colors.Header
    Write-Host (-join ("─" * ($width - $titleLeft - $Title.Length - 2))) -NoNewline -ForegroundColor $config.Colors.Primary
    Write-Host "┐" -ForegroundColor $config.Colors.Primary
    
    # Empty line
    Write-Host "  │" -NoNewline -ForegroundColor $config.Colors.Primary
    Write-Host (-join (" " * $contentWidth)) -NoNewline
    Write-Host "│" -ForegroundColor $config.Colors.Primary
    
    # Content
    foreach ($line in $Content) {
        Write-Host "  │ " -NoNewline -ForegroundColor $config.Colors.Primary
        Write-Host $line -NoNewline
        # Calculate padding to right border
        $padding = $contentWidth - $line.Length - 1
        if ($padding -gt 0) {
            Write-Host (-join (" " * $padding)) -NoNewline
        }
        Write-Host "│" -ForegroundColor $config.Colors.Primary
    }
    
    # Empty line
    Write-Host "  │" -NoNewline -ForegroundColor $config.Colors.Primary
    Write-Host (-join (" " * $contentWidth)) -NoNewline
    Write-Host "│" -ForegroundColor $config.Colors.Primary
    
    # Bottom border
    Write-Host "  └" -NoNewline -ForegroundColor $config.Colors.Primary
    Write-Host (-join ("─" * $width)) -NoNewline -ForegroundColor $config.Colors.Primary
    Write-Host "┘" -ForegroundColor $config.Colors.Primary
}

# Function to display the script menu with keyboard navigation
function Show-Menu {
    param([array]$Scripts)
    
    $selectedIndex = 0
    $scrollOffset = 0
    $maxVisibleItems = [Math]::Min($Scripts.Count, $Host.UI.RawUI.WindowSize.Height - 15)
    
    $cursorSupported = Set-CursorVisible $false
    
    try {
        while ($true) {
            Clear-Host
            
            # Header
            $headerTitle = $config.Title
            Write-Host (Get-CenteredText -Text $headerTitle) -ForegroundColor $config.Colors.Header
            Write-Host (Get-CenteredText -Text (New-HorizontalLine -Char '═' -Length $headerTitle.Length)) -ForegroundColor $config.Colors.Header
            Write-Host ""
            
            # Menu box
            $helpText = "Use ↑↓ or j/k to navigate, Enter to select, Esc to exit"
            Show-TextBox -Title "Available Scripts" -Content @($helpText, "")
            
            # Calculate visible range
            if ($selectedIndex - $scrollOffset -ge $maxVisibleItems) {
                $scrollOffset = $selectedIndex - $maxVisibleItems + 1
            }
            elseif ($selectedIndex -lt $scrollOffset) {
                $scrollOffset = $selectedIndex
            }
            
            $endIndex = [Math]::Min($scrollOffset + $maxVisibleItems - 1, $Scripts.Count - 1)
            
            # Show scroll indicators
            if ($scrollOffset -gt 0) {
                Write-Host "  ⟰ More scripts above" -ForegroundColor $config.Colors.Secondary
            }
            
            # Display visible scripts
            for ($i = $scrollOffset; $i -le $endIndex; $i++) {
                $scriptName = $Scripts[$i].name
                
                # Use if-else instead of ternary operator for PowerShell 5.1 compatibility
                if ($i -eq $selectedIndex) {
                    $scriptSymbol = $config.Symbols.Selected
                    $scriptColor = $config.Colors.Highlight
                } else {
                    $scriptSymbol = $config.Symbols.Bullet
                    $scriptColor = $config.Colors.Text
                }
                
                Write-Host "  " -NoNewline
                Write-Host $scriptSymbol -NoNewline -ForegroundColor $scriptColor
                Write-Host " " -NoNewline
                Write-Host "$scriptName" -ForegroundColor $scriptColor
            }
            
            # Show scroll indicators
            if ($endIndex -lt $Scripts.Count - 1) {
                Write-Host "  ⟱ More scripts below" -ForegroundColor $config.Colors.Secondary
            }
            
            Write-Host ""
            Show-Notification -Message "Script $($selectedIndex + 1) of $($Scripts.Count)" -Color $config.Colors.Secondary -Symbol $config.Symbols.Info
            
            # Get key press
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            # Process key press
            switch ($key.VirtualKeyCode) {
                38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }                 # Up Arrow
                40 { if ($selectedIndex -lt $Scripts.Count - 1) { $selectedIndex++ } } # Down Arrow
                13 { return $selectedIndex }                                          # Enter Key
                27 { return -1 }                                                      # Escape Key - Return -1 instead of exit
                75 { if ($selectedIndex -gt 0) { $selectedIndex-- } }                 # K key (vim-style)
                74 { if ($selectedIndex -lt $Scripts.Count - 1) { $selectedIndex++ } } # J key (vim-style)
                36 { $selectedIndex = 0 }                                             # Home key
                35 { $selectedIndex = $Scripts.Count - 1 }                            # End key
                33 { $selectedIndex = [Math]::Max(0, $selectedIndex - $maxVisibleItems) } # Page Up
                34 { $selectedIndex = [Math]::Min($Scripts.Count - 1, $selectedIndex + $maxVisibleItems) } # Page Down
            }
        }
    }
    finally {
        if ($cursorSupported) {
            Set-CursorVisible $true
        }
    }
}

# Function to execute a script
function Invoke-SelectedScript {
    param (
        [object]$Script
    )
    
    if ($null -eq $Script) {
        return
    }
    
    Clear-Host
    Write-Host (Get-CenteredText -Text "Executing Script") -ForegroundColor $config.Colors.Header
    Write-Host (Get-CenteredText -Text (New-HorizontalLine -Char '═' -Length 16)) -ForegroundColor $config.Colors.Header
    Write-Host ""
    
    Show-TextBox -Title $Script.name -Content @("Downloading and preparing to execute...")
    
    try {
        $scriptContent = Show-LoadingAnimation -LoadingText "Downloading script" -ScriptBlock {
            try {
                Invoke-RestMethod -Uri $using:Script.download_url -ErrorAction Stop
            }
            catch {
                return @{ Error = $_ }
            }
        }
        
        # Check if we got an error object back
        if ($scriptContent -is [hashtable] -and $scriptContent.ContainsKey('Error')) {
            throw $scriptContent.Error
        }
        
        Write-Host ""
        Show-Notification -Message "Script downloaded successfully!" -Color $config.Colors.Highlight -Symbol $config.Symbols.Success
        Write-Host ""
        
        # Create a temporary script file
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $scriptContent | Out-File -FilePath $tempFile -Encoding UTF8
        
        # Execute it in a new scope
        Show-Notification -Message "Executing script..." -Color $config.Colors.Warning
        Write-Host ""
        Write-Host (New-HorizontalLine) -ForegroundColor $config.Colors.Secondary
        Write-Host ""
        
        & $tempFile
        
        Write-Host ""
        Write-Host (New-HorizontalLine) -ForegroundColor $config.Colors.Secondary
        Write-Host ""
        Show-Notification -Message "Script execution completed!" -Color $config.Colors.Highlight -Symbol $config.Symbols.Success
        
        # Clean up
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host ""
        Show-Notification -Message "Error: $_" -Color $config.Colors.Error -Symbol $config.Symbols.Error
    }
    
    Write-Host ""
    Show-Notification -Message "Press any key to return to the menu..." -Color $config.Colors.Warning
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Handles exiting the application
function Exit-Application {
    Clear-Host
    Write-Host (Get-CenteredText -Text "Thank you for using PowerShell Script Manager") -ForegroundColor $config.Colors.Header
    Write-Host ""
    exit
}

# Main application loop
function Start-Application {
    while ($true) {
        # Clear screen and set cursor position
        Clear-Host
        
        # Fetch scripts
        $scripts = Get-Scripts
        if (-not $scripts) { 
            # Check if user wants to exit
            Clear-Host
            Show-Notification -Message "No scripts available. Press any key to retry or Esc to exit..." -Color $config.Colors.Warning
            $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            if ($key.VirtualKeyCode -eq 27) { 
                Exit-Application
            }
            continue
        }
        
        # Show menu and get user selection
        $selectedIndex = Show-Menu -Scripts $scripts
        
        # Check if user pressed Esc to exit
        if ($selectedIndex -eq -1) {
            Exit-Application
        }
        
        $selectedScript = $scripts[$selectedIndex]
        
        # Execute the selected script
        Invoke-SelectedScript -Script $selectedScript
    }
}

# Start the application
try {
    Start-Application
}
catch {
    Clear-Host
    Write-Host "An unexpected error occurred:" -ForegroundColor $config.Colors.Error
    Write-Host $_.Exception.Message -ForegroundColor $config.Colors.Error
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor $config.Colors.Warning
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
