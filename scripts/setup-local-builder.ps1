$ErrorActionPreference = "Stop"

function Ensure-Command {
  param(
    [string]$Name,
    [string]$PackageId
  )

  if (Get-Command $Name -ErrorAction SilentlyContinue) {
    Write-Host "✅ $Name is installed."
    return
  }

  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required to install $Name automatically. Install it, then rerun this script."
  }

  Write-Host "📦 Installing $Name via winget..."
  winget install --id $PackageId --accept-package-agreements --accept-source-agreements
}

Ensure-Command -Name "git" -PackageId "Git.Git"
Ensure-Command -Name "node" -PackageId "OpenJS.NodeJS.LTS"
Ensure-Command -Name "npm" -PackageId "OpenJS.NodeJS.LTS"
Ensure-Command -Name "cargo" -PackageId "Rustlang.Rustup"
Ensure-Command -Name "ffmpeg" -PackageId "Gyan.FFmpeg"

node scripts/setup-local-builder.mjs @args
