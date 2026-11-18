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

:: Detectar ejecutable GUI de Godot 4.x (prioridad 0: motor portable incluido en USB/carpeta)
set "GODOT_EXE="
if exist "%~dp0godot_portable" (
    for /f "delims=" %%f in ('dir /b /s "%~dp0godot_portable\Godot_v4.*win64.exe" 2^>nul ^| findstr /v /i "_console"') do (
        if not defined GODOT_EXE set "GODOT_EXE=%%f"
    )
)
if not defined GODOT_EXE (
    for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine*") do (
        if not defined GODOT_EXE (
            for /f "delims=" %%f in ('dir /b /s "%%d\Godot_v4.*win64.exe" 2^>nul ^| findstr /v /i "_console"') do (
                if not defined GODOT_EXE set "GODOT_EXE=%%f"
            )
        )
    )
)
if not defined GODOT_EXE (
    for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine*") do (
        if not defined GODOT_EXE (
            for /f "delims=" %%f in ('dir /b /s "%%d\Godot_v4.*win64_console.exe" 2^>nul') do (
                if not defined GODOT_EXE set "GODOT_EXE=%%f"
            )
        )
    )
)
if not defined GODOT_EXE (
    if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" (
        set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe"
    )
)
if not defined GODOT_EXE (
    for /d %%d in ("%ProgramFiles%\Godot*" "%LOCALAPPDATA%\Programs\Godot*") do (
        if not defined GODOT_EXE (
            for /f "delims=" %%f in ('dir /b /s "%%d\Godot*.exe" 2^>nul ^| findstr /v /i "_console"') do (
                if not defined GODOT_EXE set "GODOT_EXE=%%f"
            )
        )
    )
)
if not defined GODOT_EXE (
    for /f "delims=" %%g in ('where godot 2^>nul') do (
        if not defined GODOT_EXE set "GODOT_EXE=%%g"
    )
)
if not defined GODOT_EXE (
    if exist "%USERPROFILE%\.gemini\antigravity\bin\godot.cmd" (
        set "GODOT_EXE=%USERPROFILE%\.gemini\antigravity\bin\godot.cmd"
    )
)

if not defined GODOT_EXE (
    echo [ERROR] No se encontro el ejecutable de Godot 4.7.
    echo         Ejecuta primero INSTALAR_DEPENDENCIAS.bat para instalarlo automaticamente.
    pause
    exit /b 1
)

echo Motor detectado: "%GODOT_EXE%"
if not exist "%~dp0SimuladorPlantaGodot\.godot\imported" (
    echo Primera ejecucion detectada: importando recursos 3D una sola vez...
    "%GODOT_EXE%" --headless --import --path "%~dp0SimuladorPlantaGodot"
)
echo Iniciando juego interactivo con Godot 4.7...
if /i "%GODOT_EXE:~-4%"==".cmd" (
    start "" cmd /c ""%GODOT_EXE%" --path "%~dp0SimuladorPlantaGodot""
) else if /i "%GODOT_EXE:~-4%"==".bat" (
    start "" cmd /c ""%GODOT_EXE%" --path "%~dp0SimuladorPlantaGodot""
) else (
    start "" "%GODOT_EXE%" --path "%~dp0SimuladorPlantaGodot"
)
