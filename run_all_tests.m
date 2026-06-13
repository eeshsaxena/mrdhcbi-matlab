%% RUN_ALL_TESTS  Unit tests and validation for the MRDHCBI implementation.
%
%  Tests cover:
%    T1: VC basis matrix properties (row weights, OR weight thresholds)
%    T2: Encryption correctness (pixel block Hamming weight = W for all shares)
%    T3: Embed -> Extract round-trip (BER = 0 for all shares)
%    T4: Full pipeline lossless recovery (all image types)
%    T5: k-out-of-n property (any 2 of 3 shares recover losslessly)

clear; clc;
addpath(genpath('src'));
addpath(genpath('utils'));

n_pass = 0;
n_fail = 0;

% Helper: print result and update counters
function [p, f] = check(cond, name, p, f)
    if cond
        fprintf('  [PASS] %s\n', name);
        p = p + 1;
    else
        fprintf('  [FAIL] %s\n', name);
        f = f + 1;
    end
end

%% ── T1: Basis matrix properties ─────────────────────────────────────────────
fprintf('\n--- T1: Basis matrix properties ---\n');
[B0, B1, m, W, d] = vc_basis_matrices(2, 3);

[n_pass, n_fail] = check(all(sum(B0,2) == W), ...
    'B0: all row weights equal W', n_pass, n_fail);
[n_pass, n_fail] = check(all(sum(B1,2) == W), ...
    'B1: all row weights equal W', n_pass, n_fail);

% OR of any 2 rows of B0 -> weight < d (white stays recoverable)
or_w = [];
for i=1:3; for j=i+1:3; or_w(end+1)=sum(B0(i,:)|B0(j,:)); end; end
[n_pass, n_fail] = check(all(or_w < d), ...
    'OR of 2 B0 rows weight < d  (white pixel condition)', n_pass, n_fail);

% OR of any 2 rows of B1 -> weight >= d (black stays recoverable)
or_b = [];
for i=1:3; for j=i+1:3; or_b(end+1)=sum(B1(i,:)|B1(j,:)); end; end
[n_pass, n_fail] = check(all(or_b >= d), ...
    'OR of 2 B1 rows weight >= d (black pixel condition)', n_pass, n_fail);

%% ── T2: Encryption correctness ───────────────────────────────────────────────
fprintf('\n--- T2: Encryption block weights ---\n');
rng(0);
BI_t2 = uint8([0 1; 1 0]);
CBI_t2 = encrypt_image(BI_t2, 3, 2);
[~, ~, m2, W2, ~] = vc_basis_matrices(2, 3);

weight_ok = true;
for i = 1:3
    for x = 1:2
        for y = 1:2
            c1 = (y-1)*m2+1; c2 = y*m2;
            if sum(double(CBI_t2{i}(x,c1:c2))) ~= W2
                weight_ok = false;
            end
        end
    end
end
[n_pass, n_fail] = check(weight_ok, ...
    'All ciphertext pixel blocks have Hamming weight W', n_pass, n_fail);

%% ── T3: Embed / Extract round-trip BER = 0 ───────────────────────────────────
fprintf('\n--- T3: Embed/Extract round-trip ---\n');
rng(1);
sz = [32, 32];
BI_t3 = uint8(randi([0,1], sz));
CBI_t3 = encrypt_image(BI_t3, 3, 2);
keys_t3 = [111, 222, 333];
sd_t3 = cell(1,3);
MBI_t3 = cell(1,3);
for i = 1:3
    sd_t3{i} = uint8(randi([0,1], 1, prod(sz)));
    MBI_t3{i} = embed_data(CBI_t3{i}, sd_t3{i}, keys_t3(i), 2, 3);
end

% Test all C(3,2)=3 share combinations
combos = nchoosek(1:3, 2);
for c = 1:size(combos,1)
    idx = combos(c,:);
    [ext, ~] = extract_data(MBI_t3(idx), keys_t3(idx), 2, 3);
    for s = 1:2
        ber = mean(sd_t3{idx(s)}(:) ~= ext(s,:)');
        [n_pass, n_fail] = check(ber == 0, ...
            sprintf('BER=0 for share %d using combo %s', idx(s), mat2str(idx)), ...
            n_pass, n_fail);
    end
end

%% ── T4: Full pipeline lossless recovery ──────────────────────────────────────
fprintf('\n--- T4: Full pipeline lossless recovery ---\n');
rng(2);
for img_type = {'checkerboard', 'random', 'gradient', 'text'}
    BI_t4 = make_test_binary_image(img_type{1}, 32, 32);
    CBI_t4 = encrypt_image(BI_t4, 3, 2);
    keys_t4 = [10, 20, 30];
    MBI_t4 = cell(1,3);
    for i = 1:3
        MBI_t4{i} = embed_data(CBI_t4{i}, uint8(randi([0,1],1,32*32)), keys_t4(i), 2, 3);
    end
    [~, CBI_rec] = extract_data(MBI_t4([1,2]), keys_t4([1,2]), 2, 3);
    BI_rec = recover_image(CBI_rec, 2, 3);
    [n_pass, n_fail] = check(all(BI_t4(:) == BI_rec(:)), ...
        sprintf('Lossless recovery: %s', img_type{1}), n_pass, n_fail);
end

%% ── T5: k-out-of-n (any 2 of 3 suffice) ─────────────────────────────────────
fprintf('\n--- T5: k-out-of-n property ---\n');
rng(3);
BI_t5 = uint8(randi([0,1], 32, 32));
CBI_t5 = encrypt_image(BI_t5, 3, 2);
keys_t5 = [7, 8, 9];
MBI_t5 = cell(1,3);
for i = 1:3
    MBI_t5{i} = embed_data(CBI_t5{i}, uint8(randi([0,1],1,32*32)), keys_t5(i), 2, 3);
end
for c = 1:size(combos,1)
    idx = combos(c,:);
    [~, CBI_rec] = extract_data(MBI_t5(idx), keys_t5(idx), 2, 3);
    BI_rec = recover_image(CBI_rec, 2, 3);
    [n_pass, n_fail] = check(all(BI_t5(:)==BI_rec(:)), ...
        sprintf('Shares %s recover losslessly', mat2str(idx)), n_pass, n_fail);
end

%% ── T6: Edge cases ────────────────────────────────────────────────────────────
fprintf('\n--- T6: Edge cases ---\n');
% All-white image
rng(4);
BI_white = uint8(zeros(16,16));
CBI_w = encrypt_image(BI_white, 3, 2);
MBI_w = cell(1,3);
for i=1:3; MBI_w{i} = embed_data(CBI_w{i}, uint8(randi([0,1],1,256)), i*10, 2, 3); end
[~, CBI_rw] = extract_data(MBI_w([1,2]), [10,20], 2, 3);
BI_rw = recover_image(CBI_rw, 2, 3);
[n_pass, n_fail] = check(all(BI_rw(:)==0), 'All-white image recovered', n_pass, n_fail);

% All-black image
BI_black = uint8(ones(16,16));
CBI_b = encrypt_image(BI_black, 3, 2);
MBI_b = cell(1,3);
for i=1:3; MBI_b{i} = embed_data(CBI_b{i}, uint8(randi([0,1],1,256)), i*10, 2, 3); end
[~, CBI_rb] = extract_data(MBI_b([1,2]), [10,20], 2, 3);
BI_rb = recover_image(CBI_rb, 2, 3);
[n_pass, n_fail] = check(all(BI_rb(:)==1), 'All-black image recovered', n_pass, n_fail);

%% ── Summary ───────────────────────────────────────────────────────────────────
fprintf('\n========================================\n');
fprintf('  Results: %d passed, %d failed\n', n_pass, n_fail);
fprintf('========================================\n');
if n_fail == 0
    fprintf('  ALL TESTS PASSED\n');
else
    fprintf('  SOME TESTS FAILED — check output above\n');
end
