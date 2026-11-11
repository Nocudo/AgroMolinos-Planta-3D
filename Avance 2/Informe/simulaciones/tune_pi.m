% 1. Cargar las variables base del motor
InductionMachineDTCData;

% 2. Calcular los parámetros físicos reales (SI)
wbase_mech = 2*pi*fn/p; % [rad/s] Velocidad mecánica síncrona
Tbase = Pn/wbase_mech;  % [N*m] Torque base

% Inercia J [kg*m^2] calculada a partir de H [s]
J = (2 * H * Tbase) / wbase_mech;

% Fricción F_si [N*m*s/rad] calculada a partir de F_pu
F_si = F * (Tbase / wbase_mech);

% Ganancia y polo de la planta mecánica G(s) = K / (s + a)
K_planta = Tbase / J;
a_planta = F_si / J;

fprintf('\n=== SINTONIZACIÓN ANALÍTICA DEL PI DE VELOCIDAD ===\n');
fprintf('Inercia (J): %.4f kg*m^2\n', J);
fprintf('Fricción (F): %.4f N*m*s/rad\n', F_si);
fprintf('---------------------------------------------------\n');

% 3. Parámetros de Diseño
% ts = tiempo de estabilización deseado en segundos (qué tan rápido arranca)
% zeta = factor de amortiguamiento (1.0 = sin sobreimpulso)
tiempos_deseados = [0.05, 0.1, 0.2, 0.5]; 
zeta = 1.0; 

for ts = tiempos_deseados
    % Calcular frecuencia natural deseada
    wn = 4 / (zeta * ts);
    
    % Calcular constantes del PI
    Kp_calculado = (2 * zeta * wn - a_planta) / K_planta;
    Ki_calculado = (wn^2) / K_planta;
    
    fprintf('Para un tiempo de respuesta de %.2f segundos:\n', ts);
    fprintf(' -> Kp_wr = %.4f\n', Kp_calculado);
    fprintf(' -> Ki_wr = %.4f\n\n', Ki_calculado);
end