% =========================================================================
% SCRIPT DE LANZAMIENTO - PANEL INTERACTIVO DE DIAGNÓSTICO (IA)
% Motor de Inducción Jaula de Ardilla 10 HP - AgroMolinos del Valle S.A.
% Proyecto Final de Máquinas Eléctricas (2026-2) - Avance 2
% =========================================================================
% Para ejecutar en MATLAB:
% >> abrir_panel
% =========================================================================

clc;
fprintf('===================================================================\n');
fprintf('  INICIALIZANDO PANEL INTERACTIVO DE DIAGNÓSTICO PREDICTIVO (IA)  \n');
fprintf('  AgroMolinos del Valle S.A. - Motor 10 HP / 460 V (Avance 2)      \n');
fprintf('===================================================================\n\n');

rootDir = fileparts(mfilename('fullpath'));
simDir  = fullfile(rootDir, 'Informe', 'simulaciones');
iaDir   = fullfile(rootDir, 'Informe', 'IA');
imgDir  = fullfile(rootDir, 'Informe', 'imagenes');

addpath(simDir);
addpath(iaDir);

% 1. Verificar y cargar archivo maestro de constantes
if isfile(fullfile(simDir, 'InductionMachineDTCData.m'))
    fprintf('[1/3] Sincronizando constantes base desde InductionMachineDTCData.m...\n');
    run(fullfile(simDir, 'InductionMachineDTCData.m'));
else
    warning('No se encontró InductionMachineDTCData.m en %s', simDir);
end

% 2. Verificar modelo de IA entrenado
modeloFile = fullfile(iaDir, 'modelo_ia_entrenado.mat');
if ~isfile(modeloFile)
    fprintf('[2/3] Modelo de IA no encontrado. Entrenando red neuronal...\n');
    run(fullfile(iaDir, 'train_classifiers.m'));
else
    fprintf('[2/3] Modelo de IA verificado correctamente (%s).\n', modeloFile);
end

% 3. Abrir Panel Interactivo de App Designer
fprintf('[3/3] Abriendo panel de control interactivo...\n\n');
app = MotorFaultDiagnosticGUI();

fprintf('✓ Panel de control en ejecución. Seleccione un escenario o ajuste\n');
fprintf('  los deslizadores para observar la predicción de IA y la ruta\n');
fprintf('  de mantenimiento despachada en tiempo real.\n');
fprintf('===================================================================\n');
