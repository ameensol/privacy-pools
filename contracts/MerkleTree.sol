// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Poseidon {
    function poseidon(uint256[2] calldata) external pure returns (uint);
}

contract MerkleTree {

    error MerkleTreeCapacity();

    Poseidon public hasher;
    mapping (uint => uint) public zeros;
    mapping (uint => uint) public filledSubtrees;
    mapping (uint => uint) public roots;
    uint public constant ROOTS_CAPACITY = 30;
    uint public currentRootIndex;
    uint public nextLeafIndex;

    constructor(address poseidon, uint zeroValue) {
        hasher = Poseidon(poseidon);
        for (uint i; i < 20;) {
            zeros[i] = zeroValue;
            filledSubtrees[i] = zeroValue;
            zeroValue = hasher.poseidon([zeroValue, zeroValue]);
            unchecked { ++i; }
        }
        roots[0] = zeroValue;
    }

    /*
        Tree with 2**3 leaves

                      R0
              x               x
          y       y       y       y
        z   z   z   z   z   z   z   z
    */

    function getLatestRoot() public view returns (uint) {
        return roots[currentRootIndex];
    }

    function isKnownRoot(uint root) public view returns (bool) {
        if (root == 0) return false;
        uint checkIndex = currentRootIndex;
        for (uint i; i < ROOTS_CAPACITY;) {
            if (root == roots[checkIndex]) return true;
            if (checkIndex == 0) checkIndex = ROOTS_CAPACITY;
            unchecked {
                ++i;
                --checkIndex;
            }
        }
        return false;
    }

    function insert(uint leaf) internal returns (uint) {
        if (nextLeafIndex == 1 << 20) revert MerkleTreeCapacity();
        uint currentLeafIndex = nextLeafIndex;
        uint currentHash = leaf;
        uint left;
        uint right;
        for (uint i; i < 20;) {
            if (currentLeafIndex % 2 == 0) {
                left = currentHash;
                right = zeros[i];
                filledSubtrees[i] = currentHash;
            } else {
                left = filledSubtrees[i];
                right = currentHash;
            }
            currentHash = hasher.poseidon([left, right]);
            unchecked {
                ++i;
                currentLeafIndex >>= 1;
            }
        }
        unchecked {
            currentRootIndex = addmod(currentRootIndex, 1, ROOTS_CAPACITY);
            roots[currentRootIndex] = currentHash;
            return nextLeafIndex++;
        }
    }

    function testInsert(uint leaf) public returns (uint) {
        if (nextLeafIndex == 1 << 20) revert MerkleTreeCapacity();
        uint currentLeafIndex = nextLeafIndex;
        uint currentHash = leaf;
        uint left;
        uint right;
        for (uint i; i < 20;) {
            if (currentLeafIndex % 2 == 0) {
                left = currentHash;
                right = zeros[i];
                filledSubtrees[i] = currentHash;
            } else {
                left = filledSubtrees[i];
                right = currentHash;
            }
            currentHash = hasher.poseidon([left, right]);
            unchecked {
                ++i;
                currentLeafIndex >>= 1;
            }
        }
        unchecked {
            currentRootIndex = addmod(currentRootIndex, 1, ROOTS_CAPACITY);
            roots[currentRootIndex] = currentHash;
            return nextLeafIndex++;
        }
    }
}