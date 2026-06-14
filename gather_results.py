"""Numeric results harness mirroring the MATLAB MRDHCBI implementation
(Chen et al., IEEE SPL 2025) for the implementation report. No MATLAB on
this machine, so this mirrors src/*.m exactly and prints the report tables."""
import numpy as np

# (2,3) VC basis matrices (vc_basis_matrices.m)
B0 = np.array([[1,0,0],[1,0,0],[1,0,0]])
B1 = np.array([[1,0,0],[0,1,0],[0,0,1]])
m, W, d = 3, 1, 1.5

def encrypt(BI, n, seed):
    rng = np.random.default_rng(seed)
    X, Y = BI.shape
    CBI = [np.zeros((X, Y*m), dtype=int) for _ in range(n)]
    for x in range(X):
        for y in range(Y):
            B = B0 if BI[x,y]==0 else B1
            perm = rng.permutation(m)
            Bp = B[:, perm]
            for i in range(n):
                CBI[i][x, y*m:(y+1)*m] = Bp[i]
    return CBI

def embed(CBI_i, secret, key):
    X, Ym = CBI_i.shape; Y = Ym//m; tot = X*Y
    rng = np.random.default_rng(key)
    prn = rng.integers(0,2,tot)
    sd = np.zeros(tot, dtype=int); sd[:len(secret)] = secret
    rd = sd ^ prn
    M = CBI_i.copy()
    for x in range(X):
        for y in range(Y):
            p = y*X + x
            if rd[p]==0:
                M[x, y*m] = 1 - CBI_i[x, y*m]
    return M

def extract(MBIs, keys):
    s = len(MBIs); X, Ym = MBIs[0].shape; Y = Ym//m; tot = X*Y
    secrets=[]; restored=[]
    for si in range(s):
        MBI = MBIs[si]; CBIr = MBI.copy(); rd = np.ones(tot, dtype=int)
        for x in range(X):
            for y in range(Y):
                H = MBI[x, y*m:(y+1)*m].sum()
                p = y*X+x
                if H != W:
                    rd[p]=0; CBIr[x, y*m]=1-MBI[x, y*m]
        rng=np.random.default_rng(keys[si]); prn=rng.integers(0,2,tot)
        secrets.append(rd ^ prn); restored.append(CBIr)
    return secrets, restored

def recover(CBIr):
    X, Ym = CBIr[0].shape; Y=Ym//m
    BI = np.zeros((X,Y),dtype=int)
    for x in range(X):
        for y in range(Y):
            obi=np.zeros(m,dtype=int)
            for s in CBIr: obi |= s[x, y*m:(y+1)*m]
            BI[x,y] = 1 if obi.sum()>=d else 0
    return BI

def entropy_bits(arr):
    # binary share entropy over {0,1}
    p1 = arr.mean(); p0 = 1-p1
    h = 0
    for p in (p0,p1):
        if p>0: h -= p*np.log2(p)
    return h

print("=== MRDHCBI numeric results (2,3)-threshold VC ===\n")
print("Basis matrix properties:")
print(f"  B0 row weights = {B0.sum(1).tolist()} (all == W={W})")
print(f"  B1 row weights = {B1.sum(1).tolist()} (all == W={W})")
orw=[ (B0[i]|B0[j]).sum() for i in range(3) for j in range(i+1,3)]
orb=[ (B1[i]|B1[j]).sum() for i in range(3) for j in range(i+1,3)]
print(f"  OR of 2 white(B0) rows weights = {orw} (all < d={d})")
print(f"  OR of 2 black(B1) rows weights = {orb} (all >= d={d})")

print("\nReversibility + capacity over image types (64x64, k=2,n=3):")
print(f"{'ImageType':<14}{'Lossless':<10}{'BER(sh1)':<10}{'BER(sh2)':<10}{'bpp':<8}")
rng = np.random.default_rng(7)
def make(kind, X, Y):
    if kind=='checkerboard':
        r,c=np.meshgrid(range(X),range(Y),indexing='ij'); return ((r//8+c//8)%2).astype(int)
    if kind=='random': return rng.integers(0,2,(X,Y))
    if kind=='gradient':
        r,c=np.meshgrid(range(X),range(Y),indexing='ij'); return (c>Y/2).astype(int)
for kind in ['checkerboard','random','gradient']:
    BI=make(kind,64,64); n=3; keys=[101,202,303]
    CBI=encrypt(BI,n,seed=1)
    secs=[rng.integers(0,2,64*64) for _ in range(n)]
    MBI=[embed(CBI[i],secs[i],keys[i]) for i in range(n)]
    es,cr=extract([MBI[0],MBI[1]],[keys[0],keys[1]])
    BIrec=recover(cr)
    loss = np.array_equal(BI,BIrec)
    ber1=(secs[0]!=es[0]).mean(); ber2=(secs[1]!=es[1]).mean()
    bpp = (64*64)/(64*64*m)
    print(f"{kind:<14}{str(loss):<10}{ber1:<10.4f}{ber2:<10.4f}{bpp:<8.4f}")

print("\nk-out-of-n (random 64x64): any 2 of 3 shares")
BI=make('random',64,64); keys=[7,8,9]; n=3
CBI=encrypt(BI,n,seed=2); secs=[rng.integers(0,2,64*64) for _ in range(n)]
MBI=[embed(CBI[i],secs[i],keys[i]) for i in range(n)]
import itertools
for combo in itertools.combinations(range(3),2):
    es,cr=extract([MBI[combo[0]],MBI[combo[1]]],[keys[combo[0]],keys[combo[1]]])
    print(f"  shares {tuple(c+1 for c in combo)}: lossless={np.array_equal(BI,recover(cr))}")

print("\nShare entropy (random image, ideal=1.0 bit for binary):")
sh_ent=[entropy_bits(c) for c in CBI]
print(f"  original entropy = {entropy_bits(BI):.4f}")
print(f"  share entropies  = {[round(e,4) for e in sh_ent]}")
