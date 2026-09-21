@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where godot >nul 2>nul
if not errorlevel 1 goto run_path

set "GODOT_EXE=%ProgramFiles%\Godot\Godot.exe"
if exist "%GODOT_EXE%" goto run_executable

set "GODOT_EXE="
set "WINGET_GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"
for /f "delims=" %%G in ('dir /b /a-d /o-n "%WINGET_GODOT%\Godot*_win64.exe" 2^>nul') do set "GODOT_EXE=%WINGET_GODOT%\%%G"
if defined GODOT_EXE goto run_executable

echo Godot 4 is required. Open client\project.godot in Godot to play.
exit /b 1

:run_path
godot --path client
exit /b %errorlevel%

:run_executable
"%GODOT_EXE%" --path client
exit /b %errorlevel%
