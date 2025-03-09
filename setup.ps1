# ┌─────────────────────────────────────────────────────────────────────────┐
# │ WinDotfiles setup script, by Marco Gomez (@TheCodeTherapy) 2025         │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ C:\Users\marcogomez\WinDotfiles\setup.ps1                               │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ This script creates symbolic links for your PowerShell profiles.        │
# │ It will link the profile in your WinDotfiles directory to the           │
# │ appropriate location for PowerShell 7 and 5. Among other things.        │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ Written to be used on Windows 10 Enterprise LTSC 2021 -> 2031 ...       │
# │ because fuck Microsoft and its bloat, ads, and abusive data mining on   │
# │ a fucking PAID operating system. We're not idiots, nor products.        │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ usage: .\setup.ps1                                                      │
# └─────────────────────────────────────────────────────────────────────────┘

# NOTE: I use Windows 10 LTSC and because chocolatey and winget are weird to
# install and usually are not immediately available after installation, I've
# wrote this script to be executed twice. The first time, for example, it
# will skip chocolatey packages instalation because it's not available, and
# on the second run it will install the packages.

# NOTE: Before running nvim for the first time, you must install any recent
# NodeJS LTS version through nvm, as some neovim scripts will need NodeJS
# to install and configure plugins.

# 🔹 Package Lists
$wingetPackages = @("Microsoft.WindowsTerminal", "Microsoft.PowerShell", "JanDeDobbeleer.OhMyPosh")
$chocoPackages = @("llvm", "nvm", "lazygit", "fd", "fzf", "ripgrep", "neovim")

# 🔹 Auto-Elevate: Relaunch as Administrator if not already elevated
$scriptPath = $MyInvocation.MyCommand.Definition
$scriptArgs = $args -join ' '
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
  Write-Host "🔸 Elevation required. Restarting as Administrator..."
  Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $scriptArgs" -Verb RunAs
  exit
}

Write-Host "✅ Running as Administrator."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$dotfilesProfile = Join-Path $scriptDir "dotfiles\powershell\Microsoft.PowerShell_profile.ps1"
$dotfilesTerminalSettings = Join-Path $scriptDir "dotfiles\terminal\settings.json"
$dotfilesVSCodeSettings = Join-Path $scriptDir "dotfiles\vscode\settings.json"
$dotfilesWinfetchSettings = Join-Path $scriptDir "dotfiles\winfetch\config.ps1"
$dotfilesNvimConfig = Join-Path $scriptDir "dotfiles\nvim"

# Define target paths ========================================================
$ps7Profile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$ps5Profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$vscodeSettingsPath = "$env:APPDATA\Code\User\settings.json"
$winfetchSettingsPath = "$env:USERPROFILE\.config\winfetch\config.ps1"
$nvimConfigPath = "$env:LOCALAPPDATA\nvim"

$terminalSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
# Fallback for manually installed Windows Terminal
if (-Not (Test-Path $terminalSettingsPath)) {
  $terminalSettingsPath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json"
}
# ============================================================================

# Ensure the source profile exists
if (-Not (Test-Path $dotfilesProfile)) {
  Write-Host "❌ Error: Source profile not found at $dotfilesProfile" -ForegroundColor Red
  exit 1
}

# Function to create symbolic link
function New-Symlink {
  param (
    [string]$target,
    [string]$link
  )
  
  # Check if link already exists and remove it if necessary
  if (Test-Path $link) {
    Write-Host "Removing existing profile at $link"
    Remove-Item -Force $link
  }

  # Create the symbolic link
  Write-Host "Creating symbolic link: $link -> $target"
  New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null

  # Verify creation
  if (Test-Path $link) {
    Write-Host "✅ Symlink created successfully: $link -> $(Get-Item $link).Target"
  } else {
    Write-Host "❌ Failed to create symlink: $link" -ForegroundColor Red
  }
}

# Function to pause execution and wait for a key press
function Wait-ForKeyPress {
  Write-Host "`nPress any key to exit..."
  $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 🔹 Ensure Chocolatey is Installed
function Install-Chocolatey {
  if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "🍫 Chocolatey is not installed. Installing now..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  } else {
    Write-Host "✅ Chocolatey is already installed."
  }
}

# 🔹 Install Chocolatey Packages
function Install-Chocolatey-Packages {
  if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ Chocolatey is not installed. Skipping Chocolatey package installation." -ForegroundColor Yellow
    return
  }

  foreach ($package in $chocoPackages) {
    $installed = choco list --local-only | Select-String -Pattern "^$package "
    if ($installed) {
      Write-Host "✅ $package is already installed. Checking for updates..."
      choco upgrade $package -y
    } else {
      Write-Host "📦 Installing $package..."
      choco install $package -y
    }
  }
}

# 🔹 Install Winget Packages
function Install-Winget-Packages {
  if (-Not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ Winget is not installed or not available in the PATH." -ForegroundColor Yellow
    return
  }

  foreach ($package in $wingetPackages) {
    $installed = winget list --id $package --exact 2>$null
    if ($installed -match $package) {
      Write-Host "✅ $package is already installed. Checking for updates..."
      winget upgrade --id $package --exact --silent --accept-source-agreements
    } else {
      Write-Host "📦 Installing $package..."
      winget install --id $package --exact --silent --accept-source-agreements
    }
  }
}

# 🔹 Install All Packages
function Install-Packages {
  Install-Winget-Packages
  Install-Chocolatey-Packages
}

if ($isAdmin) {
  Write-Host "🔸 Installing packages..."
  Install-Packages
}

if ($isAdmin) {
  Write-Host "🔸 Checking Chocolatey install..."
  Install-Chocolatey
}

# Create symlinks for PowerShell 7 and 5
New-Symlink -target $dotfilesProfile -link $ps7Profile
New-Symlink -target $dotfilesProfile -link $ps5Profile
New-Symlink -target $dotfilesTerminalSettings -link $terminalSettingsPath
New-Symlink -target $dotfilesVSCodeSettings -link $vscodeSettingsPath
New-Symlink -target $dotfilesWinfetchSettings -link $winfetchSettingsPath
New-Symlink -target $dotfilesNvimConfig -link $nvimConfigPath
Write-Host "🎉 All symbolic links have been created successfully!" -ForegroundColor Green

if ($isAdmin) {
  Wait-ForKeyPress
}
