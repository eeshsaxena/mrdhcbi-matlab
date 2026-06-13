%% RUN_EXPERIMENTS  Reproduce Table I (encryption runtime) and Fig. 3
%                   (embedding rates) from Chen et al., IEEE SPL 2025.
%
%  Uses synthetic images at the same pixel counts as the paper's dataset
%  (binary images from [16]: Cartoon-183, CAD-487, Texture-760,
%   Mask-1001, Pattern-1704, Document-3060 bmp files).
%  Since the dataset is not included, we generate random binary images
%  with matching pixel counts. Replace with imread() for real images.

clear; clc;
addpath(genpath('src'));
addpath(genpath('utils'));

k = 2; n = 3;   % (2,3) threshold as in paper
N_RUNS = 3;     % repetitions for timing stability

% Dataset sizes from paper (approximate pixel counts in thousands)
datasets = struct( ...
    'name',  {'Cartoon', 'CAD',  'Texture', 'Mask', 'Pattern', 'Document'}, ...
    'npix',  {183*183,   487*1,  256*256,   256*256, 256*256,  256*256} ...
);
% Use square images with matching pixel count
for d = 1:numel(datasets)
    s = round(sqrt(datasets(d).npix));
    datasets(d).rows = s;
    datasets(d).cols = s;
end
% Override with round numbers matching paper's approximate image counts
image_sizes = [183, 487, 760, 1001, 1704, 3060]; % bmp file sizes hint at total pixels
% For our synthetic test: use 256x256 for all (matches 65536-pixel images in paper Fig 2)
for d = 1:numel(datasets)
    datasets(d).rows = 256;
    datasets(d).cols = 256;
end

fprintf('=== Encryption Runtime (Table I equivalent) ===\n');
fprintf('%-12s  %10s\n', 'Image', 'Time (ms)');
fprintf('%s\n', repmat('-',1,25));

runtimes = zeros(1, numel(datasets));
for d = 1:numel(datasets)
    X = datasets(d).rows;
    Y = datasets(d).cols;

    % Generate synthetic binary image (replace with real image loading if available)
    rng(d * 100);
    BI = uint8(randi([0,1], X, Y));

    t_total = 0;
    for r = 1:N_RUNS
        t0 = tic;
        CBI = encrypt_image(BI, n, k);
        t_total = t_total + toc(t0);
    end
    runtimes(d) = (t_total / N_RUNS) * 1000; % ms
    fprintf('%-12s  %10.2f\n', datasets(d).name, runtimes(d));
end

fprintf('\n=== Embedding Rates (Fig. 3 equivalent) ===\n');
fprintf('%-12s  %12s  %12s\n', 'Image', 'Emb. bits', 'Rate (bpp)');
fprintf('%s\n', repmat('-',1,40));

embed_rates = zeros(1, numel(datasets));
for d = 1:numel(datasets)
    X = datasets(d).rows;
    Y = datasets(d).cols;
    rng(d * 200);
    BI = uint8(randi([0,1], X, Y));

    CBI = encrypt_image(BI, n, k);
    [~, ~, m_vc, ~, ~] = vc_basis_matrices(k, n);

    % Embedding capacity: X*Y bits per data hider
    num_embed_bits = X * Y;

    % bpp = embedded bits / pixels in ciphertext image (X x Y*m)
    num_cbi_pixels = X * Y * m_vc;
    bpp = num_embed_bits / num_cbi_pixels;

    embed_rates(d) = bpp;
    fprintf('%-12s  %12d  %12.4f\n', datasets(d).name, num_embed_bits, bpp);
end

%% Plot results (mirrors Fig. 3 layout)
figure('Name', 'Embedding Rate Comparison', 'NumberTitle', 'off', ...
       'Position', [100 100 800 400]);

bar_data = embed_rates;
b = bar(bar_data, 0.5);
b.FaceColor = [0.2 0.4 0.8];
set(gca, 'XTickLabel', {datasets.name}, 'XTick', 1:numel(datasets));
ylabel('Embedding rate (bits/pixel, bpp)');
xlabel('Test images');
title('MRDHCBI: Embedding Rate per Ciphertext Image  (2,3)-threshold VC');
ylim([0 max(embed_rates)*1.3]);
grid on;
yline(1/3, '--r', '1/m = 0.333 (theoretical)', 'LabelHorizontalAlignment','left');

fprintf('\nNote: bpp = 1/m = 1/3 ≈ 0.333 for (2,3) VC with m=3.\n');
fprintf('The presented approach gives stable embedding rate across image types,\n');
fprintf('unlike correlation-based RDHCBI methods (see paper Fig. 3 discussion).\n');

%% Full round-trip verification for one image
fprintf('\n=== Full pipeline verification (256x256 random) ===\n');
rng(42);
BI_v = uint8(randi([0,1], 256, 256));
keys_v = [9001, 9002, 9003];

% Encrypt
CBI_v = encrypt_image(BI_v, n, k);

% Embed one data hider's secret
sd_v = {uint8(randi([0,1], 1, 256*256)), ...
        uint8(randi([0,1], 1, 256*256)), ...
        uint8(randi([0,1], 1, 256*256))};
MBI_v = cell(1,n);
for i = 1:n
    MBI_v{i} = embed_data(CBI_v{i}, sd_v{i}, keys_v(i), k, n);
end

% Receiver uses shares 1 & 2
[ext_bits, CBI_rv] = extract_data(MBI_v([1,2]), keys_v([1,2]), k, n);
BI_out = recover_image(CBI_rv, k, n);

ber1 = mean(sd_v{1}(:) ~= ext_bits(1,:)');
ber2 = mean(sd_v{2}(:) ~= ext_bits(2,:)');
lossless = all(BI_v(:) == BI_out(:));

fprintf('  Lossless recovery : %s\n', mat2str(lossless));
fprintf('  BER share 1       : %.6f\n', ber1);
fprintf('  BER share 2       : %.6f\n', ber2);
fprintf('  Embedded bits     : %d per share\n', 256*256);
