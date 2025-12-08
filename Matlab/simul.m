%% LIF Neuron Experiments — versi frekuensi diskrit (64 ms, dt = 0.001 ms)
clear; clc; close all;

% ================== PARAMETER WAKTU ==================
T_total_ms = 64;        % total durasi simulasi [ms]
dt_ms      = 0.001;     % resolusi waktu [ms]
Nt         = round(T_total_ms / dt_ms);   % jumlah sampel
t          = (0:Nt-1) * dt_ms;            % vektor waktu [ms]
fs_Hz      = 1000 / dt_ms;                % sampling freq [Hz]

% ================== PARAMETER NEURON ==================
w_fix      = 1.0;    % weight tetap
beta_fix   = 0.8;    % faktor leak
theta_fix  = 1.5;    % threshold
T_in_fix_ms = 5;     % periode spike input [ms] (untuk sweep lain)
pulse_w_ms = 0.3;    % lebar pulsa spike [ms]

% Konversi ke domain sampel
T_in_fix_samp = round(T_in_fix_ms / dt_ms);
pulse_w_samp  = max(1, round(pulse_w_ms / dt_ms));

%% 1. Frekuensi spike input vs output (smooth sweep, dalam Hz)
%    + Pembuktian bahwa hubungan tidak linear secara global

T_in_ms_list   = linspace(1, 64, 640);          % periode input [ms]
T_in_samp_list = round(T_in_ms_list / dt_ms);   % periode input [sampel, integer]
f_in_list      = fs_Hz ./ T_in_samp_list;       % frekuensi input [Hz]
f_out_list     = zeros(size(T_in_ms_list));     % frekuensi output [Hz]

for i = 1:numel(T_in_ms_list)
    T_in_samp = T_in_samp_list(i);  % periode dalam sampel

    s = make_spike_train_discrete(Nt, T_in_samp, pulse_w_samp);
    [v, y] = lif_neuron(s, w_fix, beta_fix, theta_fix);
    f_out_list(i) = compute_freq_time(y, dt_ms);  % [Hz]
end

% --- Plot utama hubungan f_in vs f_out ---
figure;
subplot(2,1,1);
plot(f_in_list, f_out_list, 'b', 'LineWidth', 1.5); hold on;
xlabel('Frekuensi Spike Input (Hz)');
ylabel('Frekuensi Spike Output (Hz)');
title('Input Frequency vs Output Frequency (LIF Neuron, diskrit)');
grid on;

% --- PILIH REGION QUASI-LINEAR UNTUK DI-FIT ---
% Range T_in 5–30 ms (≈ 33–200 Hz) dan hanya yang ada spike
idx_lin = (T_in_ms_list >= 5) & (T_in_ms_list <= 30) & (f_out_list > 0);

fin_lin  = f_in_list(idx_lin);
fout_lin = f_out_list(idx_lin);

% Regresi linear di region ini: f_out ≈ a * f_in + b
p = polyfit(fin_lin, fout_lin, 1);   % p(1)=a, p(2)=b
fout_fit_lin = polyval(p, fin_lin);

% Plot garis fit hanya di region quasi-linear
plot(fin_lin, fout_fit_lin, 'r--', 'LineWidth', 1.5);
legend('Data simulasi','Fit linear (region quasi-linear)','Location','best');

% Tampilkan parameter garis
txt = sprintf('f_{out} \\approx %.2f f_{in} %+ .2f (T_{in} = 5–30 ms)', p(1), p(2));
text(0.05*max(f_in_list), 0.9*max(f_out_list), txt, 'FontSize', 8, 'BackgroundColor', 'w');

% --- ANALISIS ERROR: BUKTI TIDAK LINEAR SECARA GLOBAL ---
% Hitung prediksi linear untuk seluruh f_in (pakai p dari region tengah)
fout_pred_all = polyval(p, f_in_list);

% Error absolut hanya untuk titik yang memang spike (f_out > 0)
idx_pos = (f_out_list > 0);
err_all = nan(size(f_out_list));
err_all(idx_pos) = abs(f_out_list(idx_pos) - fout_pred_all(idx_pos));

subplot(2,1,2);
plot(f_in_list, err_all, 'k', 'LineWidth', 1.5);
xlabel('Frekuensi Spike Input (Hz)');
ylabel('|Error linear fit| (Hz)');
title('Error terhadap fit linear (bukti non-linear global)');
grid on;

% Batas error kecil (misal 1 Hz)
hold on;
yline(1.0, 'r--');
text(0.05*max(f_in_list), 1.1, 'Batas error kecil (misal 1 Hz)', 'Color', 'r', 'FontSize', 8);

% ================== 2. Weight vs frekuensi output ==================
w_list  = linspace(0.1, 3, 3000);
f_out_w = zeros(size(w_list));

for i = 1:numel(w_list)
    w = w_list(i);

    s = make_spike_train_discrete(Nt, T_in_fix_samp, pulse_w_samp);
    [v, y] = lif_neuron(s, w, beta_fix, theta_fix);
    f_out_w(i) = compute_freq_time(y, dt_ms);  % [Hz]
end

figure;
plot(w_list, f_out_w, 'LineWidth', 2);
xlabel('Weight');
ylabel('Frekuensi Output (Hz)');
title('Effect of Weight on Output Frequency (diskrit)');
grid on;

% ================== 3. Threshold vs frekuensi output ==================
theta_list = linspace(0.1, 3, 3000);
f_out_th   = zeros(size(theta_list));

for i = 1:numel(theta_list)
    theta = theta_list(i);

    s = make_spike_train_discrete(Nt, T_in_fix_samp, pulse_w_samp);
    [v, y] = lif_neuron(s, w_fix, beta_fix, theta);
    f_out_th(i) = compute_freq_time(y, dt_ms);  % [Hz]
end

figure;
plot(theta_list, f_out_th, 'LineWidth', 2);
xlabel('Threshold');
ylabel('Frekuensi Output (Hz)');
title('Effect of Threshold on Output Frequency (diskrit)');
grid on;

% ================== 4. Beta vs frekuensi output ==================
beta_list  = linspace(0.1, 0.99, 1000);
f_out_beta = zeros(size(beta_list));

for i = 1:numel(beta_list)
    beta = beta_list(i);

    s = make_spike_train_discrete(Nt, T_in_fix_samp, pulse_w_samp);
    [v, y] = lif_neuron(s, w_fix, beta, theta_fix);
    f_out_beta(i) = compute_freq_time(y, dt_ms);  % [Hz]
end

figure;
plot(beta_list, f_out_beta, 'LineWidth', 2);
xlabel('Beta (leak)');
ylabel('Frekuensi Output (Hz)');
title('Effect of Beta on Output Frequency (diskrit)');
grid on;

% ================== 5. Contoh satu eksperimen (sampling lengkap) =======
T_in_example_ms   = 5;                          % ms
T_in_example_samp = round(T_in_example_ms / dt_ms);

s_ex = make_spike_train_discrete(Nt, T_in_example_samp, pulse_w_samp);
[v_ex, y_ex] = lif_neuron(s_ex, w_fix, beta_fix, theta_fix);

figure;
subplot(3,1,1);
stairs(t, s_ex, 'LineWidth', 2);
ylabel('Spike In');
title(sprintf('Respons Neuron LIF (T_{in} = %.1f ms, diskrit)', T_in_example_ms));
xlim([0 T_total_ms]);
grid on;

subplot(3,1,2);
plot(t, v_ex, 'LineWidth', 2);
ylabel('v_m (a.u.)');
xlim([0 T_total_ms]);
grid on;

subplot(3,1,3);
stairs(t, y_ex, 'LineWidth', 2);
ylabel('Spike Out');
xlabel('Waktu (ms)');
xlim([0 T_total_ms]);
grid on;


%% =========== FUNGSI-FUNGSI ===========

function [v, y] = lif_neuron(spike_in, w, beta, theta)
    % Discrete-time LIF neuron
    N = numel(spike_in);
    v = zeros(1, N);
    y = zeros(1, N);

    v(1) = 0;
    y(1) = 0;

    for k = 2:N
        v(k) = beta * v(k-1) + w * spike_in(k) - theta * y(k-1);
        y(k) = v(k) >= theta;
    end
end

function s = make_spike_train_discrete(Nt, T_in_samp, width_samp)
    % Generate spike train murni dalam domain sampel.
    % Nt         : jumlah sampel total
    % T_in_samp  : periode spike input [sampel, integer]
    % width_samp : lebar pulsa spike [sampel, integer]

    s = zeros(1, Nt);

    if T_in_samp <= 0
        return;
    end

    spike_idx = 1:T_in_samp:Nt;  % spike pertama di sampel 1, lalu 1+T_in, dst

    for k = 1:numel(spike_idx)
        idx_start = spike_idx(k);
        idx_end   = min(idx_start + width_samp - 1, Nt);
        s(idx_start:idx_end) = 1;
    end
end

function f_Hz = compute_freq_time(y, dt_ms)
    % Hitung frekuensi spike output dalam satuan Hz
    idx = find(y == 1);
    if numel(idx) >= 2
        T_samples = mean(diff(idx));     % periode dalam satuan sampel
        T_ms      = T_samples * dt_ms;   % konversi ke ms
        f_Hz      = 1000 ./ T_ms;        % Hz (karena 1000 ms = 1 s)
    else
        f_Hz = 0;  % tidak ada atau hanya 1 spike -> dianggap 0 Hz
    end
end
