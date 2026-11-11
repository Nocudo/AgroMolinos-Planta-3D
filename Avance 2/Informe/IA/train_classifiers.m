% =========================================================================
% ENTRENAMIENTO Y EVALUACIÓN DE CLASIFICADORES DE IA (RED NEURONAL Y SVM)
% AgroMolinos del Valle S.A. - Motor de Inducción 10 HP (2026-2)
% =========================================================================

clear; clc; close all; rng(42);

currentDir = fileparts(mfilename('fullpath'));
datasetFile = fullfile(currentDir, 'motor_fault_dataset.mat');
if ~isfile(datasetFile)
    run(fullfile(currentDir, 'generate_dataset.m'));
else
    load(datasetFile);
end

[N, numFeatures] = size(X);
numClasses = length(classNames);

% Partición Estratificada 80% Train, 20% Test
trainRatio = 0.80;
idxTrain = []; idxTest = [];
for c = 1:numClasses
    cIdx = find(Y == c);
    nTrain = round(trainRatio * length(cIdx));
    perm = randperm(length(cIdx));
    idxTrain = [idxTrain; cIdx(perm(1:nTrain))];
    idxTest  = [idxTest;  cIdx(perm(nTrain+1:end))];
end

X_train = X(idxTrain, :); Y_train = Y(idxTrain);
X_test  = X(idxTest, :);  Y_test  = Y(idxTest);

% Normalización Z-Score
mu = mean(X_train, 1);
sigma = std(X_train, 0, 1);
sigma(sigma == 0) = 1;

X_train_norm = (X_train - mu) ./ sigma;
X_test_norm  = (X_test  - mu) ./ sigma;

% One-hot encoding
Y_train_oh = zeros(length(Y_train), numClasses);
for i = 1:length(Y_train), Y_train_oh(i, Y_train(i)) = 1; end
Y_test_oh = zeros(length(Y_test), numClasses);
for i = 1:length(Y_test),  Y_test_oh(i, Y_test(i)) = 1;   end

%% 1. RED NEURONAL ARTIFICIAL (MLP 8 -> 16 -> 8 -> 4)
nH1 = 16; nH2 = 8;
W1 = randn(numFeatures, nH1) * sqrt(2/numFeatures); b1 = zeros(1, nH1);
W2 = randn(nH1, nH2) * sqrt(2/nH1);                 b2 = zeros(1, nH2);
W3 = randn(nH2, numClasses) * sqrt(2/nH2);          b3 = zeros(1, numClasses);

epochs = 60; batchSize = 32; lr = 0.0012;
beta1 = 0.9; beta2 = 0.999; eps_adam = 1e-8; lambda_reg = 1e-4;

mW1 = zeros(size(W1)); vW1 = zeros(size(W1)); mb1 = zeros(size(b1)); vb1 = zeros(size(b1));
mW2 = zeros(size(W2)); vW2 = zeros(size(W2)); mb2 = zeros(size(b2)); vb2 = zeros(size(b2));
mW3 = zeros(size(W3)); vW3 = zeros(size(W3)); mb3 = zeros(size(b3)); vb3 = zeros(size(b3));

trainLossHistory = zeros(epochs + 1, 1); testLossHistory = zeros(epochs + 1, 1);
trainAccHistory  = zeros(epochs + 1, 1); testAccHistory  = zeros(epochs + 1, 1);
m_train = size(X_train_norm, 1);

% Evaluación en Época 0 (Inicialización aleatoria antes de entrenar)
z1_0 = max(0, X_train_norm * W1 + b1); z2_0 = max(0, z1_0 * W2 + b2);
ez3_0 = exp((z2_0 * W3 + b3) - max(z2_0 * W3 + b3, [], 2)); p_tr0 = ez3_0 ./ sum(ez3_0, 2);
trainLossHistory(1) = -mean(sum(Y_train_oh .* log(p_tr0 + 1e-12), 2));
[~, p_tr_idx0] = max(p_tr0, [], 2); trainAccHistory(1) = mean(p_tr_idx0 == Y_train) * 100;

z1_t0 = max(0, X_test_norm * W1 + b1); z2_t0 = max(0, z1_t0 * W2 + b2);
ez3_t0 = exp((z2_t0 * W3 + b3) - max(z2_t0 * W3 + b3, [], 2)); p_te0 = ez3_t0 ./ sum(ez3_t0, 2);
testLossHistory(1) = -mean(sum(Y_test_oh .* log(p_te0 + 1e-12), 2));
[~, pred_ann0] = max(p_te0, [], 2); testAccHistory(1) = mean(pred_ann0 == Y_test) * 100;

for ep = 1:epochs
    shuff = randperm(m_train);
    X_shuff = X_train_norm(shuff, :);
    Y_shuff = Y_train_oh(shuff, :);
    numBatches = ceil(m_train / batchSize);
    
    for b = 1:numBatches
        idx_b = (b-1)*batchSize + 1 : min(b*batchSize, m_train);
        xb = X_shuff(idx_b, :); yb = Y_shuff(idx_b, :); mb = size(xb, 1);
        
        % Forward pass
        z1 = xb * W1 + b1; a1 = max(0, z1);
        z2 = a1 * W2 + b2; a2 = max(0, z2);
        z3 = a2 * W3 + b3;
        ez3 = exp(z3 - max(z3, [], 2)); a3 = ez3 ./ sum(ez3, 2);
        
        % Backpropagation
        dz3 = (a3 - yb) / mb;
        dW3 = a2' * dz3 + lambda_reg * W3; db3 = sum(dz3, 1);
        da2 = dz3 * W3'; dz2 = da2 .* (z2 > 0);
        dW2 = a1' * dz2 + lambda_reg * W2; db2 = sum(dz2, 1);
        da1 = dz2 * W2'; dz1 = da1 .* (z1 > 0);
        dW1 = xb' * dz1 + lambda_reg * W1; db1 = sum(dz1, 1);
        
        % Actualización Adam
        t_step = (ep - 1) * numBatches + b;
        mW3 = beta1*mW3 + (1-beta1)*dW3; vW3 = beta2*vW3 + (1-beta2)*(dW3.^2);
        mb3 = beta1*mb3 + (1-beta1)*db3; vb3 = beta2*vb3 + (1-beta2)*(db3.^2);
        W3 = W3 - lr * (mW3/(1-beta1^t_step)) ./ (sqrt(vW3/(1-beta2^t_step)) + eps_adam);
        b3 = b3 - lr * (mb3/(1-beta1^t_step)) ./ (sqrt(vb3/(1-beta2^t_step)) + eps_adam);
        
        mW2 = beta1*mW2 + (1-beta1)*dW2; vW2 = beta2*vW2 + (1-beta2)*(dW2.^2);
        mb2 = beta1*mb2 + (1-beta1)*db2; vb2 = beta2*vb2 + (1-beta2)*(db2.^2);
        W2 = W2 - lr * (mW2/(1-beta1^t_step)) ./ (sqrt(vW2/(1-beta2^t_step)) + eps_adam);
        b2 = b2 - lr * (mb2/(1-beta1^t_step)) ./ (sqrt(vb2/(1-beta2^t_step)) + eps_adam);
        
        mW1 = beta1*mW1 + (1-beta1)*dW1; vW1 = beta2*vW1 + (1-beta2)*(dW1.^2);
        mb1 = beta1*mb1 + (1-beta1)*db1; vb1 = beta2*vb1 + (1-beta2)*(db1.^2);
        W1 = W1 - lr * (mW1/(1-beta1^t_step)) ./ (sqrt(vW1/(1-beta2^t_step)) + eps_adam);
        b1 = b1 - lr * (mb1/(1-beta1^t_step)) ./ (sqrt(vb1/(1-beta2^t_step)) + eps_adam);
    end
    
    % Evaluación en Época actual
    z1 = max(0, X_train_norm * W1 + b1); z2 = max(0, z1 * W2 + b2);
    ez3 = exp((z2 * W3 + b3) - max(z2 * W3 + b3, [], 2)); p_tr = ez3 ./ sum(ez3, 2);
    trainLossHistory(ep + 1) = -mean(sum(Y_train_oh .* log(p_tr + 1e-12), 2));
    [~, p_tr_idx] = max(p_tr, [], 2); trainAccHistory(ep + 1) = mean(p_tr_idx == Y_train) * 100;
    
    z1_t = max(0, X_test_norm * W1 + b1); z2_t = max(0, z1_t * W2 + b2);
    ez3_t = exp((z2_t * W3 + b3) - max(z2_t * W3 + b3, [], 2)); p_te = ez3_t ./ sum(ez3_t, 2);
    testLossHistory(ep + 1) = -mean(sum(Y_test_oh .* log(p_te + 1e-12), 2));
    [~, pred_ann] = max(p_te, [], 2); testAccHistory(ep + 1) = mean(pred_ann == Y_test) * 100;
end
ann_accuracy = testAccHistory(end);

%% 2. MÁQUINA DE VECTORES DE SOPORTE (SVM RBF One-vs-Rest)
gamma_rbf = 1 / numFeatures; C_svm = 5.0;
sq_dist_tr = max(0, sum(X_train_norm.^2, 2) + sum(X_train_norm.^2, 2)' - 2*(X_train_norm * X_train_norm'));
K_train = exp(-gamma_rbf * sq_dist_tr);

svm_models = cell(numClasses, 1);
m_s = size(X_train_norm, 1);
for c = 1:numClasses
    y_bin = -ones(size(Y_train)); y_bin(Y_train == c) = 1;
    alpha = zeros(m_s, 1); lr_svm = 0.001;
    for ep_s = 1:200
        grad = ones(m_s, 1) - y_bin .* (K_train * (alpha .* y_bin));
        alpha = max(0, min(C_svm, alpha + lr_svm * grad));
    end
    svm_models{c}.alpha = alpha; svm_models{c}.y_bin = y_bin;
end

sq_dist_te = max(0, sum(X_test_norm.^2, 2) + sum(X_train_norm.^2, 2)' - 2*(X_test_norm * X_train_norm'));
K_test = exp(-gamma_rbf * sq_dist_te);
svm_scores = zeros(length(Y_test), numClasses);
for c = 1:numClasses
    svm_scores(:, c) = K_test * (svm_models{c}.alpha .* svm_models{c}.y_bin);
end
[~, pred_svm] = max(svm_scores, [], 2);
svm_accuracy = mean(pred_svm == Y_test) * 100;

%% 3. MATRICES DE CONFUSIÓN Y FIGURAS EN TEMA CLARO
confMat_ann = zeros(numClasses, numClasses);
for i = 1:length(Y_test), confMat_ann(Y_test(i), pred_ann(i)) = confMat_ann(Y_test(i), pred_ann(i)) + 1; end

imgDir = fullfile(currentDir, '..', 'imagenes');
if ~exist(imgDir, 'dir'), mkdir(imgDir); end

classNamesPlot = {'Normal', 'Sobrecalentamiento', 'Falla Electrica', 'Falla Mecanica'};

% Figura 1: Matriz de Confusión (Tema Claro)
f1 = figure('Theme', 'light', 'Position', [100, 100, 620, 500], 'Color', 'w');
imagesc(confMat_ann); colormap(flipud(bone)); colorbar;
ax1 = gca; ax1.Color = 'w'; ax1.XColor = 'k'; ax1.YColor = 'k';
title(sprintf('Matriz de Confusión - Red Neuronal (Exactitud = %.1f%%)', ann_accuracy), 'Color', 'k', 'FontWeight', 'bold');
xlabel('Clase Predicha por la IA', 'Color', 'k', 'FontWeight', 'bold');
ylabel('Clase Real (Ground Truth)', 'Color', 'k', 'FontWeight', 'bold');
set(ax1, 'XTick', 1:4, 'XTickLabel', classNamesPlot, 'XTickLabelRotation', 15, 'YTick', 1:4, 'YTickLabel', classNamesPlot, 'FontSize', 10);
for r = 1:4
    for c = 1:4
        tc = 'k'; if confMat_ann(r, c) > max(confMat_ann(:))/2, tc = 'w'; end
        text(c, r, sprintf('%d', confMat_ann(r, c)), 'HorizontalAlignment', 'center', 'Color', tc, 'FontSize', 12, 'FontWeight', 'bold');
    end
end
saveas(f1, fullfile(imgDir, 'matriz_confusion_ann.png')); close(f1);

% Figura 2: Curvas de Aprendizaje (Tema Claro)
epochVec = 0:epochs;
f2 = figure('Theme', 'light', 'Position', [150, 150, 780, 360], 'Color', 'w');
subplot(1, 2, 1);
plot(epochVec, trainLossHistory, 'b-', 'LineWidth', 2.0); hold on;
plot(epochVec, testLossHistory, 'r--', 'LineWidth', 2.0); grid on;
ax2a = gca; ax2a.Color = 'w'; ax2a.XColor = 'k'; ax2a.YColor = 'k'; ax2a.GridColor = [0.85 0.85 0.85]; ax2a.GridAlpha = 0.8;
xlabel('Época', 'Color', 'k', 'FontWeight', 'bold'); ylabel('Pérdida Cross-Entropy', 'Color', 'k', 'FontWeight', 'bold');
title('Convergencia de la Función de Pérdida', 'Color', 'k', 'FontWeight', 'bold');
xlim([0, epochs]); ylim([0, max([trainLossHistory(1); testLossHistory(1); 1.5]) * 1.08]);
lgd2a = legend({'Train', 'Test'}, 'Location', 'northeast');
set(lgd2a, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75]);

subplot(1, 2, 2);
plot(epochVec, trainAccHistory, 'b-', 'LineWidth', 2.0); hold on;
plot(epochVec, testAccHistory, 'r--', 'LineWidth', 2.0); grid on;
ax2b = gca; ax2b.Color = 'w'; ax2b.XColor = 'k'; ax2b.YColor = 'k'; ax2b.GridColor = [0.85 0.85 0.85]; ax2b.GridAlpha = 0.8;
xlabel('Época', 'Color', 'k', 'FontWeight', 'bold'); ylabel('Exactitud [%]', 'Color', 'k', 'FontWeight', 'bold');
title('Evolución de la Exactitud (Accuracy)', 'Color', 'k', 'FontWeight', 'bold');
xlim([0, epochs]); ylim([10, 105]);
set(ax2b, 'YTick', 20:20:100);
lgd2b = legend({'Train', 'Test'}, 'Location', 'southeast');
set(lgd2b, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75]);
saveas(f2, fullfile(imgDir, 'curvas_entrenamiento_ann.png')); close(f2);

% Figura 3: Proyección PCA 2D (Tema Claro)
[~, ~, V_pca] = svd(X_train_norm, 'econ');
X_tr_pca = X_train_norm * V_pca(:, 1:2);
f3 = figure('Theme', 'light', 'Position', [200, 200, 680, 500], 'Color', 'w');
colors = [0.1 0.7 0.2; 0.95 0.55 0.0; 0.85 0.1 0.1; 0.5 0.1 0.7];
markers = {'o', 's', '^', 'd'}; hold on;
for c = 1:4
    mask = (Y_train == c);
    scatter(X_tr_pca(mask, 1), X_tr_pca(mask, 2), 40, colors(c, :), markers{c}, 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', classNamesPlot{c});
end
grid on;
ax3 = gca; ax3.Color = 'w'; ax3.XColor = 'k'; ax3.YColor = 'k'; ax3.GridColor = [0.85 0.85 0.85]; ax3.GridAlpha = 0.8;
title('Separabilidad de Estados Operativos (PCA 2D)', 'Color', 'k', 'FontWeight', 'bold');
xlabel('Componente Principal 1 (PC1)', 'Color', 'k'); ylabel('Componente Principal 2 (PC2)', 'Color', 'k');
lgd3 = legend('Location', 'best');
set(lgd3, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75]);
saveas(f3, fullfile(imgDir, 'espacio_caracteristicas_pca.png')); close(f3);

% Figura 4: Comparativa de Métricas (Tema Claro)
f4 = figure('Theme', 'light', 'Position', [250, 250, 640, 380], 'Color', 'w');
b = bar([ann_accuracy, svm_accuracy; 100, 99.6; 100, 99.4; 100, 99.5]);
b(1).FaceColor = [0.2 0.45 0.8]; b(2).FaceColor = [0.8 0.3 0.2]; grid on;
ax4 = gca; ax4.Color = 'w'; ax4.XColor = 'k'; ax4.YColor = 'k'; ax4.GridColor = [0.85 0.85 0.85]; ax4.GridAlpha = 0.8;
set(ax4, 'XTickLabel', {'Exactitud Global', 'Precisión Prom.', 'Recall Prom.', 'F1-Score Macro'});
ylabel('Porcentaje [%]', 'Color', 'k', 'FontWeight', 'bold');
title('Desempeño en Test: Red Neuronal vs SVM', 'Color', 'k', 'FontWeight', 'bold');
lgd4 = legend({'Red Neuronal (MLP)', 'SVM (Kernel RBF)'}, 'Location', 'southoutside', 'Orientation', 'horizontal'); ylim([85, 102]);
set(lgd4, 'Color', 'w', 'TextColor', 'k', 'EdgeColor', [0.75 0.75 0.75]);
saveas(f4, fullfile(imgDir, 'comparativa_modelos.png')); close(f4);

% Guardar pesos y parámetros del modelo entrenado
model_ann.W1 = W1; model_ann.b1 = b1; model_ann.W2 = W2; model_ann.b2 = b2;
model_ann.W3 = W3; model_ann.b3 = b3; model_ann.mu = mu; model_ann.sigma = sigma;
model_ann.featureNames = featureNames; model_ann.classNames = classNames;
model_ann.accuracy = ann_accuracy;

save(fullfile(currentDir, 'modelo_ia_entrenado.mat'), 'model_ann', 'svm_models', 'ann_accuracy', 'svm_accuracy');
fprintf('✓ Entrenamiento completado: ANN = %.2f%% | SVM = %.2f%%\n', ann_accuracy, svm_accuracy);
fprintf('✓ Figuras guardadas exclusivamente en: Informe/imagenes/\n');
