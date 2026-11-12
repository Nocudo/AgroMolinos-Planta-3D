@echo off
title Simulador 3D Planta Molino de Granos - AgroMolinos del Valle S.A.
chcp 65001 >nul
cls

echo ======================================================================
echo    AGROMOLINOS DEL VALLE S.A. - SIMULADOR 3D DE PLANTA INDUSTRIAL
echo ======================================================================
echo.
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] No se encontró Python en el sistema.
    pause
    exit /b
)

cd /d "%~dp0"
python serve.py

pause
