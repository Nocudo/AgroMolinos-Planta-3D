@echo off
setlocal
chcp 65001 >nul 2>&1
title Simulador 3D Planta Molino de Granos - AgroMolinos del Valle S.A.
cls

echo ======================================================================
echo    AGROMOLINOS DEL VALLE S.A. - SIMULADOR 3D DE PLANTA INDUSTRIAL
echo    Proyecto Final de Maquinas Electricas - Universidad de los Llanos
echo ======================================================================
echo.
echo [1/2] Verificando instalacion de Python...

python --version >nul 2>&1
if not errorlevel 1 (
    set "PY_CMD=python"
    goto :python_found
)

py --version >nul 2>&1
if not errorlevel 1 (
    set "PY_CMD=py"
    goto :python_found
)

echo.
echo [ERROR] No se encontro Python en el PATH del sistema.
echo Por favor, instala Python 3 (https://www.python.org/) y asegurate
echo de marcar la casilla "Add Python to PATH" durante la instalacion.
echo.
pause
exit /b 1

:python_found
echo [OK] Python detectado correctamente (%PY_CMD%).
echo.
echo [2/2] Iniciando servidor multihilo y abriendo navegador web...
echo.

cd /d "%~dp0SimuladorPlantaWeb"
%PY_CMD% serve.py

if errorlevel 1 (
    echo.
    echo [AVISO] El servidor se ha detenido con error.
    pause
)