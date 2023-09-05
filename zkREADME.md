## ZK Scheme
See [withdraw_from_subset.circom](./circuits/withdraw_from_subset.circom) for the circom implementation of this scheme. I'm not the best with math notation so it might make more sense to read the actual circom file.
### **Definitions**

$$
\begin{aligned}
\psi &= \text{poseidon hash function}\\
\kappa_q &= \text{keccak256 hash function, mod q if necessary}\\
R_{C'} &= \text{Merkle root of all deposits}\\
M_{C'} &= \text{array of elements that form a merkle proof in }R_{C'}\\
R_a &= \text{merkle root of some subset of }R_{C'}\\
M_a &= \text{array of elements that form a merkle proof in }R_a\\
A &= \text{asset public metadata: }\kappa_q(\text{token, denomination})\\
W &= \text{withdraw public metadata: }\kappa_q(\text{recipient, relayer, fee})\\
E &= \text{expected value in the subset: }\kappa_q(\text{"allowed"})\\
s&= \text{crytographically secure random value}\\
C &= \text{raw commitment: }\psi(s)\\
C' &= \text{stamped commitment: }\psi(C, A)\\
C'_i &= \text{$i$-th commitment in } R_{C'}\\
N_i &= \text{nullifier for $C'_i$: }\psi(s, 1, i)\\
\end{aligned}
$$

### **Prove**

$$
\begin{aligned}
C &= \psi(s)\\
C' &= \psi(C, A)\\
N_i &= \psi(s, 1, i)\\
R_{C'} &= \text{VerifyMerkleProof}(C', i, M_{C'})\\
R_{a} &= \text{VerifyMerkleProof}(E, i, M_a)\\
W^2 &= W \cdot W
\end{aligned}
$$

**Private Inputs**
1. $s$
2. $i$
3. $M_{C'}$
4. $M_a$

**Public Inputs**

1. $R_{C'}$
2. $R_a$
3. $N_i$
4. $A$
5. $W$

# To Do
1. Verify that this design does what it claims to do.
2. Solidity implementation & unit tests
3. Subset compression and decompression algorithms
4. Contracts/library for posting/retrieving data on-chain
5. Interface and testnet deployment
