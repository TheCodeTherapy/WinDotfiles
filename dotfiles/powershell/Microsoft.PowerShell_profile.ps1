### PowerShell Profile =======================================================
###
### $PROFILE
### C:\Users\marcogomez\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
###

# Find out if current user identity is elevated (admin)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Define the path to winfetch.ps1
$winfetchPath = "$env:USERPROFILE\WinDotfiles\bin\winfetch.ps1"

# Define custom ANSI color for directories (only works in PowerShell 7+)
if ($PSVersionTable.PSVersion.Major -ge 7) {
  $PSStyle.FileInfo.Directory = "`e[38;5;255m`e[48;2;30;70;120m"
  $PSStyle.FileInfo.SymbolicLink = "`e[38;5;222m`e[48;2;30;70;120m"
}

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Write-Output "isAdmin: $isAdmin"	

function cd... { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }

function md5 { Get-FileHash -Algorithm MD5 $args }
function sha1 { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

function lr {
  if ($args.Count -gt 0) {
    Get-ChildItem -Recurse -Include "$args" | ForEach-Object FullName
  }
  else {
    Get-ChildItem -Recurse | ForEach-Object FullName
  }
}

function l {
  if ($args.Count -gt 0) {
    Get-ChildItem -Include "$args"
  }
  else {
    Get-ChildItem
  }
}

function ll {
  if ($args.Count -gt 0) {
    Get-ChildItem -Include "$args" | Format-Table -AutoSize
  }
  else {
    Get-ChildItem | Format-Table -AutoSize
  }
}

function admin {
  if ($args.Count -gt 0) {
    $argList = "& '" + $args + "'"
    Start-Process "$psHome\powershell.exe" -Verb RunAs -ArgumentList $argList
  }
  else {
    Start-Process "$psHome\powershell.exe" -Verb RunAs
  }
}

function uptime {
  Get-WmiObject win32_operatingsystem | Select-Object csname, @{LABEL = 'LastBootUpTime';
    EXPRESSION                                                        = { $_.ConverttoDateTime($_.lastbootuptime) }
  }
}

function update-profile {
  & $PROFILE
}

function find($name) {
  Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
    $place_path = $_.directory
    Write-Output "${place_path}\${_}"
  }
}

function which($name) {
  Get-Command $name | Select-Object -ExpandProperty Definition
}

function pkill($name) {
  Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function psgrep($name) {
  Get-Process $name
}

function chocolog() {
  $logPath = "$env:ChocolateyInstall\logs\chocolatey.log"
  if (Test-Path $logPath) {
    # open the file in vscode
    code $logPath
  }
  else {
    Write-Output "Log file not found: $logPath"
  }
}

Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin
Set-Alias -Name dirs -Value lr

if ($PSVersionTable.PSVersion.Major -ge 7) {
  if (Test-Path $winfetchPath) {
    # & $winfetchPath -Logo "Windows 7" -showpkgs winget,scoop,choco
    & $winfetchPath -Logo "Windows 7"
  }
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/catppuccin_mocha.omp.json" | Invoke-Expression
