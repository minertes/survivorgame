# Faz 6 - Yerel test calistirma (Godot 4.x gerekli)
$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

# Godot: PATH'te veya asagidaki yolu duzenleyin
$Godot = $null
try { $null = Get-Command godot -ErrorAction Stop; $Godot = "godot" } catch {}
if (-not $Godot) { $Godot = "C:\Users\miner\Downloads\Godot_v4.6.1-stable_win64.exe" }

$env:GODOT_DISABLE_LEAK_CHECKS = "1"

Write-Host "=== Birim testleri ===" -ForegroundColor Cyan
if ($Godot -eq "godot") {
    godot --headless --path . res://ci/test_runner.tscn --quit-after 5
} else {
    & $Godot --headless --path . res://ci/test_runner.tscn --quit-after 5
}
$unitExit = $LASTEXITCODE

Write-Host "`n=== Entegrasyon testleri ===" -ForegroundColor Cyan
if ($Godot -eq "godot") {
    godot --headless --path . res://ci/integration_test.tscn --quit-after 5
} else {
    & $Godot --headless --path . res://ci/integration_test.tscn --quit-after 5
}
$intExit = $LASTEXITCODE

Write-Host "`nUnit exit: $unitExit  Integration exit: $intExit" -ForegroundColor $(if ($unitExit -eq 0 -and $intExit -eq 0) { "Green" } else { "Red" })
if ($unitExit -ne 0) { exit $unitExit }
if ($intExit -ne 0) { exit $intExit }
exit 0
