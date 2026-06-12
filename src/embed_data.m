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

[X, Ym] = size(CBI_i);
[~, ~, m, ~, ~] = vc_basis_matrices(k, n);
Y = Ym / m;
total_pixels = X * Y;

% Validate secret data length
if numel(secret_bits) > total_pixels
    error('secret_bits length (%d) exceeds capacity (%d).', numel(secret_bits), total_pixels);
end

% Pad secret bits to full capacity with zeros
sd = zeros(1, total_pixels, 'uint8');
sd(1:numel(secret_bits)) = uint8(secret_bits(:)');

% Pseudorandom sequence (Eq. in Section II-B)
rng(embed_key, 'twister');
prn = uint8(randi([0, 1], 1, total_pixels));

% rd = secret XOR pseudorandom sequence
rd = bitxor(sd, prn);          % 1 x (X*Y) vector
rd_mat = reshape(rd, X, Y);   % X x Y matrix

% Data embedding
MBI = CBI_i;
for x = 1:X
    for y = 1:Y
        if rd_mat(x, y) == 0
            % Flip first element of pixel block (Eq. 5)
            c1 = (y - 1) * m + 1;
            MBI(x, c1) = 1 - CBI_i(x, c1);
        end
    end
end
end
