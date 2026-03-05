@echo off
REM Faz 6 - Yerel test calistirma (Godot 4.x gerekli)
set PROJECT_DIR=%~dp0
cd /d "%PROJECT_DIR%"

REM Godot yolunu burada duzenleyin (PATH'te yoksa)
set GODOT=godot
where godot >nul 2>nul || set GODOT=C:\Users\miner\Downloads\Godot_v4.6.1-stable_win64.exe

set GODOT_DISABLE_LEAK_CHECKS=1
echo === Birim testleri ===
"%GODOT%" --headless --path . res://ci/test_runner.tscn --quit-after 5
set UNIT_EXIT=%ERRORLEVEL%
echo.
echo === Entegrasyon testleri ===
"%GODOT%" --headless --path . res://ci/integration_test.tscn --quit-after 5
set INT_EXIT=%ERRORLEVEL%
echo.
echo Unit: %UNIT_EXIT%  Integration: %INT_EXIT%
if %UNIT_EXIT% neq 0 exit /b %UNIT_EXIT%
if %INT_EXIT% neq 0 exit /b %INT_EXIT%
exit /b 0
