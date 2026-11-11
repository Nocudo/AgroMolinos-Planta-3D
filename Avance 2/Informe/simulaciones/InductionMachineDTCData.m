% Parámetros para el Control de Velocidad de la Máquina de Inducción

%% Parámetros de la máquina de inducción
Pn  = 7460;     % W,  potencia nominal (10 HP)
Vn  = 460;      % V,  rms fase a fase, voltaje nominal
fn  = 60;       % Hz, frecuencia nominal

Rs  = 0.0139;   % pu, resistencia del estator
Lls = 0.0672;   % pu, inductancia de dispersión del estator
Rr  = 0.0112;   % pu, resistencia del rotor, referida al lado del estator
Llr = 0.0672;   % pu, inductancia de dispersión del rotor, referida al lado del estator
Lm  = 2.717;    % pu, inductancia de magnetización
Lr = Llr+Lm;    % pu, inductancia del rotor
Ls = Lls+Lm;    % pu, inductancia del estator

H = 0.2734;     % s, momento de inercia
F = 0.0106;     % pu, coeficiente de fricción
p = 2;          % pares de polos

Vbase = Vn/sqrt(3)*sqrt(2); % V,     voltaje base, pico, línea a neutro
Ibase = Pn/(1.5*Vbase);     % A,     corriente base, pico
Zbase = Vbase/Ibase;        % ohm,   resistencia base
wbase = 2*pi*fn;            % rad/s, frecuencia radial eléctrica base
Tbase = Pn/(wbase/p);       % N*m,   par base
psin  = (Vn/sqrt(3)*sqrt(2)/wbase);  % Flujo nominal

Rss = Rs*Zbase;  % ohm, resistencia del estator
Xls = Lls*Zbase; % ohm, reactancia de dispersión del estator
Rrr = Rr*Zbase;  % ohm, resistencia del rotor, referida al lado del estator
Xlr = Llr*Zbase; % ohm, reactancia de dispersión del rotor, referida al lado del estator
Xm = Lm*Zbase;   % ohm, reactancia de magnetización

%% Parámetros de control
Ts = 5e-6;        % s,  tiempo de muestreo fundamental
fsw = 2e3;        % Hz, frecuencia de conmutación 
Tsc = Ts;         % s,  tiempo de muestreo de control (IGUAL a Ts para evitar inestabilidad DTC)

% Parámetros del controlador de velocidad PI en POR-UNIDAD
% La planta en p.u. es: T_pu - F*w_pu = 2H * s * w_pu
% F de transferencia: w_pu / T_pu = 1 / (2H*s + F)
zeta = 1.0;          % Amortiguamiento crítico
wn = 20;             % Ancho de banda (rad/s), más rápido que antes para seguir la rampa

Kp_wr = 2 * zeta * wn * (2*H) - F;
Ki_wr = (wn^2) * (2*H);

% Parámetros de las bandas de histéresis del controlador DTC
FluxHystBand = 0.015; % Wb
THystBand = 3;       % N*m
