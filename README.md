# MRDHCBI — MATLAB Implementation

MATLAB implementation of:

> B. Chen, J. Yu, B. Feng, W. Lu, J. Cai,  
> **"Multi-Party Reversible Data Hiding in Ciphertext Binary Images Based on Visual Cryptography"**  
> *IEEE Signal Processing Letters*, vol. 32, pp. 1560–1564, 2025.  
> DOI: 10.1109/LSP.2025.3557273

---

## Overview

The MRDHCBI scheme lets multiple data hiders independently embed secret data into ciphertext shares of a binary image. The original image is perfectly recoverable from any `k` of the `n` marked shares (k-out-of-n threshold).

### Three-stage pipeline

```
Owner ──────────────────────────────────────────────────────────────┐
  Binary image ──[Visual Cryptography]──> n Ciphertext Binary Images │
                                          (CBI^1 … CBI^n)           │
                                               │                     │
Data Hider i ──────────────────────────────────┘                    │
  CBI^i + secret data_i ──[embed_data]──> Marked CBI^i (MBI^i)     │
                                               │                     │
Receiver (collects any k MBI) ────────────────┘                     │
  k MBI ──[extract_data]──> secret bits + restored CBI              │
       ──[recover_image]──> Original binary image (lossless)        │
```

---

## Repo Structure

```
mrdhcbi-matlab/
├── main_demo.m              # Full pipeline demonstration
├── run_all_tests.m          # Unit tests (T1–T5)
├── src/
│   ├── vc_basis_matrices.m  # (k,n) VC basis matrices B^0, B^1
│   ├── encrypt_image.m      # Stage 1: binary image encryption (Eq. 1–4)
│   ├── embed_data.m         # Stage 2: data embedding per hider (Eq. 5)
│   ├── extract_data.m       # Stage 3: data extraction (Eq. 6–7)
│   └── recover_image.m      # Stage 3: binary image recovery (Eq. 8)
└── utils/
    ├── compute_metrics.m    # BER, pixel error rate, embedding rate
    └── make_test_binary_image.m  # Synthetic test image generator
```

---

## Quick Start

```matlab
addpath(genpath('src'));
addpath(genpath('utils'));

k = 2; n = 3;            % (2,3) threshold — paper's experiment setting
BI = imread('your_binary_image.png');   % must be uint8 with values 0 or 1

% --- Owner ---
CBI = encrypt_image(BI, n, k);          % 3 ciphertext shares

% --- Data Hiders (independent) ---
keys = [1001, 2002, 3003];
MBI  = cell(1, n);
for i = 1:n
    secret = uint8(randi([0,1], 1, numel(BI)));
    MBI{i} = embed_data(CBI{i}, secret, keys(i), k, n);
end

% --- Receiver (any 2 shares suffice) ---
[bits, CBI_r] = extract_data(MBI([1,2]), keys([1,2]), k, n);
BI_out        = recover_image(CBI_r, k, n);

isequal(BI, BI_out)   % should be 1 (lossless)
```

Run the full demo:
```matlab
main_demo
```

Run unit tests:
```matlab
run_all_tests
```

---

## Algorithm Details

### Visual Cryptography (k,n) — Eq. 1–4

Basis matrices `B^0` (white) and `B^1` (black) share the same row Hamming weight `W`.  
For **(2,3)** with `m = 3` columns:

| Matrix | Row content | Row weight W |
|--------|-------------|-------------|
| `B^0`  | `[1 0 0]` (all rows identical) | 1 |
| `B^1`  | `[1 0 0; 0 1 0; 0 0 1]` (identity) | 1 |

For each pixel `BI_{xy} = t`:
- Randomly pick a column permutation `π` of `B^t`
- Row `i` of the permuted matrix → `CBI^i_{xy}` (1×m pixel block)

### Data Embedding — Eq. 5

```
rd = secret_bit XOR PRNG(embed_key)

if rd == 0:  flip MBI[x, c1]   (first element of pixel block)
else:        MBI = CBI          (no change)
```

### Data Extraction — Eq. 6–7

```
H = Hamming weight of MBI pixel block

if H != W:  rd = 0  →  flip first element back to restore CBI
if H == W:  rd = 1  →  CBI unchanged

secret_bit = rd XOR PRNG(embed_key)
```

### Image Recovery — Eq. 8

```
OBI_{xy} = Boolean OR of k restored pixel blocks
BI_{xy}  = 1 if H(OBI_{xy}) >= d   else 0
```

For (2,3): `d = 1.5`, `H_white_OR = 1`, `H_black_OR = 2`.

---

## Embedding Capacity

Each data hider embeds **1 bit per original pixel**.  
For a `256×256` image: **65 536 bits** per hider (matches paper, Section III-A).

---

## Requirements

- MATLAB R2019b or later (uses `randi`, `rng`, `nchoosek`)
- No additional toolboxes required

---

## Reference

```bibtex
@article{chen2025mrdhcbi,
  author  = {Chen, Bing and Yu, Jingkun and Feng, Bingwen and Lu, Wei and Cai, Jun},
  title   = {Multi-Party Reversible Data Hiding in Ciphertext Binary Images
             Based on Visual Cryptography},
  journal = {IEEE Signal Processing Letters},
  year    = {2025},
  volume  = {32},
  pages   = {1560--1564},
  doi     = {10.1109/LSP.2025.3557273}
}
```
