clear; close all; clc;

% Parameters
N = 2000;                 % Number of samples
tapsFIR = 16;             % Number of FIR taps
mu = 0.01;                % Step size

% Desired signal (ex.: sinusoid with white noise)
t = (0:N-1)';
input_signal = sin(2*pi*0.01*t);     % Input signal
input_noise = 0.5*randn(N,1);        % Noise
d = input_signal + input_noise;      % Desired signal

% Noise reference: correlated noise (reference channel)
reference_noise = filter([1 0.5 0.2], 1, input_noise);

% LMS FIR object
lms = dsp.LMSFilter('Length', tapsFIR, 'StepSize', mu);

% Applying the adaptive filter
[x_est, error, w] = lms(reference_noise, d);

% Plot of results
figure;
subplot(3,1,1);
plot(t, d); title('Sinal with noise');
subplot(3,1,2);
plot(t, x_est); title('Filter output');
subplot(3,1,3);
plot(t, error); title('Estimative of the clean signal');