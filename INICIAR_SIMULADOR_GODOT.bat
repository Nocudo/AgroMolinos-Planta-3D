@echo off
chcp 65001 >nul
title AgroMolinos - Simulador 3D Serious Game (Godot 4.7)

cd /d "%~dp0"

echo ========================================================
echo   INICIANDO SIMULADOR 3D INTERACTIVO EN GODOT 4.7
echo   Planta Molino de Granos - Motor 10 HP (460 V / IE3)
echo ========================================================
echo.

:: Detectar ejecutable GUI de Godot preferentemente
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
    echo [ERROR] No se encontro el ejecutable de Godot 4.7.
    pause
    exit /b 1
)

echo Iniciando juego interactivo con Godot...
start "" "%GODOT_EXE%" --path "%~dp0SimuladorPlantaGodot"
