# Run from the repository root: powershell -ExecutionPolicy Bypass -File .\scripts\repair-submodules.ps1
$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$paths = @("packages/Open-AI-Design-Agent", "packages/Open-Poe-AI", "packages/Vibe-Workflow")
$statuses = @(git submodule status)
if ($LASTEXITCODE -ne 0) { throw "Unable to read git submodule status." }
$pending = @()
foreach ($path in $paths) {
  $line = @($statuses | Where-Object { $_ -match [regex]::Escape($path) + '(\s|$)' } | Select-Object -First 1)
  if ($line.Count -eq 0) { throw "Missing submodule entry: $path" }
  if ($line[0].StartsWith("-")) { $pending += $path }
}
if ($pending.Count -eq 0) {
  Write-Host "All three submodules are already initialized."
} else {
  $backupRoot = Join-Path (Split-Path (Get-Location).Path -Parent) ("higsfild-submodule-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss-fff"))
  foreach ($path in $pending) {
    if (Test-Path -LiteralPath $path) {
      $destination = Join-Path $backupRoot $path
      New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
      Move-Item -LiteralPath $path -Destination $destination -ErrorAction Stop
      Write-Host "Backed up $path to $destination"
    }
  }
  git submodule sync --recursive
  if ($LASTEXITCODE -ne 0) { throw "Submodule sync failed. Backups are at $backupRoot" }
  git submodule update --init --recursive
  if ($LASTEXITCODE -ne 0) { throw "Submodule checkout failed. Backups are at $backupRoot" }
}
git submodule status
Write-Host "Submodules initialized. Next: npm install; npm run build:packages"
