@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title AgroMolinos - Instalador de Dependencias y Entorno

cd /d "%~dp0"

echo ============================================================================
echo   AGROMOLINOS DEL VALLE S.A. - INSTALADOR AUTOMATICO DE DEPENDENCIAS
echo   Simulador 3D Serious Game (Godot 4.7 Vulkan 1.3 + Python Tooling)
echo ============================================================================
echo.

set "HAS_WINGET=0"
where winget >nul 2>nul
if %errorlevel% equ 0 set "HAS_WINGET=1"

:: ----------------------------------------------------------------------------
:: 1. Verificar / Instalar Git
:: ----------------------------------------------------------------------------
echo [1/5] Verificando Git...
where git >nul 2>nul
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('git --version') do echo       [OK] %%v
) else (
    if "!HAS_WINGET!"=="1" (
        echo       Instalando Git via WinGet...
        winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
    ) else (
        echo       [AVISO] Git no detectado y WinGet no esta disponible. Instalalo desde https://git-scm.com/
    )
)
echo.

:: ----------------------------------------------------------------------------
:: 2. Verificar / Instalar Godot Engine 4.7+
:: ----------------------------------------------------------------------------
echo [2/5] Verificando Godot Engine 4.7...
set "GODOT_EXE="
call :FIND_GODOT
if defined GODOT_EXE (
    echo       [OK] Godot detectado en: !GODOT_EXE!
) else (
    if "!HAS_WINGET!"=="1" (
        echo       Instalando Godot Engine via WinGet...
        winget install --id GodotEngine.GodotEngine -e --source winget --accept-source-agreements --accept-package-agreements
        call :FIND_GODOT
        if defined GODOT_EXE (
            echo       [OK] Godot instalado correctamente: !GODOT_EXE!
        ) else (
            echo       [AVISO] Godot se instalo; reinicia esta terminal si no aparece en PATH.
        )
    ) else (
        echo       [ERROR] Godot 4.7 no encontrado y WinGet no esta disponible.
        echo               Descargalo desde: https://godotengine.org/download/windows/
    )
)
echo.

:: ----------------------------------------------------------------------------
:: 3. Verificar / Instalar Python 3.12
:: ----------------------------------------------------------------------------
echo [3/5] Verificando Python 3...
set "PYTHON_CMD="
call :FIND_PYTHON
if not defined PYTHON_CMD (
    if "!HAS_WINGET!"=="1" (
        echo       Instalando Python 3.12 via WinGet...
        winget install --id Python.Python.3.12 -e --source winget --accept-source-agreements --accept-package-agreements
        call :FIND_PYTHON
    )
)

if defined PYTHON_CMD (
    for /f "tokens=*" %%p in ('!PYTHON_CMD! --version 2^>^&1') do echo       [OK] %%p
) else (
    echo       [ERROR] No se encontro Python 3. Instalalo desde https://www.python.org/downloads/
    echo               Asegurate de marcar "Add python.exe to PATH" y vuelve a ejecutar este archivo.
    pause
    exit /b 1
)
echo.

:: ----------------------------------------------------------------------------
:: 4. Instalar paquetes de requirements.txt
:: ----------------------------------------------------------------------------
echo [4/5] Instalando paquetes de requirements.txt...
if not exist "%~dp0requirements.txt" (
    echo       [ERROR] No se encontro requirements.txt en "%~dp0".
    pause
    exit /b 1
)

!PYTHON_CMD! -m pip install --upgrade pip
if %errorlevel% neq 0 (
    echo       [AVISO] No se pudo actualizar pip, continuando con la version actual...
)

!PYTHON_CMD! -m pip install -r "%~dp0requirements.txt"
if %errorlevel% neq 0 (
    echo       [ERROR] Ocurrio un problema instalando los paquetes de requirements.txt.
    pause
    exit /b 1
)
echo       [OK] Paquetes de requirements.txt instalados correctamente.
echo.

:: ----------------------------------------------------------------------------
:: 5. Pre-importar recursos de Godot (cache Vulkan / Basis Universal)
:: ----------------------------------------------------------------------------
echo [5/5] Pre-importando modelos y texturas de baja resolucion en Godot...
if defined GODOT_EXE (
    call "!GODOT_EXE!" --headless --import --path "%~dp0SimuladorPlantaGodot" >nul 2>&1
    echo       [OK] Cache de recursos de SimuladorPlantaGodot preparado.
) else (
    echo       [AVISO] Se omitio la pre-importacion porque Godot no estuvo disponible en esta sesion.
)

echo.
echo ============================================================================
echo   INSTALACION COMPLETADA CON EXITO
echo   - Para jugar:        doble clic en INICIAR_SIMULADOR_GODOT.bat
echo   - Para editar en 3D: doble clic en ABRIR_EDITOR_GODOT.bat
echo ============================================================================
echo.
pause
exit /b 0

:: ----------------------------------------------------------------------------
:: Subrutinas de deteccion
:: ----------------------------------------------------------------------------
:FIND_GODOT
for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine*") do (
    for /f "delims=" %%f in ('dir /b /s "%%d\Godot_v4.*win64.exe" 2^>nul ^| findstr /v /i "_console"') do (
        set "GODOT_EXE=%%f"
        goto :eof
    )
)
for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine*") do (
    for /f "delims=" %%f in ('dir /b /s "%%d\Godot_v4.*win64_console.exe" 2^>nul') do (
        set "GODOT_EXE=%%f"
        goto :eof
    )
)
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" (
    set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe"
    goto :eof
)
for /f "delims=" %%g in ('where godot 2^>nul') do (
    set "GODOT_EXE=%%g"
    goto :eof
)
if exist "%USERPROFILE%\.gemini\antigravity\bin\godot.cmd" (
    set "GODOT_EXE=%USERPROFILE%\.gemini\antigravity\bin\godot.cmd"
    goto :eof
)
goto :eof

:FIND_PYTHON
where python >nul 2>nul
if %errorlevel% equ 0 (
    python --version >nul 2>nul
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=python"
        goto :eof
    )
)
where py >nul 2>nul
if %errorlevel% equ 0 (
    py -3 --version >nul 2>nul
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=py -3"
        goto :eof
    )
)
for /d %%d in ("%LOCALAPPDATA%\Programs\Python\Python3*") do (
    if exist "%%d\python.exe" (
        set "PYTHON_CMD=%%d\python.exe"
        goto :eof
    )
)
goto :eof
