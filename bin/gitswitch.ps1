# gitswitch.ps1
[CmdletBinding()]
param()

$SshDir = "$HOME\.ssh"

if (-not (Test-Path $SshDir)) {
  New-Item -ItemType Directory -Path $SshDir | Out-Null
}

function Switch-KeyPair($sourcePriv, $sourcePub) {
  $destPriv = Join-Path $SshDir "id_rsa"
  $destPub = Join-Path $SshDir "id_rsa.pub"

  foreach ($file in @($destPriv, $destPub)) {
    if (Test-Path $file) {
      # Take ownership
      takeown /F $file /A /R /D Y > $null 2>&1
      # Grant full control to current user
      icacls $file /grant:r "$($env:USERNAME):(F)" /inheritance:r > $null 2>&1
      # Remove read-only if set
      attrib -R $file 2>$null
      # Delete file
      Remove-Item $file -Force
    }
  }

  Copy-Item $sourcePriv $destPriv -Force
  if (Test-Path $sourcePub) {
    Copy-Item $sourcePub $destPub -Force
  }

  # Restrict permissions to mimic OpenSSH requirement (no group/other access)
  icacls $destPriv /inheritance:r /grant:r "$($env:USERNAME):F" "SYSTEM:F" > $null
}

Write-Host "Select profile:"
Write-Host "1) Personal"
Write-Host "2) Improbable"
$choice = Read-Host "Enter choice (1 or 2)"

switch ($choice) {
  1 {
    Write-Host "Switching to Personal Git Credentials..."
    Switch-KeyPair "$SshDir\personal_id_rsa" "$SshDir\personal_id_rsa.pub"
  }
  2 {
    Write-Host "Switching to Improbable Git Credentials..."
    Switch-KeyPair "$SshDir\improbable_id_rsa" "$SshDir\improbable_id_rsa.pub"
  }
  default {
    Write-Host "Invalid choice."
    exit 1
  }
}

Write-Host "Done! Test with: ssh -T git@github.com"
