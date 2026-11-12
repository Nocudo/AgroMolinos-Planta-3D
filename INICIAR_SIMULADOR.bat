@echo off
title Simulador 3D Planta Molino de Granos - AgroMolinos del Valle S.A.
chcp 65001 >nul
cls

echo ======================================================================
echo    AGROMOLINOS DEL VALLE S.A. - SIMULADOR 3D DE PLANTA INDUSTRIAL
echo    Proyecto Final de Máquinas Eléctricas (Universidad de los Llanos)
echo ======================================================================
echo.
echo [1/2] Verificando instalación de Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] No se encontró Python instalado o en el PATH del sistema.
    echo Por favor, instala Python 3 (https://www.python.org/) y asegúrate
    echo de marcar la casilla "Add Python to PATH" durante la instalación.
    echo.
    pause
    exit /b
)

echo [2/2] Iniciando servidor multihilo y abriendo navegador web...
echo.
cd /d "%~dp0SimuladorPlantaWeb"
python serve.py

pause
