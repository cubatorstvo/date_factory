# DATE FACTORY release headless autotest launcher (PowerShell)
# Modes: smoke | full | both. No window focus. Writes raw engine log + concise report.
# Exit 0 only when selected mode(s) PASS; non-zero on FAIL / missing Godot / missing report.

param(
	[ValidateSet("smoke", "full", "both")]
	[string]$Mode = "both",
	[string]$GodotExe = "C:\godot\Godot_v4.7.1-stable_win64.exe",
	[string]$ProjectPath = "C:\Users\User\Documents\GodotProjects\date_factory",
	[int]$SmokeQuitAfterSec = 120,
	[int]$FullQuitAfterSec = 300
)

$ErrorActionPreference = "Continue"
$Artifacts = Join-Path $ProjectPath "tests\release\artifacts"
New-Item -ItemType Directory -Force -Path $Artifacts | Out-Null

if (-not (Test-Path -LiteralPath $GodotExe)) {
	Write-Host "ERROR: Godot executable not found: $GodotExe"
	exit 2
}

function Stop-ProjectReleaseGodot {
	Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
		Where-Object {
			$_.Name -match "Godot" -and
			$_.CommandLine -and
			$_.CommandLine -match [regex]::Escape($ProjectPath) -and
			$_.CommandLine -match "tests[/\\]release"
		} |
		ForEach-Object {
			Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
		}
}

function Invoke-ReleaseMode {
	param(
		[string]$Name,
		[string]$ScriptRes,
		[string]$LogName,
		[string]$ReportName,
		[int]$QuitAfterSec
	)
	$logPath = Join-Path $Artifacts $LogName
	$reportPath = Join-Path $Artifacts $ReportName
	if (Test-Path $logPath) { Remove-Item -Force $logPath -ErrorAction SilentlyContinue }
	if (Test-Path $reportPath) { Remove-Item -Force $reportPath -ErrorAction SilentlyContinue }

	Write-Host "=== RELEASE $Name START ==="
	$sw = [System.Diagnostics.Stopwatch]::StartNew()
	$argList = @(
		"--headless",
		"--path", $ProjectPath,
		"--script", $ScriptRes,
		"--log-file", $logPath,
		"--quit-after", "$QuitAfterSec"
	)
	$proc = Start-Process -FilePath $GodotExe -ArgumentList $argList -PassThru -Wait -NoNewWindow
	$sw.Stop()
	$code = 1
	if ($null -ne $proc.ExitCode) { $code = [int]$proc.ExitCode }
	$elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 2)
	Write-Host "=== RELEASE $Name EXIT=$code duration_sec=$elapsed ==="
	Write-Host "raw_log=$logPath"
	Write-Host "report=$reportPath"
	if (Test-Path $reportPath) {
		Get-Content -Path $reportPath -TotalCount 24 -ErrorAction SilentlyContinue
	} else {
		Write-Host "WARNING: report missing at $reportPath"
		if ($code -eq 0) { $code = 1 }
	}
	return @{ Code = $code; DurationSec = $elapsed }
}

Stop-ProjectReleaseGodot

$smokeCode = 0
$fullCode = 0
$smokeDur = 0
$fullDur = 0

try {
	if ($Mode -eq "smoke" -or $Mode -eq "both") {
		$r = Invoke-ReleaseMode -Name "SMOKE" -ScriptRes "res://tests/release/run_smoke.gd" `
			-LogName "smoke_godot.log" -ReportName "smoke_report.txt" -QuitAfterSec $SmokeQuitAfterSec
		$smokeCode = [int]$r.Code
		$smokeDur = $r.DurationSec
	}
	if ($Mode -eq "full" -or $Mode -eq "both") {
		$r = Invoke-ReleaseMode -Name "FULL" -ScriptRes "res://tests/release/run_full.gd" `
			-LogName "full_godot.log" -ReportName "full_report.txt" -QuitAfterSec $FullQuitAfterSec
		$fullCode = [int]$r.Code
		$fullDur = $r.DurationSec
	}
}
finally {
	Stop-ProjectReleaseGodot
}

Write-Host "=== RELEASE SUMMARY mode=$Mode smoke_exit=$smokeCode smoke_sec=$smokeDur full_exit=$fullCode full_sec=$fullDur ==="
if ($smokeCode -ne 0 -or $fullCode -ne 0) {
	exit 1
}
exit 0
