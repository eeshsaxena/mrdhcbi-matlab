function BI_recovered = recover_image(CBI_restored, k, n)
% RECOVER_IMAGE  Recover the original binary image from k restored ciphertext
%                binary images using Boolean OR and Hamming threshold (Eq. 8).
%
%   BI_recovered = recover_image(CBI_restored, k, n)
%
%   CBI_restored : 1 x s cell array of restored ciphertext binary images
%                  (s >= k; any k suffice for perfect recovery)
%   k, n         : VC threshold parameters
%
%   BI_recovered : X x Y binary image (0 = white, 1 = black)
%
%   Algorithm (Section II-C):
%     1. Boolean OR all s pixel blocks at each position -> OBI_{xy}
%     2. BI_{xy} = 0 if H(OBI_{xy}) < d
%               = 1 if H(OBI_{xy}) >= d
%     where d is the Hamming threshold between u (white OR weight) and
%     v (black OR weight).

[~, ~, m, ~, d] = vc_basis_matrices(k, n);
num_shares = numel(CBI_restored);

[X, Ym] = size(CBI_restored{1});
Y = Ym / m;

BI_recovered = zeros(X, Y, 'uint8');

for x = 1:X
    for y = 1:Y
        c1 = (y - 1) * m + 1;
        c2 = y * m;

        % Boolean OR across all available shares
        obi = zeros(1, m);
        for s = 1:num_shares
            obi = obi | double(CBI_restored{s}(x, c1:c2));
        end

        % Threshold decision (Eq. 8)
        if sum(obi) >= d
            BI_recovered(x, y) = 1;
        else
            BI_recovered(x, y) = 0;
        end
    end
end
end
