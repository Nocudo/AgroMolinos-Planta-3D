@echo off
chcp 65001 >nul
title AgroMolinos - Simulador 3D Serious Game (Godot 4.7 Vulkan 1.3)

cd /d "%~dp0"

echo ========================================================
echo   INICIANDO SIMULADOR 3D INTERACTIVO EN GODOT 4.7
echo   Planta Molino de Granos - Motor 10 HP (460 V / IE3)
echo   API Grafica: Vulkan 1.3 Forward+
echo ========================================================
echo.

:: Detectar ejecutable GUI de Godot 4.x preferentemente
set "GODOT_EXE="
for /f "delims=" %%f in ('dir /b /s "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*\Godot_v4.*win64.exe" 2^>nul ^| findstr /v /i "_console"') do (
    set "GODOT_EXE=%%f"
)
if not defined GODOT_EXE (
    where godot >nul 2>nul
    if %errorlevel% equ 0 (
        set "GODOT_EXE=godot"
    ) else if exist "%USERPROFILE%\.gemini\antigravity\bin\godot.cmd" (
        set "GODOT_EXE=%USERPROFILE%\.gemini\antigravity\bin\godot.cmd"
    )
)

if not defined GODOT_EXE (
    echo [ERROR] No se encontro el ejecutable de Godot 4.7.
    echo         Ejecuta primero INSTALAR_DEPENDENCIAS.bat para instalarlo automaticamente.
    pause
    exit /b 1
)

echo Iniciando juego interactivo con Godot 4.7...
start "" "%GODOT_EXE%" --path "%~dp0SimuladorPlantaGodot"
