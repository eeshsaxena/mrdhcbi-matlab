function [secret_bits, CBI_restored] = extract_data(MBI_set, embed_keys, k, n)
% EXTRACT_DATA  Extract secret data and restore ciphertext images (Eq. 6-7).
%
%   [secret_bits, CBI_restored] = extract_data(MBI_set, embed_keys, k, n)
%
%   MBI_set      : 1 x s cell array of marked ciphertext binary images
%                  (s >= k shares collected by the receiver)
%   embed_keys   : 1 x s vector of embedding keys (one per share)
%   k, n         : VC threshold parameters
%
%   secret_bits  : s x (X*Y) uint8 matrix; row s = bits from share s
%   CBI_restored : 1 x s cell array of restored ciphertext binary images
%
%   Algorithm (Section II-C, Eq. 6-7):
%     For each marked pixel block MBI^{s*}_{xy}:
%       H = Hamming weight of block
%       if H != W  ->  rd = 0  (first pixel was flipped during embedding)
%                       restore: flip first pixel back  (Eq. 7)
%       if H == W  ->  rd = 1  (block unchanged during embedding)
%     secret bit = rd XOR PRN(embed_key)
%
%   Indexing note: pixel (x,y) maps to flat index p = (y-1)*X + x
%   (column-major), matching the convention in embed_data.

[~, ~, m, W, ~] = vc_basis_matrices(k, n);
num_shares = numel(MBI_set);

[X, Ym] = size(MBI_set{1});
Y = Ym / m;
total_pixels = X * Y;

secret_bits  = zeros(num_shares, total_pixels, 'uint8');
CBI_restored = cell(1, num_shares);

for s = 1:num_shares
    MBI   = MBI_set{s};
    CBI_r = MBI;
    rd_vec = ones(1, total_pixels, 'uint8'); % default: rd=1 (no change)

    for x = 1:X
        for y = 1:Y
            c1 = (y - 1) * m + 1;
            c2 = y * m;
            H  = sum(double(MBI(x, c1:c2)));
            p  = (y - 1) * X + x;  % column-major — must match embed_data

            if H ~= W
                % First pixel was flipped during embedding -> rd = 0 (Eq. 6)
                rd_vec(p) = 0;
                % Restore: flip first element back (Eq. 7)
                CBI_r(x, c1) = 1 - MBI(x, c1);
            else
                rd_vec(p) = 1;
            end
        end
    end

    % Recover secret bits: secret = rd XOR PRN
    rng(embed_keys(s), 'twister');
    prn = uint8(randi([0, 1], 1, total_pixels));
    secret_bits(s, :) = bitxor(rd_vec, prn);
    CBI_restored{s}   = CBI_r;
end
end
