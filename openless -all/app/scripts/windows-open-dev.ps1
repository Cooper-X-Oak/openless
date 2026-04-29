param(
  [string]$ExePath = "$env:TEMP\openless-windows-gnu\src-tauri\target\x86_64-pc-windows-gnu\release\openless.exe"
)

$ErrorActionPreference = "Stop"

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class OpenLessWindow {
  [DllImport("user32.dll")]
  public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

  [DllImport("user32.dll")]
  public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

function Show-OpenLessWindow($Process) {
  if ($null -eq $Process -or $Process.MainWindowHandle -eq 0) {
    return $false
  }

  # 9 = SW_RESTORE. This restores minimized windows and leaves normal windows visible.
  [OpenLessWindow]::ShowWindow($Process.MainWindowHandle, 9) | Out-Null
  [OpenLessWindow]::SetForegroundWindow($Process.MainWindowHandle) | Out-Null
  return $true
}

$running = Get-Process openless -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  Select-Object -First 1

if (Show-OpenLessWindow $running) {
  Write-Host "OpenLess is already running; brought window to foreground. pid=$($running.Id)"
  exit 0
}

if (-not (Test-Path $ExePath)) {
  throw "OpenLess executable not found: $ExePath. Run scripts/windows-build-gnu.ps1 first."
}

$process = Start-Process -FilePath $ExePath -PassThru
$deadline = (Get-Date).AddSeconds(10)

while ((Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 250
  $current = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
  if (Show-OpenLessWindow $current) {
    Write-Host "OpenLess started and brought to foreground. pid=$($current.Id)"
    exit 0
  }
}

throw "OpenLess started but no main window was visible within 10 seconds. pid=$($process.Id)"
