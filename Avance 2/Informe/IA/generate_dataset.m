% =========================================================================
% GENERADOR DE DATASET DE TELEMETRÍA Y FALLAS - MOTOR DE INDUCCIÓN 10 HP
% AgroMolinos del Valle S.A. - Curso de Máquinas Eléctricas (2026-2)
% =========================================================================

clear; clc; rng(42);

% Cargar constantes base desde InductionMachineDTCData (Única Fuente de Verdad)
currentDir = fileparts(mfilename('fullpath'));
simPath = fullfile(currentDir, '..', 'simulaciones');
addpath(simPath);
InductionMachineDTCData;

% Magnitudes base y nominales derivadas del archivo maestro
In_rms = Ibase / sqrt(2); % Corriente eficaz nominal de estator (~9.36 - 10.5 A)
Tn = Tbase;               % Par nominal mecánico (~39.58 N*m)
R_stator = Rss;           % Resistencia óhmica real del estator [ohm]

fprintf('Parámetros maestros cargados de InductionMachineDTCData:\n');
fprintf('  Pn = %.0f W | Vn = %.0f V | fn = %.0f Hz | p = %d\n', Pn, Vn, fn, p);
fprintf('  Tbase = %.2f N*m | Ibase_peak = %.2f A | In_rms = %.2f A\n\n', Tbase, Ibase, In_rms);

nSamplesPerClass = 300;
totalSamples = nSamplesPerClass * 4;

% Matriz de características (8 columnas) y etiquetas
X = zeros(totalSamples, 8);
Y = zeros(totalSamples, 1);

%% CLASE 1: OPERACIÓN NORMAL (Carga entre 20% y 100% de Tn)
for i = 1:nSamplesPerClass
    loadFactor = 0.20 + 0.80 * rand();
    Irms = (0.35 * In_rms + 0.65 * In_rms * loadFactor) + 0.25 * randn();
    IUF  = 0.50 + 1.20 * rand() + 0.15 * abs(randn());
    THD  = 2.00 + 2.00 * rand() + 0.25 * randn();
    Vrms = Vn + 3.50 * randn();
    Temp = 40.0 + 32.0 * loadFactor + 2.0 * randn();
    dTemp_dt = 0.05 * randn();
    Vrms_vib = 0.70 + 0.75 * loadFactor + 0.12 * randn();
    Vpeak_vib = Vrms_vib * (1.35 + 0.15 * rand());
    
    X(i, :) = [Irms, IUF, THD, Vrms, Temp, dTemp_dt, Vrms_vib, Vpeak_vib];
    Y(i) = 1;
end

%% CLASE 2: SOBRECALENTAMIENTO (Sobrecarga sostenida o falla en ventilación)
for i = 1:nSamplesPerClass
    idx = nSamplesPerClass + i;
    overloadFactor = 1.15 + 0.45 * rand();
    Irms = In_rms * overloadFactor + 0.40 * randn();
    IUF  = 1.00 + 1.50 * rand() + 0.20 * randn();
    THD  = 3.50 + 1.80 * rand() + 0.35 * randn();
    Vrms = (Vn - 3) + 4.50 * randn();
    Temp = 98.0 + 52.0 * (overloadFactor - 1.15)/0.45 + 3.0 * randn();
    dTemp_dt = 1.20 + 2.30 * rand() + 0.25 * abs(randn());
    Vrms_vib = 1.40 + 0.80 * rand() + 0.15 * randn();
    Vpeak_vib = Vrms_vib * (1.40 + 0.20 * rand());
    
    X(idx, :) = [Irms, IUF, THD, Vrms, Temp, dTemp_dt, Vrms_vib, Vpeak_vib];
    Y(idx) = 2;
end

%% CLASE 3: FALLA ELÉCTRICA (Desbalance de fases / cortocircuito entre espiras)
for i = 1:nSamplesPerClass
    idx = 2 * nSamplesPerClass + i;
    sev = 0.20 + 0.80 * rand();
    Irms = (In_rms * (0.85 + 0.55 * sev)) + 0.50 * randn();
    IUF  = 8.00 + 34.0 * sev + 1.20 * randn();
    THD  = 6.00 + 11.0 * sev + 0.80 * randn();
    Vrms = (Vn - 15 * sev) + 5.00 * randn();
    Temp = 65.0 + 35.0 * sev + 2.5 * randn();
    dTemp_dt = 0.40 + 1.00 * sev + 0.15 * randn();
    Vrms_vib = 2.00 + 2.00 * sev + 0.25 * randn();
    Vpeak_vib = Vrms_vib * (1.60 + 0.30 * rand());
    
    X(idx, :) = [Irms, IUF, THD, Vrms, Temp, dTemp_dt, Vrms_vib, Vpeak_vib];
    Y(idx) = 3;
end

%% CLASE 4: FALLA MECÁNICA (Desalineación / desgaste de rodamientos)
for i = 1:nSamplesPerClass
    idx = 3 * nSamplesPerClass + i;
    msev = 0.20 + 0.80 * rand();
    Irms = In_rms * (0.90 + 0.30 * msev) + 0.35 * randn();
    IUF  = 1.50 + 2.50 * msev + 0.25 * randn();
    THD  = 3.00 + 3.50 * rand() + 0.35 * randn();
    Vrms = Vn + 3.00 * randn();
    Temp = 55.0 + 26.0 * msev + 2.0 * randn();
    dTemp_dt = 0.20 + 0.45 * msev + 0.10 * randn();
    Vrms_vib = 4.20 + 8.50 * msev + 0.35 * randn();
    Vpeak_vib = Vrms_vib * (2.10 + 1.10 * rand());
    
    X(idx, :) = [Irms, IUF, THD, Vrms, Temp, dTemp_dt, Vrms_vib, Vpeak_vib];
    Y(idx) = 4;
end

% Acotar magnitudes físicas no negativas
X(:, [1, 2, 3, 4, 5, 7, 8]) = max(X(:, [1, 2, 3, 4, 5, 7, 8]), 0.01);

% Mezclar aleatoriamente
shuff = randperm(totalSamples);
X = X(shuff, :);
Y = Y(shuff);

featureNames = {'Irms_A', 'IUF_pct', 'THD_pct', 'Vrms_V', 'Temp_C', 'dTemp_dt', 'Vrms_vib_mms', 'Vpeak_vib_mms'};
classNames   = {'Normal', 'Sobrecalentamiento', 'Falla_Electrica', 'Falla_Mecanica'};

% Guardar en la carpeta actual (Informe/IA)
save(fullfile(currentDir, 'motor_fault_dataset.mat'), 'X', 'Y', 'featureNames', 'classNames', 'Pn', 'Vn', 'fn', 'In_rms', 'Tn');

T_data = array2table(X, 'VariableNames', featureNames);
T_data.Estado = categorical(Y, 1:4, classNames);
writetable(T_data, fullfile(currentDir, 'motor_fault_dataset.csv'));

fprintf('✓ Dataset generado con %d muestras y sincronizado con InductionMachineDTCData.\n', totalSamples);
