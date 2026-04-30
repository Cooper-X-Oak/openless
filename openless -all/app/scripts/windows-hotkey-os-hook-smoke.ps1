param(
  [string]$ExePath = "",
  [int]$TimeoutSeconds = 20,
  [int]$VirtualKey = 0xA3
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ExePath)) {
  $appRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  $ExePath = Join-Path $appRoot ".artifacts\windows-gnu\dev\openless.exe"
}

if (-not $env:SystemDrive) {
  $env:SystemDrive = "C:"
}
if (-not $env:ProgramData) {
  $env:ProgramData = Join-Path $env:SystemDrive "ProgramData"
}

if (-not (Test-Path $ExePath)) {
  throw "OpenLess executable not found: $ExePath"
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class OpenLessInput {
  [StructLayout(LayoutKind.Sequential)]
  public struct INPUT {
    public int type;
    public INPUTUNION u;
  }

  [StructLayout(LayoutKind.Explicit)]
  public struct INPUTUNION {
    [FieldOffset(0)]
    public KEYBDINPUT ki;
  }

  [StructLayout(LayoutKind.Sequential)]
  public struct KEYBDINPUT {
    public ushort wVk;
    public ushort wScan;
    public int dwFlags;
    public int time;
    public IntPtr dwExtraInfo;
  }

  [DllImport("user32.dll", SetLastError = true)]
  public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

  [DllImport("user32.dll")]
  public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, UIntPtr dwExtraInfo);

  public const int INPUT_KEYBOARD = 1;
  public const int KEYEVENTF_EXTENDEDKEY = 0x0001;
  public const int KEYEVENTF_KEYUP = 0x0002;
}
"@

function Wait-LogPattern($Path, $Pattern, $TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-Path $Path) {
      $text = Get-Content -Raw $Path
      if ($text -match $Pattern) {
        return $true
      }
    }
    Start-Sleep -Milliseconds 250
  }
  return $false
}

function Send-KeyEdge($Vk, $KeyUp) {
  $flags = [OpenLessInput]::KEYEVENTF_EXTENDEDKEY
  if ($KeyUp) {
    $flags = $flags -bor [OpenLessInput]::KEYEVENTF_KEYUP
  }
  [OpenLessInput]::keybd_event([byte]$Vk, 0x1D, $flags, [UIntPtr]::Zero)
  return

  $input = New-Object OpenLessInput+INPUT
  $input.type = [OpenLessInput]::INPUT_KEYBOARD
  $input.u.ki.wVk = [uint16]$Vk
  $input.u.ki.wScan = 0
  $input.u.ki.dwFlags = if ($KeyUp) { [OpenLessInput]::KEYEVENTF_KEYUP } else { 0 }
  $input.u.ki.time = 0
  $input.u.ki.dwExtraInfo = [IntPtr]::Zero
  $sent = [OpenLessInput]::SendInput(1, @($input), [Runtime.InteropServices.Marshal]::SizeOf([type][OpenLessInput+INPUT]))
  if ($sent -ne 1) {
    throw "SendInput failed for vk=$Vk keyUp=$KeyUp"
  }
}

$logPath = Join-Path $env:LOCALAPPDATA "OpenLess\Logs\openless.log"
Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
Get-Process openless -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "== Windows OS hotkey hook smoke =="
$env:OPENLESS_SHOW_MAIN_ON_START = "1"
try {
  $process = Start-Process -FilePath $ExePath -WorkingDirectory (Split-Path $ExePath -Parent) -PassThru
} finally {
  Remove-Item Env:OPENLESS_SHOW_MAIN_ON_START -ErrorAction SilentlyContinue
}

try {
  if (-not (Wait-LogPattern $logPath "WH_KEYBOARD_LL installed" $TimeoutSeconds)) {
    throw "Windows low-level keyboard hook was not installed within $TimeoutSeconds seconds."
  }

  Send-KeyEdge $VirtualKey $false
  Start-Sleep -Milliseconds 400
  Send-KeyEdge $VirtualKey $true

  if (-not (Wait-LogPattern $logPath "\[hotkey\] Windows trigger pressed" $TimeoutSeconds)) {
    throw "Windows hook did not observe synthetic vk=$VirtualKey press."
  }
  if (-not (Wait-LogPattern $logPath "\[coord\] hotkey pressed" $TimeoutSeconds)) {
    throw "Coordinator did not observe OS hook hotkey press."
  }
  Write-Host "[ok] Windows low-level hook observed vk=$VirtualKey and reached Coordinator."
} finally {
  Get-Process openless -ErrorAction SilentlyContinue | Stop-Process -Force
}

Write-Host "Windows OS hotkey hook smoke passed."
