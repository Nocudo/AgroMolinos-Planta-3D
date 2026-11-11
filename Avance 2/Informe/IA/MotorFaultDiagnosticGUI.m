function app = MotorFaultDiagnosticGUI(options)
    % =========================================================================
    % PANEL DE CONTROL Y DIAGNÓSTICO PREDICTIVO DE FALLAS CON IA
    % Motor de Inducción Jaula de Ardilla 10 HP - AgroMolinos del Valle S.A.
    % Proyecto Final - Máquinas Eléctricas (2026-2) - Avance 2
    % =========================================================================

    arguments
        options.AutoSaveSnapshot (1,1) logical = false
        options.SnapshotPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), '..', 'imagenes', 'interfaz_app_designer.png')
    end

    currentDir = fileparts(mfilename('fullpath'));

    % Cargar constantes del archivo maestro InductionMachineDTCData (Única Fuente de Verdad)
    simPath = fullfile(currentDir, '..', 'simulaciones');
    motorParams = loadMotorConstants(fullfile(simPath, 'InductionMachineDTCData.m'));
    Pn = motorParams.Pn;
    Vn = motorParams.Vn;
    Ibase = motorParams.Ibase;
    In_rms = Ibase / sqrt(2); % Corriente nominal eficaz

    % Cargar modelo de IA entrenado
    modelFile = fullfile(currentDir, 'modelo_ia_entrenado.mat');
    if ~isfile(modelFile)
        run(fullfile(currentDir, 'train_classifiers.m'));
    end
    dataLoaded = load(modelFile);
    model = dataLoaded.model_ann;

    % Ventana Principal en Tema Claro
    fig = uifigure('Theme', 'light', ...
                   'Name', sprintf('AgroMolinos del Valle S.A. - Monitoreo Predictivo Motor %0.0f HP / %0.0f V (IA)', Pn/746, Vn), ...
                   'Position', [80, 60, 1150, 750], 'Color', [0.95, 0.96, 0.98]);

    mainGrid = uigridlayout(fig, [2, 1]);
    mainGrid.RowHeight = {55, '1x'};
    mainGrid.Padding = [15, 12, 15, 12];
    mainGrid.RowSpacing = 10;

    %% HEADER SUPERIOR DE LA INTERFAZ
    pnlHeader = uipanel(mainGrid, 'BackgroundColor', [0.08, 0.20, 0.38], ...
                        'BorderType', 'none', 'AutoResizeChildren', 'off');
    lblHeaderMain = uilabel(pnlHeader, 'Text', 'AGROMOLINOS DEL VALLE S.A.  —  MONITOREO Y DIAGNÓSTICO PREDICTIVO DE FALLAS CON IA', ...
                            'FontSize', 14, 'FontWeight', 'bold', 'FontColor', [1 1 1], ...
                            'Position', [20, 26, 1080, 22]);
    lblHeaderSub = uilabel(pnlHeader, 'Text', sprintf('Motor de Inducción Jaula de Ardilla %0.0f HP / %0.0f V  |  Supervisión en Tiempo Real según Normativas RETIE e ISO 10816-1', Pn/746, Vn), ...
                           'FontSize', 10.5, 'FontColor', [0.82, 0.90, 1.0], ...
                           'Position', [20, 6, 1080, 18]);
    pnlHeader.SizeChangedFcn = @(src, evt) resizeHeader(src);

    bodyGrid = uigridlayout(mainGrid, [1, 2]);
    bodyGrid.ColumnWidth = {'1.1x', '1.3x'};
    bodyGrid.Padding = [0, 0, 0, 0];
    bodyGrid.ColumnSpacing = 15;

    %% PANEL IZQUIERDO: TELEMETRÍA Y CONTROLES
    leftPanel = uipanel(bodyGrid, 'Title', 'TELEMETRÍA MULTISENSOR Y CONTROL DE OPERACIÓN', ...
                        'FontSize', 12, 'FontWeight', 'bold', ...
                        'BackgroundColor', 'white', 'ForegroundColor', [0.08, 0.20, 0.38]);
    leftGrid = uigridlayout(leftPanel, [12, 2]);
    leftGrid.RowHeight = {35, 30, 38, 38, 38, 38, 38, 38, 38, 38, 38, '1x'};
    leftGrid.ColumnWidth = {'1x', '1.4x'};
    leftGrid.Padding = [10, 8, 10, 8];
    leftGrid.RowSpacing = 4;

    lblScen = uilabel(leftGrid, 'Text', 'Inyección Rápida de Escenarios:', 'FontWeight', 'bold', 'FontSize', 11, 'FontColor', [0.15 0.15 0.15]);
    lblScen.Layout.Row = 1; lblScen.Layout.Column = [1, 2];

    btnGrid = uigridlayout(leftGrid, [1, 4]);
    btnGrid.Layout.Row = 2; btnGrid.Layout.Column = [1, 2];
    btnGrid.Padding = [0, 0, 0, 0]; btnGrid.ColumnSpacing = 6;

    uibutton(btnGrid, 'Text', 'Normal', 'BackgroundColor', [0.85, 0.95, 0.85], ...
             'FontWeight', 'bold', 'FontColor', [0.1 0.4 0.1], 'ButtonPushedFcn', @(btn, event) setScenario('Normal'));
    uibutton(btnGrid, 'Text', 'Sobrecarga', 'BackgroundColor', [1.0, 0.92, 0.80], ...
             'FontWeight', 'bold', 'FontColor', [0.6 0.3 0.0], 'ButtonPushedFcn', @(btn, event) setScenario('Sobrecalentamiento'));
    uibutton(btnGrid, 'Text', 'F. Eléctrica', 'BackgroundColor', [1.0, 0.85, 0.85], ...
             'FontWeight', 'bold', 'FontColor', [0.6 0.1 0.1], 'ButtonPushedFcn', @(btn, event) setScenario('Falla_Electrica'));
    uibutton(btnGrid, 'Text', 'F. Mecánica', 'BackgroundColor', [0.92, 0.88, 0.98], ...
             'FontWeight', 'bold', 'FontColor', [0.4 0.1 0.6], 'ButtonPushedFcn', @(btn, event) setScenario('Falla_Mecanica'));

    uilabel(leftGrid, 'Text', 'Corriente Irms [A]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldIrms = uislider(leftGrid, 'Limits', [0, In_rms*2.5], 'Value', In_rms*0.85, ...
                       'ValueChangedFcn', @(sld, event) updateDiagnosis());
    
    uilabel(leftGrid, 'Text', 'Desbalance IUF [%]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldIUF = uislider(leftGrid, 'Limits', [0, 50], 'Value', 1.1, ...
                      'ValueChangedFcn', @(sld, event) updateDiagnosis());

    uilabel(leftGrid, 'Text', 'THD Corriente [%]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldTHD = uislider(leftGrid, 'Limits', [0, 25], 'Value', 3.2, ...
                      'ValueChangedFcn', @(sld, event) updateDiagnosis());

    uilabel(leftGrid, 'Text', 'Tensión Vrms [V]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldVrms = uislider(leftGrid, 'Limits', [Vn*0.75, Vn*1.15], 'Value', Vn, ...
                       'ValueChangedFcn', @(sld, event) updateDiagnosis());

    uilabel(leftGrid, 'Text', 'Temperatura [°C]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldTemp = uislider(leftGrid, 'Limits', [20, 180], 'Value', 58, ...
                       'ValueChangedFcn', @(sld, event) updateDiagnosis());

    uilabel(leftGrid, 'Text', 'Tasa dT/dt [°C/min]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldGrad = uislider(leftGrid, 'Limits', [-1.0, 5.0], 'Value', 0.0, ...
                       'ValueChangedFcn', @(sld, event) updateDiagnosis());

    uilabel(leftGrid, 'Text', 'Vibración Vrms [mm/s]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldVibRMS = uislider(leftGrid, 'Limits', [0, 20], 'Value', 1.1, ...
                         'ValueChangedFcn', @(sld, event) updateDiagnosis());

    uilabel(leftGrid, 'Text', 'Vibración Pico [mm/s]:', 'FontWeight', 'bold', 'FontColor', 'k');
    sldVibPeak = uislider(leftGrid, 'Limits', [0, 35], 'Value', 1.6, ...
                          'ValueChangedFcn', @(sld, event) updateDiagnosis());

    btnSnap = uibutton(leftGrid, 'Text', 'Capturar Estado para Informe Técnico', ...
                       'BackgroundColor', [0.15, 0.35, 0.65], 'FontColor', 'white', ...
                       'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, event) saveSnapshot());
    btnSnap.Layout.Row = 11; btnSnap.Layout.Column = [1, 2];

    %% PANEL DERECHO: DIAGNÓSTICO DE IA Y RUTA DE MANTENIMIENTO
    rightPanel = uipanel(bodyGrid, 'Title', 'DIAGNÓSTICO PREDICTIVO Y DISPATCHER DE MANTENIMIENTO', ...
                         'FontSize', 12, 'FontWeight', 'bold', ...
                         'BackgroundColor', 'white', 'ForegroundColor', [0.08, 0.20, 0.38]);
    rightGrid = uigridlayout(rightPanel, [4, 1]);
    rightGrid.RowHeight = {65, 155, '1x', 25};
    rightGrid.Padding = [12, 10, 12, 10]; rightGrid.RowSpacing = 8;

    % Banner de Estado con fondo sólido dinámico sin máscara de grid
    pnlBanner = uipanel(rightGrid, 'BackgroundColor', [0.15, 0.70, 0.25], ...
                        'BorderType', 'line', 'HighlightColor', [0.10, 0.50, 0.20], ...
                        'AutoResizeChildren', 'off');
    lblStatusTitle = uilabel(pnlBanner, 'Text', 'ESTADO DE OPERACIÓN: NORMAL (CONFORME)', ...
                             'FontSize', 13.5, 'FontWeight', 'bold', 'FontColor', 'white', ...
                             'HorizontalAlignment', 'center', 'Position', [10, 34, 570, 24]);
    lblConfidence = uilabel(pnlBanner, 'Text', 'Certeza IA: 99.8%  |  Condición Operativa Conforme (Sin Advertencias)', ...
                            'FontSize', 10.5, 'FontColor', 'white', ...
                            'HorizontalAlignment', 'center', 'Position', [10, 8, 570, 20]);
    pnlBanner.SizeChangedFcn = @(src, evt) resizeBanner(src);

    axProbs = uiaxes(rightGrid);
    axProbs.BackgroundColor = 'white';
    axProbs.XColor = 'k'; axProbs.YColor = 'k';
    title(axProbs, 'Distribución de Probabilidades por Estado Operativo', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    ylabel(axProbs, 'Probabilidad [%]', 'FontSize', 9, 'Color', 'k');
    axProbs.YLim = [0, 105]; axProbs.XGrid = 'on'; axProbs.YGrid = 'on';
    axProbs.GridColor = [0.85 0.85 0.85]; axProbs.GridAlpha = 0.8;

    pnlMaint = uipanel(rightGrid, 'Title', 'Ruta de Mantenimiento Despachada (Preventivo / Predictivo)', ...
                       'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.98, 0.98, 0.99], 'ForegroundColor', [0.08, 0.20, 0.38]);
    gridMaint = uigridlayout(pnlMaint, [1, 1]);
    gridMaint.Padding = [8, 8, 8, 8];
    txtMaint = uitextarea(gridMaint, 'Editable', 'off', 'FontSize', 9.5, ...
                          'FontName', 'Consolas', 'BackgroundColor', 'white', 'FontColor', [0.1 0.1 0.1]);

    lblFooter = uilabel(rightGrid, 'Text', sprintf('Motor: %0.0f HP | %0.0f V | In = %0.1f A | Aislamiento RETIE Clase F (155°C) | Vibración ISO 10816-1 Zona A', Pn/746, Vn, In_rms), ...
                        'FontSize', 8.5, 'FontColor', [0.35, 0.35, 0.45], 'HorizontalAlignment', 'center');

    %% FUNCIONES DE REDIMENSIONAMIENTO RESPONSIVO
    function resizeHeader(src)
        w = src.Position(3);
        lblHeaderMain.Position = [20, 26, max(10, w - 40), 22];
        lblHeaderSub.Position  = [20, 6,  max(10, w - 40), 18];
    end

    function resizeBanner(src)
        w = src.Position(3);
        lblStatusTitle.Position = [10, 34, max(10, w - 20), 24];
        lblConfidence.Position  = [10, 8,  max(10, w - 20), 20];
    end

    %% FUNCIONES CALLBACK
    function setScenario(scenName)
        switch scenName
            case 'Normal'
                sldIrms.Value = In_rms * 0.85; sldIUF.Value = 1.1; sldTHD.Value = 3.2;
                sldVrms.Value = Vn; sldTemp.Value = 58; sldGrad.Value = 0.0;
                sldVibRMS.Value = 1.1; sldVibPeak.Value = 1.6;
            case 'Sobrecalentamiento'
                sldIrms.Value = In_rms * 1.45; sldIUF.Value = 1.8; sldTHD.Value = 4.2;
                sldVrms.Value = Vn - 5; sldTemp.Value = 135; sldGrad.Value = 2.8;
                sldVibRMS.Value = 2.1; sldVibPeak.Value = 3.0;
            case 'Falla_Electrica'
                sldIrms.Value = In_rms * 1.25; sldIUF.Value = 26.5; sldTHD.Value = 14.0;
                sldVrms.Value = Vn - 35; sldTemp.Value = 88; sldGrad.Value = 1.2;
                sldVibRMS.Value = 3.4; sldVibPeak.Value = 5.8;
            case 'Falla_Mecanica'
                sldIrms.Value = In_rms * 1.10; sldIUF.Value = 2.8; sldTHD.Value = 4.5;
                sldVrms.Value = Vn; sldTemp.Value = 74; sldGrad.Value = 0.4;
                sldVibRMS.Value = 8.8; sldVibPeak.Value = 24.5;
        end
        updateDiagnosis();
    end

    function updateDiagnosis()
        x_raw = [sldIrms.Value, sldIUF.Value, sldTHD.Value, sldVrms.Value, ...
                 sldTemp.Value, sldGrad.Value, sldVibRMS.Value, sldVibPeak.Value];
        x_norm = (x_raw - model.mu) ./ model.sigma;

        z1 = max(0, x_norm * model.W1 + model.b1);
        z2 = max(0, z1 * model.W2 + model.b2);
        z3 = z2 * model.W3 + model.b3;
        ez3 = exp(z3 - max(z3));
        probs = (ez3 ./ sum(ez3)) * 100;
        [maxProb, predClassIdx] = max(probs);
        predClassName = model.classNames{predClassIdx};

        cla(axProbs);
        barColors = [0.2 0.7 0.3; 0.95 0.55 0.1; 0.85 0.2 0.2; 0.6 0.2 0.8];
        b = bar(axProbs, 1:4, probs, 'FaceColor', 'flat');
        b.CData = barColors;
        axProbs.XTick = 1:4;
        axProbs.XTickLabel = {'Normal', 'Sobrecarga', 'F. Eléctrica', 'F. Mecánica'};
        for k = 1:4
            text(axProbs, k, probs(k) + 4, sprintf('%.1f%%', probs(k)), ...
                 'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
        end

        switch predClassName
            case 'Normal'
                pnlBanner.BackgroundColor = [0.15, 0.70, 0.25];
                pnlBanner.HighlightColor  = [0.10, 0.50, 0.20];
                lblStatusTitle.Text = 'ESTADO DE OPERACIÓN: NORMAL (CONFORME)';
                lblConfidence.Text = sprintf('Certeza IA: %.1f%%  |  Condición Operativa Conforme (Sin Advertencias)', maxProb);
                txtMaint.Value = sprintf([ ...
                    'DIAGNÓSTICO: Parámetros operativos dentro de tolerancias estándar.\n' ...
                    '- Monitoreo RETIE: Temp devanado (%0.1f°C) < Límite Clase F (155°C).\n' ...
                    '- Monitoreo ISO 10816: Vibración (%0.2f mm/s) en Zona A (Excelente).\n' ...
                    '- Monitoreo Eléctrico: Desbalance (%0.1f%%) < 3%% | THD (%0.1f%%) < 5%%.\n\n' ...
                    'ACCIONES DE LA RUTA DE MANTENIMIENTO:\n' ...
                    '1. Predictivo: Continuar adquisición continua de telemetría multisensor.\n' ...
                    '2. Preventivo: Inspección de lubricación de rodamientos mensual.\n' ...
                    '3. Mantener tolva del molino en tasa continua nominal sin restricciones.'], ...
                    sldTemp.Value, sldVibRMS.Value, sldIUF.Value, sldTHD.Value);

            case 'Sobrecalentamiento'
                pnlBanner.BackgroundColor = [0.92, 0.50, 0.08];
                pnlBanner.HighlightColor  = [0.75, 0.35, 0.05];
                lblStatusTitle.Text = 'ALERTA: SOBRECALENTAMIENTO / SOBRECARGA TÉRMICA';
                lblConfidence.Text = sprintf('Certeza IA: %.1f%%  |  Alerta de Aislamiento Clase F', maxProb);
                txtMaint.Value = sprintf([ ...
                    'DIAGNÓSTICO: Sobrecarga térmica crítica detectada en el estator.\n' ...
                    '- Temperatura (%0.1f°C) con gradiente acelerado (%0.1f°C/min).\n' ...
                    '- Riesgo RETIE: Degradación del barniz aislante Clase F (155°C).\n' ...
                    '- Corriente de estator (%0.1f A) supera umbral nominal (In = %0.1f A).\n\n' ...
                    'ACCIONES DE LA RUTA DE MANTENIMIENTO:\n' ...
                    '1. ACCIÓN INMEDIATA: Reducir alimentación de tolva al 60%% o rampa de desaceleración.\n' ...
                    '2. Planta: Limpieza de rejillas y verificación de ventilación forzada.\n' ...
                    '3. Taller: Medición de resistencia óhmica en caliente y prueba Megger.'], ...
                    sldTemp.Value, sldGrad.Value, sldIrms.Value, In_rms);

            case 'Falla_Electrica'
                pnlBanner.BackgroundColor = [0.85, 0.15, 0.15];
                pnlBanner.HighlightColor  = [0.65, 0.10, 0.10];
                lblStatusTitle.Text = 'PELIGRO: FALLA ELÉCTRICA (DESBALANCE / ESPIRAS)';
                lblConfidence.Text = sprintf('Certeza IA: %.1f%%  |  Asimetría de Fases Severa', maxProb);
                txtMaint.Value = sprintf([ ...
                    'DIAGNÓSTICO: Asimetría electromagnética severa detectada.\n' ...
                    '- Desbalance de Corriente IUF: %0.1f%% (Límite severo > 8%%).\n' ...
                    '- Distorsión Armónica THD: %0.1f%% (IEEE 519 Alerta).\n' ...
                    '- Presencia de corrientes de secuencia negativa y rizado de par.\n\n' ...
                    'ACCIONES DE LA RUTA DE MANTENIMIENTO:\n' ...
                    '1. ACCIÓN INMEDIATA: Desconexión y parada preventiva (LOTO).\n' ...
                    '2. Protocolo en Taller:\n' ...
                    '   a. CoreLoss Test (pérdidas en láminas magnéticas < 2.0 W/kg).\n' ...
                    '   b. Prueba Megger a 1000V DC (mínimo 100 MΩ) y prueba Hipot.\n' ...
                    '   c. Horno de pirólisis BurnOut (370°C), rebobinado CNC y barnizado VPI.'], ...
                    sldIUF.Value, sldTHD.Value);

            case 'Falla_Mecanica'
                pnlBanner.BackgroundColor = [0.55, 0.15, 0.75];
                pnlBanner.HighlightColor  = [0.40, 0.10, 0.60];
                lblStatusTitle.Text = 'PELIGRO: FALLA MECÁNICA (DESALINEACIÓN / RODAMIENTOS)';
                lblConfidence.Text = sprintf('Certeza IA: %.1f%%  |  Vibración Crítica ISO 10816', maxProb);
                txtMaint.Value = sprintf([ ...
                    'DIAGNÓSTICO: Anomalía mecánica severa en el tren de molienda.\n' ...
                    '- Severidad Vibratoria RMS: %0.2f mm/s (ISO 10816 Zona D: Peligro).\n' ...
                    '- Amplitud de Pico: %0.2f mm/s (Impactos en pistas de rodamiento).\n\n' ...
                    'ACCIONES DE LA RUTA DE MANTENIMIENTO:\n' ...
                    '1. ACCIÓN INMEDIATA: Parada controlada para evitar contacto estator-rotor.\n' ...
                    '2. Diagnóstico Predictivo: Análisis FFT de envolvente (frecuencias BPFO/BPFI).\n' ...
                    '3. Intervención en Taller:\n' ...
                    '   a. Sustitución de rodamientos (SKF Explorer con juego C3).\n' ...
                    '   b. Alineación láser de acople motor-molino (tolerancia < 0.05 mm).\n' ...
                    '   c. Balanceo dinámico en dos planos.'], ...
                    sldVibRMS.Value, sldVibPeak.Value);
        end
    end

    function saveSnapshot()
        destFile = options.SnapshotPath;
        destDir = fileparts(destFile);
        if ~isempty(destDir) && ~exist(destDir, 'dir'), mkdir(destDir); end
        exportapp(fig, char(destFile));
        uialert(fig, sprintf('Captura guardada en:\n%s', destFile), 'Captura Guardada', 'Icon', 'success');
    end

    setScenario('Normal');

    if options.AutoSaveSnapshot
        drawnow;
        destFile = options.SnapshotPath;
        destDir = fileparts(destFile);
        if ~isempty(destDir) && ~exist(destDir, 'dir'), mkdir(destDir); end
        exportapp(fig, char(destFile));
        fprintf('✓ Captura exportada a: %s\n', destFile);
        close(fig);
    end

    if nargout > 0, app = fig; end
end

function params = loadMotorConstants(scriptPath)
    run(scriptPath);
    params = struct();
    params.Pn = Pn;
    params.Vn = Vn;
    params.fn = fn;
    params.p = p;
    params.Tbase = Tbase;
    params.Ibase = Ibase;
    params.Rs = Rs;
end
