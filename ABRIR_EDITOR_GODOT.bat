@echo off
chcp 65001 >nul
title AgroMolinos - Editor de Godot 4.7

cd /d "%~dp0"

echo ========================================================
echo   ABRIENDO PROYECTO EN EDITOR DE GODOT 4.7
echo   AgroMolinos del Valle S.A. - Planta Molino de Granos
echo ========================================================
echo.

set "GODOT_EXE="
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" (
    set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
) else (
    where godot >nul 2>nul
    if %errorlevel% equ 0 (
        set "GODOT_EXE=godot"
    ) else if exist "%USERPROFILE%\.gemini\antigravity\bin\godot.cmd" (
        set "GODOT_EXE=%USERPROFILE%\.gemini\antigravity\bin\godot.cmd"
    )
)

if not defined GODOT_EXE (
    echo [ERROR] No se encontro Godot 4.7 en el sistema.
    pause
    exit /b 1
)

echo Iniciando Editor de Godot 4.7...
start "" "%GODOT_EXE%" -e --path "%~dp0SimuladorPlantaGodot"
