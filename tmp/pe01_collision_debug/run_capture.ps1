$ErrorActionPreference = "Continue"
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
$proj = "C:\Users\User\Documents\GodotProjects\date_factory"
$scene = "res://tmp/pe01_collision_debug/apartment_collision_debug_capture.tscn"
$logDir = Join-Path $proj "tmp\pe01_collision_debug\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stdout = Join-Path $logDir "godot_collision_debug_$stamp.log"

# Isolate userdata so capture never mutates player saves.
$env:XDG_DATA_HOME = Join-Path $proj "tmp\pe01_collision_debug\userdata"
New-Item -ItemType Directory -Force -Path $env:XDG_DATA_HOME | Out-Null

Get-Process | Where-Object { $_.ProcessName -like "Godot*" } | ForEach-Object {
    Write-Output "Stopping leftover Godot pid=$($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Output "Launching: $godot --path $proj --resolution 1280x720 --windowed --quit-after 90 $scene"
& $godot --path $proj --resolution 1280x720 --windowed --quit-after 90 $scene *>&1 | Tee-Object -FilePath $stdout
$code = $LASTEXITCODE
Write-Output "exit_code=$code"
Write-Output "stdout=$stdout"
exit $code
