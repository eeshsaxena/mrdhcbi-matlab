function MBI = embed_data(CBI_i, secret_bits, embed_key, k, n)
% EMBED_DATA  Embed secret data into one ciphertext binary image (Eq. 5).
%
%   MBI = embed_data(CBI_i, secret_bits, embed_key, k, n)
%
%   CBI_i       : X x (Y*m) ciphertext binary image for one data hider
%   secret_bits : binary column/row vector of secret bits (length <= X*Y)
%   embed_key   : scalar integer seed for the pseudorandom number generator
%   k, n        : VC threshold parameters (determines m)
%
%   MBI : X x (Y*m) marked ciphertext binary image
%
%   Algorithm (Section II-B):
%     1. Generate pseudorandom binary sequence PRN from embed_key.
%     2. rd = secret_bits XOR PRN  (converts secret to embedding vector)
%     3. For each pixel block at position (x,y):
%          if rd_{xy} == 0: flip the first element of the block
%          else:            leave block unchanged
%
%   Embedding capacity: X*Y bits (one bit per original image pixel).
%
%   Indexing note: rd is stored in MATLAB column-major order so that
%   pixel (x,y) maps to rd index p = (y-1)*X + x. extract_data uses
%   the same convention, ensuring round-trip consistency.

[X, Ym] = size(CBI_i);
[~, ~, m, ~, ~] = vc_basis_matrices(k, n);
Y = Ym / m;
total_pixels = X * Y;

if numel(secret_bits) > total_pixels
    error('secret_bits length (%d) exceeds capacity (%d).', numel(secret_bits), total_pixels);
end

% Pad secret bits to full capacity with zeros
sd = zeros(1, total_pixels, 'uint8');
sd(1:numel(secret_bits)) = uint8(secret_bits(:)');

% Pseudorandom sequence keyed to embed_key
rng(embed_key, 'twister');
prn = uint8(randi([0, 1], 1, total_pixels));

% rd = secret XOR pseudorandom sequence (1 x X*Y, column-major)
rd = bitxor(sd, prn);

% Data embedding — column-major pixel index p = (y-1)*X + x
MBI = CBI_i;
for x = 1:X
    for y = 1:Y
        p  = (y - 1) * X + x;
        c1 = (y - 1) * m + 1;
        if rd(p) == 0
            % Flip first element of pixel block (Eq. 5)
            MBI(x, c1) = 1 - CBI_i(x, c1);
        end
    end
end
end
