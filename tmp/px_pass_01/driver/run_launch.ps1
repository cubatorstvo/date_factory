param(
  [Parameter(Mandatory = $true)][string]$Persona,
  [string]$Godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe",
  [string]$Project = "C:\Users\User\Documents\GodotProjects\date_factory",
  [string]$Resolution = "1920x1080"
)

$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path $Project)) { $Project = "C:\Users\User\Documents\GodotProjects\date_factory" }
$Px = Join-Path $Project "tmp\px_pass_01"
$UserData = Join-Path $Px ("userdata_" + $Persona)
$Log = Join-Path $Px ("logs\godot_" + $Persona + "_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
$PidFile = Join-Path $Px ("logs\pid_" + $Persona + ".txt")
$HwndFile = Join-Path $Px ("logs\hwnd_" + $Persona + ".txt")

# Fresh isolated profile for this persona
if (Test-Path $UserData) { Remove-Item -Recurse -Force $UserData }
New-Item -ItemType Directory -Force -Path $UserData | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null

$env:APPDATA = $UserData
$cmd = @(
  $Godot,
  "--path", $Project,
  "--resolution", $Resolution,
  "--windowed"
)

$stdout = $Log
$argLine = ($cmd | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
Write-Output "LAUNCH: $argLine"
Write-Output "APPDATA=$env:APPDATA"
Write-Output "LOG=$Log"

# Record exact launch in a sidecar commands file
$cmdRecord = Join-Path $Px ("logs\commands_" + $Persona + ".txt")
@(
  "utc=$(Get-Date -Format o)",
  "APPDATA=$env:APPDATA",
  "cmd=$argLine",
  "resolution=$Resolution",
  "ui_scale_intent=100%_via_fresh_profile"
) | Set-Content -Encoding UTF8 $cmdRecord

$p = Start-Process -FilePath $Godot -ArgumentList @("--path", $Project, "--resolution", $Resolution, "--windowed") -PassThru -RedirectStandardOutput $Log -RedirectStandardError (Join-Path $Px ("logs\godot_" + $Persona + "_stderr.log")) -WorkingDirectory $Project
$p.Id | Set-Content -Encoding ASCII $PidFile
Write-Output "pid=$($p.Id)"
Write-Output "pid_file=$PidFile"
Write-Output "log=$Log"
