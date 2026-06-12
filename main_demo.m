%% MAIN_DEMO  Full pipeline demo for MRDHCBI (Multi-Party Reversible Data
%             Hiding in Ciphertext Binary Images Based on Visual Cryptography)
%
%  Reference:
%    B. Chen et al., "Multi-Party Reversible Data Hiding in Ciphertext
%    Binary Images Based on Visual Cryptography,"
%    IEEE Signal Processing Letters, vol. 32, 2025.
%
%  Pipeline (Fig. 1 in paper):
%    Owner  -> encrypt_image    -> n ciphertext binary images (CBI)
%    Hider  -> embed_data       -> n marked ciphertext binary images (MBI)
%    Receiver (k-out-of-n) -> extract_data + recover_image
%
%  This demo uses (k=2, n=3) threshold visual cryptography.

clear; clc; close all;
addpath(genpath('src'));
addpath(genpath('utils'));

rng(42); % reproducibility

%% ── Parameters ──────────────────────────────────────────────────────────────
k = 2;   % reconstruction threshold
n = 3;   % number of data hiders / ciphertext shares

IMAGE_SIZE = [64, 64];           % small size for fast demo; change to [256,256] etc.
IMAGE_TYPE = 'checkerboard';     % 'checkerboard' | 'random' | 'gradient' | 'text'

% Data embedding keys (one per data hider; keep secret)
embed_keys = [1001, 2002, 3003];

% Secret data for each data hider (random bits, same length as #pixels)
num_pixels  = prod(IMAGE_SIZE);
secret_data = cell(1, n);
for i = 1:n
    secret_data{i} = uint8(randi([0,1], 1, num_pixels));
end

%% ── Step 1: Generate binary test image ──────────────────────────────────────
fprintf('=== Step 1: Generating binary image (%s %dx%d) ===\n', ...
        IMAGE_TYPE, IMAGE_SIZE(1), IMAGE_SIZE(2));
BI = make_test_binary_image(IMAGE_TYPE, IMAGE_SIZE(1), IMAGE_SIZE(2));

%% ── Step 2: Binary image encryption (Owner) ─────────────────────────────────
fprintf('=== Step 2: Encrypting image into %d ciphertext shares ===\n', n);
CBI = encrypt_image(BI, n, k);
fprintf('    Each share size: %d x %d pixels\n', size(CBI{1},1), size(CBI{1},2));

%% ── Step 3: Data embedding (each Data Hider independently) ──────────────────
fprintf('=== Step 3: Embedding secret data ===\n');
MBI = cell(1, n);
for i = 1:n
    MBI{i} = embed_data(CBI{i}, secret_data{i}, embed_keys(i), k, n);
    fprintf('    Data hider %d: embedded %d bits\n', i, num_pixels);
end

%% ── Step 4: Receiver collects k=2 out of n=3 marked shares ──────────────────
fprintf('=== Step 4: Receiver collects k=%d shares ===\n', k);

% Try all C(3,2)=3 combinations
combos = nchoosek(1:n, k);
for c = 1:size(combos, 1)
    idx   = combos(c, :);
    fprintf('\n--- Using shares %s ---\n', mat2str(idx));

    MBI_subset  = MBI(idx);
    keys_subset = embed_keys(idx);

    %% ── Step 5: Data extraction ──────────────────────────────────────────────
    [extracted_bits, CBI_restored] = extract_data(MBI_subset, keys_subset, k, n);

    %% ── Step 6: Binary image recovery ───────────────────────────────────────
    BI_recovered = recover_image(CBI_restored, k, n);

    %% ── Step 7: Evaluate metrics ─────────────────────────────────────────────
    for s = 1:k
        true_share = idx(s);
        m_obj = compute_metrics(BI, BI_recovered, ...
                                secret_data{true_share}, extracted_bits(s,:));
        fprintf('  Share %d | Lossless: %d | PER: %.4f | BER: %.4f\n', ...
                true_share, m_obj.lossless_recovery, ...
                m_obj.pixel_error_rate, m_obj.bit_error_rate);
    end
end

%% ── Step 8: Visualise one full run (shares 1 & 2) ───────────────────────────
fprintf('\n=== Step 8: Visualisation (shares 1 & 2) ===\n');
idx   = [1, 2];
[extracted_bits, CBI_restored] = extract_data(MBI(idx), embed_keys(idx), k, n);
BI_recovered = recover_image(CBI_restored, k, n);

[~, ~, m_cols, ~, ~] = vc_basis_matrices(k, n);

figure('Name', 'MRDHCBI Pipeline', 'NumberTitle', 'off', ...
       'Position', [50 50 1200 700]);

subplot(3, n+1, 1);
imshow(BI, []); title('Original BI');

for i = 1:n
    % Show first m columns of each share (one pixel block column)
    subplot(3, n+1, 1 + i);
    imshow(CBI{i}(:, 1:min(end, IMAGE_SIZE(2)*m_cols)), []);
    title(sprintf('CBI^{%d} (encrypted)', i));
end

for i = 1:n
    subplot(3, n+1, n+2 + i - 1);
    imshow(MBI{i}(:, 1:min(end, IMAGE_SIZE(2)*m_cols)), []);
    title(sprintf('MBI^{%d} (marked)', i));
end

subplot(3, n+1, 2*(n+1)+1);
imshow(BI_recovered, []); title('Recovered BI');

subplot(3, n+1, 2*(n+1)+2);
diff_img = abs(double(BI) - double(BI_recovered));
imshow(diff_img, []); title('Difference (should be all-black)');

sgtitle(sprintf('MRDHCBI: (%d,%d)-threshold VC | Image: %s', k, n, IMAGE_TYPE));
fprintf('Done. See figure for visual results.\n');
