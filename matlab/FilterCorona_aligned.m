clear; close all; clc;

% --- User options ---
useNormalized = false;   % true -> use Normalized LMS
autoAlign = true;       % estimate delay via xcorr and align (offline)
tapsFIR = 16;           % adaptive filter length
mu_norm = 0.1;          % StepSize for Normalized LMS (typical 0.1-1.0).
mu_plain = 0.1;        % StepSize for plain LMS

% --- Read files ---
AudioFile = 'guitar_sample.wav';
NoiseFile = 'transmission_line_sound_100Hzharmonics.wav';

[audio_sample, Fs_audio] = audioread(AudioFile);
audio_sample = resample(audio_sample,24100,Fs_audio);
audio_sample = mean(audio_sample,2);

[noise_sig, Fs_noise] = audioread(NoiseFile);

Fs = Fs_noise;

% trim to same length for simple demo
N = min(length(audio_sample), length(noise_sig));
input_signal = audio_sample(1:N);
input_noise  = noise_sig(1:N);

% desired (primary) = wanted signal + noise
d = input_signal + input_noise;

%soundsc(d, Fs);

% create a realistic reference with extra delay/taps in front
% e.g. filter with two leading zeros to introduce delay
reference_noise = filter([0 0 -0.8 0.1 0.25], 1, input_noise);

% --- Estimate delay and align (offline) ---
if autoAlign
    maxLag = 2000; % search window
    [xc, lags] = xcorr(reference_noise, input_noise, maxLag, 'normalized');
    [~, I] = max(abs(xc));
    estLag = lags(I); % positive => reference lags input_noise by estLag samples
    fprintf('Estimated lag (reference vs input_noise): %d samples\n', estLag);

    if estLag > 0
        % reference delayed: trim its first estLag samples so it's advanced relative to d
        reference_al = reference_noise(estLag+1:end);
        d_al = d(1:end-estLag);
        input_signal_al = input_signal(1:end-estLag);
    elseif estLag < 0
        % reference leads input_noise: pad reference at start
        pad = zeros(-estLag,1);
        reference_al = [pad; reference_noise];
        reference_al = reference_al(1:N);
        d_al = d;
        input_signal_al = input_signal;
    else
        reference_al = reference_noise;
        d_al = d;
        input_signal_al = input_signal;
    end
else
    reference_al = reference_noise;
    d_al = d;
    input_signal_al = input_signal;
end

% ensure equal length
L = min(length(reference_al), length(d_al));
reference_al = reference_al(1:L);
d_al = d_al(1:L);
input_signal_al = input_signal_al(1:L);
t = (0:L-1)';

% --- Create adaptive filter object ---
if useNormalized
    lmsObj = dsp.LMSFilter('Length', tapsFIR, ...
                           'StepSize', mu_norm, ...
                           'Method','Normalized LMS');
else
    lmsObj = dsp.LMSFilter('Length', tapsFIR, ...
                           'StepSize', mu_plain, ...
                           'Method','LMS');
end

% --- Run adaptation (offline batch) ---
[x_est, error_out, w] = lmsObj(reference_al, d_al);
w_final = w(:,end);

% play cleaned output
soundsc(error_out, Fs);

% --- Plots ---
figure('Name','Results Normalized LMS','NumberTitle','off');
subplot(4,1,1);
plot(t, d_al); title('Signal with noise (d)'); xlabel('Samples');
subplot(4,1,2);
plot(t, x_est); title('Filter output (x\_est)'); xlabel('Samples');
subplot(4,1,3);
plot(t, error_out); hold on;
plot(t, input_signal_al,'r--'); hold off;
legend('error (clean estimation)','input\_signal (orig.)');
title('Error = d - x\_est'); xlabel('Samples');
subplot(4,1,4);
stem(0:tapsFIR-1, w_final, 'filled');
title('Final weights'); xlabel('Coeff index');

% metrics
mse = mean((input_signal_al - error_out).^2);
noise_before = d_al - input_signal_al;
noise_after  = error_out - input_signal_al;
SNR_in  = 10*log10(var(input_signal_al) / var(noise_before));
SNR_out = 10*log10(var(input_signal_al) / var(noise_after));
fprintf('MSE: %g\nSNR before: %g dB\nSNR after: %g dB\n', mse, SNR_in, SNR_out);