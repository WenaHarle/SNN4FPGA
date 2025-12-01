%% mean_spike_amp_vs_W_beta_theta.m
clear; clc; close all;

% ================== PARAMETER WAKTU & INPUT ==================
dt      = 0.01;          % [ms]
T_in    = 64;             % periode input [ms]
Ton     = 5;              % lebar pulsa aktif [ms]
T_total = 10 * T_in;      % simulasi 10 periode

% Precompute spike train (sama untuk semua sweep)
s = make_spike_train_time(T_total, dt, T_in, Ton);

% Buang beberapa periode pertama sebagai transient
t_trans   = 4 * T_in;                 % buang 4 periode awal
idx_start = round(t_trans / dt) + 1;

% ================== PARAMETER NEURON DASAR ==================
beta_fix  = 0.2;
theta_fix = 10;
W_fix     = 10;    % weight tetap untuk sweep beta & theta (silakan ubah kalau mau)

%% ================== 1) SWEEP W =============================
W_list      = linspace(0, 25, 25001);   % dari skripmu
mean_y_W    = nan(size(W_list));

for iw = 1:numel(W_list)
    w = W_list(iw);

    [v, y] = lif_neuron(s, w, beta_fix, theta_fix);

    if idx_start > numel(y), idx_start = 1; end
    y_ss = y(idx_start:end);

    mean_y_W(iw) = mean(y_ss);
end

figure; hold on; grid on;
plot(W_list, mean_y_W, 'LineWidth', 2);
xlabel('W (weight)');
ylabel('Amplitudo rata-rata spike out');
title(sprintf('Mean spike out vs W (\\beta=%.2f, \\theta=%.2f)', beta_fix, theta_fix));
ylim([0 0.1]);

%% ================== 2) SWEEP BETA ==========================
beta_list   = linspace(0.01, 0.99, 1000);   % contoh range leak
mean_y_beta = nan(size(beta_list));

for ib = 1:numel(beta_list)
    b = beta_list(ib);

    [v, y] = lif_neuron(s, W_fix, b, theta_fix);

    if idx_start > numel(y), idx_start = 1; end
    y_ss = y(idx_start:end);

    mean_y_beta(ib) = mean(y_ss);
end

figure; hold on; grid on;
plot(beta_list, mean_y_beta, 'LineWidth', 2);
xlabel('\beta (leak)');
ylabel('Amplitudo rata-rata spike out');
title(sprintf('Mean spike out vs \\beta (W=%.2f, \\theta=%.2f)', W_fix, theta_fix));
ylim([0 0.1]);

%% ================== 3) SWEEP THETA =========================
theta_list   = linspace(1, 30, 3000);      % contoh range threshold
mean_y_theta = nan(size(theta_list));

for it = 1:numel(theta_list)
    th = theta_list(it);

    [v, y] = lif_neuron(s, W_fix, beta_fix, th);

    if idx_start > numel(y), idx_start = 1; end
    y_ss = y(idx_start:end);

    mean_y_theta(it) = mean(y_ss);
end

figure; hold on; grid on;
plot(theta_list, mean_y_theta, 'LineWidth', 2);
xlabel('\theta (threshold)');
ylabel('Amplitudo rata-rata spike out');
title(sprintf('Mean spike out vs \\theta (W=%.2f, \\beta=%.2f)', W_fix, beta_fix));
ylim([0 0.1]);

%% ===========================================================
%% ===================== FUNGSI ==============================

function [v, y] = lif_neuron(spike_in, w, beta, theta)
    N = numel(spike_in);
    v = zeros(1, N);
    y = zeros(1, N);

    for k = 2:N
        v(k) = beta * v(k-1) + w * spike_in(k) - theta * y(k-1);
        y(k) = v(k) >= theta;
    end
end

function s = make_spike_train_time(T_total, dt, T_in, pulse_width)
    Nt = round(T_total / dt);
    s  = zeros(1, Nt);

    if T_in <= 0
        return;
    end

    width_steps = max(1, round(pulse_width / dt));
    spike_times = 0:T_in:(T_total - T_in);
    spike_idx   = round(spike_times / dt) + 1;

    for k = 1:numel(spike_idx)
        idx_start = spike_idx(k);
        idx_end   = min(idx_start + width_steps - 1, Nt);
        s(idx_start:idx_end) = 1;
    end
end
