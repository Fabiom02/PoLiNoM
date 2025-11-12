clear; close all; clc;

% --- Parameters ---

fs = 24100; % Sampling frequency (Hz)
duration = 5; % Duration (seconds)
t = 0:1/fs:duration;

% --- Base corona hiss (band-limited white noise, lowpass filtered) ---

hiss = sqrt(10) * randn(size(t)); % Adjusted amplitude
hiss = lowpass(hiss, 10000, fs); % Band-limited to 10 kHz to simulate acquisition bandwidth

% --- Amplitude modulation (double power line frequency, 100 Hz) ---

f_mod = 100;
modulator = 0.5 * (1 + 0.3 * sin(2 * pi * f_mod * t));

% --- Low-frequency hum (100 Hz and harmonics: 200, 300, 500 Hz) ---

hum = 0.05 * sin(2 * pi * 100 * t) + 0.02 * sin(2 * pi * 200 * t) + ...
      0.015 * sin(2 * pi * 300 * t) + 0.01 * sin(2 * pi * 500 * t);

% --- Random impulsive crackles ---

crackle_rate = 25; % crackles per second
n_crackles = round(crackle_rate * duration);
crackle_positions = randperm(length(t), n_crackles);
crackle = zeros(size(t));

for k = 1:n_crackles
    idx = crackle_positions(k);
    if idx < length(t) - 100
        width = randi([50 200]);
        amp = 0.5 * rand();
        crackle(idx:min(idx+width,length(t))) = amp * hamming(min(width+1,length(t)-idx+1))';
    end
end

% --- Combine components and normalize ---

y = 1.2 * (0.3 * modulator .* hiss + hum + crackle);
y = y / max(abs(y));

% --- Playback ---

sound(y, fs);

% --- Save audio file ---

audiowrite('transmission_line_sound_100Hzharmonics.wav', y, fs);
fprintf('Saved transmission_line_sound_100Hzharmonics.wav\n');

% --- Plot waveform ---

figure('Name', 'Transmission Line Sound Simulation (100 Hz Harmonics)');
subplot(2,1,1);
plot(t, y);
xlim([0 0.05]);
xlabel('Time (s)');
ylabel('Amplitude');
title('Waveform (Zoomed)');

% --- Frequency spectrum ---

N = length(y);
f = linspace(0, fs/2, floor(N/2));
Y = abs(fft(y));
subplot(2,1,2);
plot(f, 20 * log10(Y(1:floor(N/2))));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Amplitude Spectrum');
grid on;