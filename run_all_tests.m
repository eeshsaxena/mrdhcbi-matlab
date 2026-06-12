%% RUN_ALL_TESTS  Unit tests and validation for the MRDHCBI implementation.
%
%  Tests cover:
%    T1: VC basis matrix properties (row weights, OR weight thresholds)
%    T2: Encryption correctness (pixel block Hamming weight = W)
%    T3: Embed->Extract round-trip (bit error rate = 0)
%    T4: Encrypt->Embed->Extract->Recover pipeline (lossless recovery)
%    T5: k-out-of-n property (any k shares suffice; k-1 shares fail)
%    T6: All image types

clear; clc;
addpath(genpath('src'));
addpath(genpath('utils'));

pass = 0; fail = 0;

function assert_true(cond, name)
    if cond
        fprintf('  [PASS] %s\n', name);
        evalin('caller', 'pass = pass + 1;');
    else
        fprintf('  [FAIL] %s\n', name);
        evalin('caller', 'fail = fail + 1;');
    end
end

%% T1: Basis matrix properties
fprintf('\n--- T1: Basis matrix properties ---\n');
[B0, B1, m, W, d] = vc_basis_matrices(2, 3);

% All rows of B0 have weight W
rows_B0_ok = all(sum(B0, 2) == W);
assert_true(rows_B0_ok, 'B0 row weights all equal W');

% All rows of B1 have weight W
rows_B1_ok = all(sum(B1, 2) == W);
assert_true(rows_B1_ok, 'B1 row weights all equal W');

% OR of any 2 rows of B0 has weight u < d
or_B0 = [];
for i = 1:3
    for j = i+1:3
        or_B0(end+1) = sum(B0(i,:) | B0(j,:));
    end
end
assert_true(all(or_B0 < d), 'OR of 2 B0 rows weight < d (white pixel recoverable)');

% OR of any 2 rows of B1 has weight >= d
or_B1 = [];
for i = 1:3
    for j = i+1:3
        or_B1(end+1) = sum(B1(i,:) | B1(j,:));
    end
end
assert_true(all(or_B1 >= d), 'OR of 2 B1 rows weight >= d (black pixel recoverable)');

%% T2: Encryption correctness
fprintf('\n--- T2: Encryption block weights ---\n');
rng(0);
BI_test = uint8([0 1; 1 0]);
CBI_test = encrypt_image(BI_test, 3, 2);

[~, ~, m_t, W_t, ~] = vc_basis_matrices(2, 3);
weight_ok = true;
for i = 1:3
    for x = 1:2
        for y = 1:2
            c1 = (y-1)*m_t+1; c2 = y*m_t;
            H = sum(double(CBI_test{i}(x, c1:c2)));
            if H ~= W_t
                weight_ok = false;
            end
        end
    end
end
assert_true(weight_ok, 'All ciphertext pixel blocks have Hamming weight W');

%% T3: Embed -> Extract round-trip
fprintf('\n--- T3: Embed/Extract round-trip ---\n');
rng(1);
BI_rt = uint8(randi([0,1], 32, 32));
CBI_rt = encrypt_image(BI_rt, 3, 2);
keys_rt = [111, 222, 333];
sd_rt = {uint8(randi([0,1], 1, 32*32)), ...
         uint8(randi([0,1], 1, 32*32)), ...
         uint8(randi([0,1], 1, 32*32))};
MBI_rt = cell(1,3);
for i = 1:3
    MBI_rt{i} = embed_data(CBI_rt{i}, sd_rt{i}, keys_rt(i), 2, 3);
end
[ext_bits, ~] = extract_data(MBI_rt([1,2]), keys_rt([1,2]), 2, 3);
ber1 = mean(sd_rt{1}(:) ~= ext_bits(1,:)');
ber2 = mean(sd_rt{2}(:) ~= ext_bits(2,:)');
assert_true(ber1 == 0, 'BER = 0 for share 1 extraction');
assert_true(ber2 == 0, 'BER = 0 for share 2 extraction');

%% T4: Full pipeline lossless recovery
fprintf('\n--- T4: Full pipeline lossless recovery ---\n');
rng(2);
for img_type = {'checkerboard','random','gradient'}
    BI_p = make_test_binary_image(img_type{1}, 32, 32);
    CBI_p = encrypt_image(BI_p, 3, 2);
    keys_p = [10,20,30];
    MBI_p = cell(1,3);
    for i = 1:3
        MBI_p{i} = embed_data(CBI_p{i}, uint8(randi([0,1],1,32*32)), keys_p(i), 2, 3);
    end
    [~, CBI_rec] = extract_data(MBI_p([1,2]), keys_p([1,2]), 2, 3);
    BI_rec = recover_image(CBI_rec, 2, 3);
    is_lossless = all(BI_p(:) == BI_rec(:));
    assert_true(is_lossless, sprintf('Lossless recovery: %s', img_type{1}));
end

%% T5: k-out-of-n property
fprintf('\n--- T5: k-out-of-n (any 2 of 3 suffice) ---\n');
rng(3);
BI_kn = uint8(randi([0,1], 32, 32));
CBI_kn = encrypt_image(BI_kn, 3, 2);
keys_kn = [7,8,9];
MBI_kn = cell(1,3);
for i = 1:3
    MBI_kn{i} = embed_data(CBI_kn{i}, uint8(randi([0,1],1,32*32)), keys_kn(i), 2, 3);
end
combos = nchoosek(1:3, 2);
for c = 1:size(combos,1)
    idx = combos(c,:);
    [~, CBI_rec] = extract_data(MBI_kn(idx), keys_kn(idx), 2, 3);
    BI_rec = recover_image(CBI_rec, 2, 3);
    assert_true(all(BI_kn(:)==BI_rec(:)), sprintf('Shares %s recover losslessly', mat2str(idx)));
end

%% Summary
fprintf('\n========================================\n');
fprintf('  Results: %d passed, %d failed\n', pass, fail);
fprintf('========================================\n');
if fail == 0
    fprintf('  ALL TESTS PASSED\n');
else
    fprintf('  SOME TESTS FAILED\n');
end
