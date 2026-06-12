function CBI = encrypt_image(BI, n, k)
% ENCRYPT_IMAGE  Encrypt a binary image into n ciphertext binary images
%                using (k,n) threshold visual cryptography (Eq. 1-4).
%
%   CBI = encrypt_image(BI, n, k)
%
%   BI  : X x Y binary image (0 = white, 1 = black)
%   n   : number of ciphertext shares to generate (data hiders)
%   k   : reconstruction threshold (2 <= k <= n)
%
%   CBI : 1 x n cell array; CBI{i} is an X x (Y*m) uint8 binary matrix
%         for data hider i, where m = columns in basis matrix.
%
%   Algorithm (Section II-A):
%     For each pixel BI_{xy} = t in {0,1}:
%       1. Randomly select a column permutation of B^t to form an n x m matrix.
%       2. Row i of the permuted matrix becomes CBI^i_{xy} (the i-th pixel block).
%
%   See also: embed_data, extract_data, recover_image

[X, Y] = size(BI);
[B0, B1, m, ~, ~] = vc_basis_matrices(k, n);

% Preallocate ciphertext images
CBI = cell(1, n);
for i = 1:n
    CBI{i} = uint8(zeros(X, Y * m));
end

% Encrypt pixel by pixel
for x = 1:X
    for y = 1:Y
        if BI(x, y) == 0
            B = B0;
        else
            B = B1;
        end

        % Random column permutation (Eq. 2-3)
        perm = randperm(m);
        B_perm = B(:, perm);  % n x m

        % Distribute rows to each share
        c1 = (y - 1) * m + 1;
        c2 = y * m;
        for i = 1:n
            CBI{i}(x, c1:c2) = B_perm(i, :);
        end
    end
end
end
