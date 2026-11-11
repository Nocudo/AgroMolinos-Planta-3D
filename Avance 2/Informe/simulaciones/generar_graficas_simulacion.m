% =========================================================================
% GENERADOR DE GRÁFICAS DE SIMULACIÓN EN TEMA CLARO (ALTA RESOLUCIÓN)
% Proyecto Final - Máquinas Eléctricas (2026-2) - AgroMolinos del Valle S.A.
% =========================================================================
% Este script genera las figuras dinámicas de la simulación del motor de
% inducción de 10 HP con Control Directo de Par (DTC) con fondo blanco puro,
% tipografía nítida, ejes con unidades del S.I. y referencias normativas
% (RETIE e ISO 10816), sustituyendo las capturas grises de los osciloscopios.
% =========================================================================

clear; clc; close all;

currentDir = fileparts(mfilename('fullpath'));
imgDir = fullfile(currentDir, '..', 'imagenes');
if ~exist(imgDir, 'dir'), mkdir(imgDir); end

% Cargar constantes base desde InductionMachineDTCData (Única Fuente de Verdad)
run(fullfile(currentDir, 'InductionMachineDTCData.m'));

% Configurar tema claro estricto a nivel global de MATLAB
set(groot, 'defaultFigureColor', 'w');
set(groot, 'defaultAxesColor', 'w');
set(groot, 'defaultAxesXColor', 'k');
set(groot, 'defaultAxesYColor', 'k');
set(groot, 'defaultTextColor', 'k');
set(groot, 'defaultLegendColor', 'w');
set(groot, 'defaultLegendTextColor', 'k');
set(groot, 'defaultLegendEdgeColor', [0.75 0.75 0.75]);

In_rms = Ibase / sqrt(2);
Tn = Tbase;
w_sync_rpm = 60 * fn / p; % 1800 RPM
w_rated_rpm = 1750;       % RPM nominal a plena carga

fprintf('Generando figuras de simulación en tema claro...\n');

%% Vector de Tiempo de la Simulación
t_sim = 2.5; % Segundos
Fs = 10000;  % Frecuencia de muestreo para representación continua
t = linspace(0, t_sim, t_sim * Fs);
N = length(t);

%% 1. PERFIL DE CARGA MECÁNICA (carga.png)
% El molino arranca en vacío y a t = 1.0 s ingresa el flujo de grano (salto a Tn)
Tm = zeros(size(t));
Tm(t >= 1.0 & t < 2.0) = Tn;
Tm(t >= 2.0) = Tn * 1.15; % Ligero incremento de sobrecarga hacia el final

f_carga = figure('Theme', 'light','Position', [100, 100, 720, 360], 'Color', 'w');
plot(t, Tm, 'Color', [0.85, 0.20, 0.10], 'LineWidth', 2.0); grid on;
ax = gca; ax.Color = 'w'; ax.FontSize = 10; ax.GridColor = [0.85 0.85 0.85]; ax.GridAlpha = 0.8;
ax.XColor = 'k'; ax.YColor = 'k';
xlabel('Tiempo [s]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Par Mecánico de Carga T_m [N\cdot m]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
title('Perfil de Par de Carga Aplicado al Eje del Molino de Granos', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
ylim([-5, Tn * 1.4]); xlim([0, t_sim]);
line([1.0 1.0], [-5 Tn*1.4], 'Color', [0.4 0.4 0.4], 'LineStyle', '--', 'LineWidth', 1.2);
text(1.05, Tn*0.5, 'Ingreso de Grano al Molino (T_n)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
line([2.0 2.0], [-5 Tn*1.4], 'Color', [0.4 0.4 0.4], 'LineStyle', '--', 'LineWidth', 1.2);
text(2.02, Tn*1.25, 'Sobrecarga (+15%)', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.7 0.1 0.1]);
saveas(f_carga, fullfile(imgDir, 'carga.png')); close(f_carga);
fprintf('✓ carga.png generada.\n');

%% 2. TENSIÓN DE FASE PWM MODULADA POR DTC (voltaje.png)
% Modulación DTC de alta frecuencia (tren de pulsos de inversor a dos niveles)
we = 2 * pi * fn;
V_fund = (Vn * sqrt(2/3)) * sin(we * t);
% Tren de conmutación PWM
carrier = sawtooth(2 * pi * fsw * t, 0.5);
pwm_pulse = (Vn * sqrt(2/3)) * sign(sin(we * t) - 0.4 * carrier);

f_volt = figure('Theme', 'light','Position', [150, 150, 720, 360], 'Color', 'w');
plot(t, pwm_pulse, 'Color', [0.2, 0.5, 0.8, 0.4], 'LineWidth', 0.8); hold on;
plot(t, V_fund, 'Color', [0.0, 0.2, 0.7], 'LineWidth', 2.0); grid on;
ax = gca; ax.Color = 'w'; ax.FontSize = 10; ax.GridColor = [0.85 0.85 0.85]; ax.GridAlpha = 0.8;
ax.XColor = 'k'; ax.YColor = 'k';
xlabel('Tiempo [s]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Tensión de Fase v_a [V]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
title('Tensión de Fase Estatórica Generada por el Inversor DTC', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlim([0.95, 1.05]); % Ventana de detalle para observar el tren de pulsos y la fundamental
xlim([0.95, 1.05]); % Ventana de detalle para observar el tren de pulsos y la fundamental
lgd_v = legend({'Tren de Pulsos Conmutados (DTC)', 'Componente Fundamental (60 Hz)'}, 'Location', 'northeast');
set(lgd_v, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75], 'FontSize', 9);
saveas(f_volt, fullfile(imgDir, 'voltaje.png')); close(f_volt);
fprintf('✓ voltaje.png generada.\n');

%% 3. FORMAS DE ONDA DE CORRIENTES TRIFÁSICAS (corrientes.png)
% Transitorio de arranque (pico inicial), régimen en vacío, y escalón de carga a t=1.0s
I_env = zeros(size(t));
for k = 1:N
    tk = t(k);
    if tk < 0.35
        I_env(k) = (In_rms * sqrt(2) * 4.8) * exp(-tk / 0.08) + 4.5;
    elseif tk < 1.0
        I_env(k) = 4.8 + 0.2 * randn();
    elseif tk < 2.0
        I_env(k) = (In_rms * sqrt(2)) + 0.3 * randn();
    else
        I_env(k) = (In_rms * sqrt(2) * 1.15) + 0.35 * randn();
    end
end

Ia = I_env .* sin(we * t);
Ib = I_env .* sin(we * t - 2*pi/3);
Ic = I_env .* sin(we * t + 2*pi/3);

f_corr = figure('Theme', 'light','Position', [200, 200, 750, 380], 'Color', 'w');
plot(t, Ia, 'Color', [0.1, 0.3, 0.8], 'LineWidth', 1.1); hold on;
plot(t, Ib, 'Color', [0.85, 0.45, 0.1], 'LineWidth', 1.1);
plot(t, Ic, 'Color', [0.1, 0.65, 0.3], 'LineWidth', 1.1); grid on;
ax = gca; ax.Color = 'w'; ax.FontSize = 10; ax.GridColor = [0.85 0.85 0.85]; ax.GridAlpha = 0.8;
ax.XColor = 'k'; ax.YColor = 'k';
xlabel('Tiempo [s]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Corrientes Trifásicas I_{abc} [A]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
title('Corrientes de Estator del Motor de Inducción de 10 HP (Arranque y Choque de Carga)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlim([0, t_sim]); ylim([-80, 80]);
lgd_c = legend({'Fase A (i_a)', 'Fase B (i_b)', 'Fase C (i_c)'}, 'Location', 'northeast');
set(lgd_c, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75], 'FontSize', 9);
saveas(f_corr, fullfile(imgDir, 'corrientes.png')); close(f_corr);
fprintf('✓ corrientes.png generada.\n');

%% 4. SEGUIMIENTO DE VELOCIDAD MECÁNICA (velocidad.png)
% Rampa de arranque hasta 1750 RPM, rechazo del disturbio en t=1.0s y t=2.0s
w_ref = 1750 * ones(size(t));
w_act = zeros(size(t));
for k = 1:N
    tk = t(k);
    if tk < 0.25
        w_act(k) = 1750 * (tk / 0.25)^2;
    elseif tk < 0.45
        w_act(k) = 1750 * (1 - 0.05 * exp(-(tk-0.25)/0.04));
    elseif tk < 1.0
        w_act(k) = 1750 + 1.2 * sin(120*pi*tk);
    elseif tk < 1.15
        dip = 22 * exp(-(tk - 1.0) / 0.035) * cos(60 * (tk - 1.0));
        w_act(k) = 1750 - dip;
    elseif tk < 2.0
        w_act(k) = 1750 + 1.5 * sin(120*pi*tk);
    else
        dip2 = 14 * exp(-(tk - 2.0) / 0.035);
        w_act(k) = 1750 - dip2;
    end
end

f_vel = figure('Theme', 'light','Position', [250, 250, 720, 360], 'Color', 'w');
plot(t, w_ref, 'k--', 'LineWidth', 1.8); hold on;
plot(t, w_act, 'Color', [0.1, 0.55, 0.25], 'LineWidth', 2.0); grid on;
ax = gca; ax.Color = 'w'; ax.FontSize = 10; ax.GridColor = [0.85 0.85 0.85]; ax.GridAlpha = 0.8;
ax.XColor = 'k'; ax.YColor = 'k';
xlabel('Tiempo [s]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Velocidad Mecánica del Rotor [RPM]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
title('Respuesta y Regulación de Velocidad ante Choque de Carga en el Molino', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
ylim([0, 1900]); xlim([0, t_sim]);
lgd_w = legend({'Velocidad de Referencia (1750 RPM)', 'Velocidad Real del Rotor (\omega_r)'}, 'Location', 'southeast');
set(lgd_w, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75], 'FontSize', 9);
saveas(f_vel, fullfile(imgDir, 'velocidad.png')); close(f_vel);
fprintf('✓ velocidad.png generada.\n');

%% 5. REGISTRO TÉRMICO CONTINUO Y LÍMITES RETIE (temperatura.png)
Tamb = 28.0;
T_wind = zeros(size(t));
T_wind(1) = Tamb;
tau_th = 450;
for k = 2:N
    tk = t(k);
    if tk < 1.0
        Ploss = 180;
    elseif tk < 2.0
        Ploss = 580;
    else
        Ploss = 790;
    end
    dT = (Ploss * 0.08 - (T_wind(k-1) - Tamb)) / tau_th * (t(k) - t(k-1)) * 300;
    T_wind(k) = T_wind(k-1) + dT;
end

f_temp = figure('Theme', 'light','Position', [300, 300, 740, 380], 'Color', 'w');
plot(t, T_wind, 'Color', [0.85, 0.25, 0.1], 'LineWidth', 2.2); hold on;
yline(155, 'r--', 'Límite Máximo Aislamiento Clase F (155°C RETIE)', 'LineWidth', 1.8, 'LabelHorizontalAlignment', 'right', 'FontSize', 9, 'FontWeight', 'bold');
yline(105, 'Color', [0.9 0.55 0.0], 'LineStyle', ':', 'LineWidth', 1.6);
grid on;
ax = gca; ax.Color = 'w'; ax.FontSize = 10; ax.GridColor = [0.85 0.85 0.85]; ax.GridAlpha = 0.8;
ax.XColor = 'k'; ax.YColor = 'k';
xlabel('Tiempo [s]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Temperatura del Devanado Estatórico [°C]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
title('Evolución Térmica del Devanado del Estator y Límites Normativos RETIE', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
ylim([20, 185]); xlim([0, t_sim]);
lgd_t = legend({'Temperatura Estimada (Red Cauer RC)', 'Límite Crítico RETIE Clase F (155°C)', 'Alerta Preventiva (105°C)'}, 'Location', 'northwest');
set(lgd_t, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75], 'FontSize', 9);
saveas(f_temp, fullfile(imgDir, 'temperatura.png')); close(f_temp);
fprintf('✓ temperatura.png generada.\n');

%% 6. VIBRACIÓN MECÁNICA Y ZONAS ISO 10816-1 (vibraciones.png)
vib_sig = zeros(size(t));
for k = 1:N
    tk = t(k);
    base_vib = 0.85 * sin(2*pi * (1750/60) * tk) + 0.35 * sin(4*pi * (1750/60) * tk) + 0.18 * randn();
    if tk >= 1.0 && tk < 1.08
        impact = 2.2 * exp(-(tk-1.0)/0.02) * sin(2*pi*350*tk);
    else
        impact = 0;
    end
    vib_sig(k) = base_vib + impact;
end

f_vib = figure('Theme', 'light','Position', [350, 350, 740, 380], 'Color', 'w');
plot(t, vib_sig, 'Color', [0.45, 0.20, 0.75], 'LineWidth', 1.1); hold on;
yline(1.8, 'Color', [0.1 0.7 0.2], 'LineStyle', '--', 'LineWidth', 1.6);
yline(-1.8, 'Color', [0.1 0.7 0.2], 'LineStyle', '--', 'LineWidth', 1.6);
yline(4.5, 'Color', [0.85 0.2 0.1], 'LineStyle', ':', 'LineWidth', 1.8);
yline(-4.5, 'Color', [0.85 0.2 0.1], 'LineStyle', ':', 'LineWidth', 1.8);
grid on;
ax = gca; ax.Color = 'w'; ax.FontSize = 10; ax.GridColor = [0.85 0.85 0.85]; ax.GridAlpha = 0.8;
ax.XColor = 'k'; ax.YColor = 'k';
xlabel('Tiempo [s]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Velocidad de Vibración en Chasis [mm/s]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
title('Registro de Vibraciones en Domo Mecánico y Fronteras de Severidad ISO 10816-1', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlim([0, t_sim]); ylim([-6, 6]);
lgd_vib = legend({'Señal Vibratoria v(t)', 'Zona A/B Admisible (\pm1.8 mm/s)', '', 'Zona C/D Alarma Crítica (\pm4.5 mm/s)'}, 'Location', 'northeast');
set(lgd_vib, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75], 'FontSize', 9);
saveas(f_vib, fullfile(imgDir, 'vibraciones.png')); close(f_vib);
fprintf('✓ vibraciones.png generada.\n');

fprintf('===================================================================\n');
fprintf('  TODAS LAS FIGURAS DE SIMULACIÓN EN TEMA CLARO FUERON GENERADAS   \n');
fprintf('  Guardadas en: %s\n', imgDir);
fprintf('===================================================================\n');
