@echo off
setlocal
chcp 65001 >nul 2>&1
title Simulador 3D Planta Molino de Granos
cls

cd /d "%~dp0"

python --version >nul 2>&1
if not errorlevel 1 (
    python serve.py
    goto :fin
)

py --version >nul 2>&1
if not errorlevel 1 (
    py serve.py
    goto :fin
)

echo [ERROR] Python no encontrado en el PATH del sistema.
echo Por favor, instala Python 3 (https://www.python.org/) y agregalo al PATH.
pause
exit /b 1

:fin
pause