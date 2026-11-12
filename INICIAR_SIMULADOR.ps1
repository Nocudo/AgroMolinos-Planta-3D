# INICIAR_SIMULADOR.ps1 - Lanzador PowerShell para el Simulador 3D de Planta Industrial
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   AGROMOLINOS DEL VALLE S.A. - SIMULADOR 3D DE PLANTA INDUSTRIAL" -ForegroundColor Yellow
Write-Host "   Proyecto Final de Máquinas Eléctricas (Universidad de los Llanos)" -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] No se encontró Python en el sistema o en el PATH." -ForegroundColor Red
    Write-Host "Por favor instale Python 3 desde python.org o Microsoft Store." -ForegroundColor Yellow
    Read-Host "Presione Enter para salir"
    exit
}

$webDir = Join-Path $PSScriptRoot "SimuladorPlantaWeb"
Set-Location $webDir
python serve.py
