param(
  [string]$ExePath = "$env:TEMP\openless-windows-gnu\src-tauri\target\x86_64-pc-windows-gnu\release\openless.exe",
  [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = "Stop"

function Wait-LogPattern($Path, $Pattern, $Since, $TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-Path $Path) {
      $lines = Get-Content -Path $Path -Tail 200
      foreach ($line in $lines) {
        if ($line -match $Pattern) {
          return $true
        }
      }
    }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

if (-not (Test-Path $ExePath)) {
  throw "OpenLess executable not found: $ExePath"
}

$logPath = Join-Path $env:LOCALAPPDATA "OpenLess\Logs\openless.log"
Get-Process openless -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue

Write-Host "== Hotkey injection smoke =="
$env:OPENLESS_DEBUG_HOTKEY_ON_START = "1"
$process = Start-Process -FilePath $ExePath -PassThru
try {
  if (-not (Wait-LogPattern $logPath "\[debug\] injecting startup hotkey press" (Get-Date) $TimeoutSeconds)) {
    throw "Debug hotkey injection did not start within $TimeoutSeconds seconds."
  }
  if (-not (Wait-LogPattern $logPath "\[coord\] hotkey pressed" (Get-Date) $TimeoutSeconds)) {
    throw "Coordinator did not observe injected hotkey press within $TimeoutSeconds seconds."
  }
  if (-not (Wait-LogPattern $logPath "\[debug\] startup hotkey injection completed" (Get-Date) $TimeoutSeconds)) {
    throw "Debug hotkey injection did not complete within $TimeoutSeconds seconds."
  }
  Write-Host "[ok] Coordinator hotkey path observed without physical keyboard input."
} finally {
  Remove-Item Env:OPENLESS_DEBUG_HOTKEY_ON_START -ErrorAction SilentlyContinue
  Get-Process openless -ErrorAction SilentlyContinue | Stop-Process -Force
}

Write-Host "Hotkey injection smoke passed."
