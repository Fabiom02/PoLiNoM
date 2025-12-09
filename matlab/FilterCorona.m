clear; close all; clc;

% Guitar sample for test

AudioFile = 'guitar_sample.wav';

[audio_sample, Fs_input] = audioread("guitar_sample.wav");
audio_sample = resample(audio_sample,24100,Fs_input);
audio_sample = mean(audio_sample, 2);

% Corona effect audio

NoiseFile = 'transmission_line_sound_100Hzharmonics.wav';

[y,Fs] = audioread(NoiseFile);   % Gets the signal and the frequency sample

% Parameters

N = min(length(audio_sample), length(y));                   % Number of samples
tapsFIR = 16;               % Number of FIR taps
mu = 0.1;                  % Step size

% Desired Signal
t = (0:N-1)';
input_signal = audio_sample(1:N);
input_noise = y(1:N);

%sound(input_signal, Fs);

d = input_signal + input_noise;

%sound(d, Fs);

% Noise reference
reference_noise = filter([-0.8 0.1 0.25], 1, input_noise);

% LMS FIR object
lms = dsp.LMSFilter('Length', tapsFIR, 'StepSize', mu);

% Applying the adaptive filter
[x_est, error, w] = lms(reference_noise, d);

sound(error, Fs);

% Recuperation of final weights
w_final = w(:,end);

% Plot - principal results
figure('Name','Results LMS','NumberTitle','off');
subplot(4,1,1);
plot(t, d); xlabel('Samples'); ylabel('Amplitude'); title('Signal with noise (d)');

subplot(4,1,2);
plot(t, x_est); xlabel('Samples'); ylabel('Amplitude'); title('Filter output (x\_est)');

subplot(4,1,3);
plot(t, error); hold on;
plot(t, input_signal,'r--','LineWidth',1); hold off;
legend('error (clean estimation)','input\_signal (orig.)');
xlabel('Samples'); ylabel('Amplitude'); title('Error = d - x\_est');

% Plot final weights
subplot(4,1,4);
stem(0:tapsFIR-1, w_final, 'filled');
xlabel('Coeff index'); ylabel('Value');
title('Final weights (w\_final)');

% MSE and SNR improvement
mse = mean((input_signal - error).^2);
% noise before and after
noise_before = d - input_signal;            
noise_after  = error - input_signal;        
SNR_in  = 10*log10(var(input_signal) / var(noise_before));
SNR_out = 10*log10(var(input_signal) / var(noise_after));
SNR_improvement = SNR_out - SNR_in;

fprintf('MSE between input_signal and error: %g\n', mse);
fprintf('SNR before: %g dB\n', SNR_in);
fprintf('SNR after: %g dB\n', SNR_out);
fprintf('SNR improvement: %g dB\n', SNR_improvement);
