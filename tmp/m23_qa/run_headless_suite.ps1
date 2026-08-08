# Independent M23 QA headless suite. Raw Godot logs under tmp/m23_qa/*.log
$ErrorActionPreference = "Continue"
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path (Join-Path $root "project.godot"))) {
  $root = "C:\Users\User\Documents\GodotProjects\date_factory"
}
Set-Location $root
$out = Join-Path $root "tmp\m23_qa"
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Invoke-GodotTest {
  param(
    [string]$Name,
    [string]$Scene,
    [int]$QuitAfter = 90000
  )
  $log = Join-Path $out "$Name.log"
  Write-Host "=== RUN $Name ==="
  & $godot --path $root --headless --quit-after $QuitAfter $Scene 2>&1 | Tee-Object -FilePath $log
  $code = $LASTEXITCODE
  "EXIT=$code" | Tee-Object -FilePath $log -Append | Out-Null
  Write-Host "=== DONE $Name EXIT=$code ==="
  return $code
}

$results = @()

$tests = @(
  @{ Name = "audio_director"; Scene = "res://audio/test/audio_director_self_test.tscn"; Quit = 40000 },
  @{ Name = "camera_feedback"; Scene = "res://tmp/m23_d/camera_feedback_self_test.tscn"; Quit = 20000 },
  @{ Name = "slap"; Scene = "res://minigames/slap/test/slap_minigame_test.tscn"; Quit = 40000 },
  @{ Name = "dance"; Scene = "res://minigames/dance/test/dance_minigame_test.tscn"; Quit = 40000 },
  @{ Name = "sigma"; Scene = "res://minigames/sigma/test/sigma_minigame_test.tscn"; Quit = 40000 },
  @{ Name = "money"; Scene = "res://minigames/money/test/money_minigame_test.tscn"; Quit = 40000 },
  @{ Name = "rivals"; Scene = "res://game/rivals/test/rival_encounter_test.tscn"; Quit = 60000 },
  @{ Name = "dating"; Scene = "res://game/dating/test/dating_test.tscn"; Quit = 90000 },
  @{ Name = "girl_discovery"; Scene = "res://game/girls/test/girl_discovery_test.tscn"; Quit = 40000 },
  @{ Name = "clone_viz"; Scene = "res://game/clone_visualization/test/clone_visualization_test.tscn"; Quit = 60000 },
  @{ Name = "media"; Scene = "res://game/media/test/media_test.tscn"; Quit = 60000 },
  @{ Name = "first_clone"; Scene = "res://game/first_clone/test/first_clone_test.tscn"; Quit = 60000 },
  @{ Name = "late_game"; Scene = "res://game/late_game/test/late_game_test.tscn"; Quit = 60000 },
  @{ Name = "final_date"; Scene = "res://game/final_date/test/final_date_test.tscn"; Quit = 90000 },
  @{ Name = "content"; Scene = "res://world/test/content_data_test.tscn"; Quit = 40000 },
  @{ Name = "progression_ui"; Scene = "res://ui/progression/test/progression_ui_self_test.tscn"; Quit = 60000 },
  @{ Name = "game_hud_smoke"; Scene = "res://ui/hud/test/game_hud_smoke_test.tscn"; Quit = 40000 },
  @{ Name = "main_boot"; Scene = "res://main.tscn"; Quit = 3 }
)

foreach ($t in $tests) {
  $code = Invoke-GodotTest -Name $t.Name -Scene $t.Scene -QuitAfter $t.Quit
  $results += [pscustomobject]@{ Name = $t.Name; Exit = $code }
}

# Independent harness (headless first for audio asserts; shots may be blank in headless)
$code = Invoke-GodotTest -Name "m23_indep_qa_headless" -Scene "res://tmp/m23_qa/m23_indep_qa.tscn" -QuitAfter 120000
$results += [pscustomobject]@{ Name = "m23_indep_qa_headless"; Exit = $code }

$summary = Join-Path $out "suite_summary.txt"
$results | ForEach-Object { "$($_.Name)=EXIT:$($_.Exit)" } | Set-Content -Path $summary
Write-Host "=== SUMMARY ==="
Get-Content $summary
