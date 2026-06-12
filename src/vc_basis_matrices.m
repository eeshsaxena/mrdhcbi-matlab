function [B0, B1, m, W, d] = vc_basis_matrices(k, n)
% VC_BASIS_MATRICES  Returns (k,n) visual cryptography basis matrices.
%
%   [B0, B1, m, W, d] = vc_basis_matrices(k, n)
%
%   Currently supports (2,3) threshold only (as used in the paper).
%   B0: n x m basis matrix for white pixels (all rows identical, weight W)
%   B1: n x m basis matrix for black pixels (rows differ, weight W)
%   m : number of columns per pixel block
%   W : Hamming weight of every row in both B0 and B1
%   d : recovery threshold (u < d <= v)
%
%   For (2,3): B0 rows = [1 0 0], B1 = identity(3)
%   White OR of any 2 rows -> weight 1 (=u)
%   Black OR of any 2 rows -> weight 2 (=v)
%   Threshold d = 1.5

if k == 2 && n == 3
    m = 3;
    W = 1;
    % White pixel basis: all rows identical -> OR of any k rows has weight W
    B0 = [1 0 0;
          1 0 0;
          1 0 0];
    % Black pixel basis: permutation matrix -> OR of any k rows has weight k
    B1 = [1 0 0;
          0 1 0;
          0 0 1];
    % u = OR weight of k rows from B0 = 1
    % v = OR weight of k rows from B1 = 2
    d = 1.5; % threshold: pixel=1 (black) when H(OBI) >= d
else
    error('Only (2,3) threshold VC is implemented. Got k=%d, n=%d.', k, n);
end
end
