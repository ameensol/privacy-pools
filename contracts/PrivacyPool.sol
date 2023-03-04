// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./verifiers/withdraw_from_subset_verifier.sol";
import "./MerkleTree.sol";

contract PrivacyPool is ReentrancyGuard, MerkleTree, WithdrawFromSubsetVerifier {
    using ProofLib for bytes;
    using SafeERC20 for IERC20;

    event Deposit(
        uint indexed commitment,
        address indexed token,
        uint amount,
        uint leafIndex,
        uint timestamp
    );
    event Withdrawal(
        address recipient,
        address indexed relayer,
        uint indexed subsetRoot,
        uint nullifier,
        uint fee
    );

    error FeeExceedsAmount();
    error InvalidZKProof();
    error MsgValueInvalid();
    error NoteAlreadySpent();
    error UnknownRoot();
    mapping (uint => bool) public nullifiers;

    constructor(address poseidon) MerkleTree(poseidon, bytes("empty").snarkHash()) {}

    function deposit(uint commitment, address token, uint amount)
        public
        payable
        nonReentrant
        returns (uint)
    {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if (msg.value != amount) revert MsgValueInvalid();
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
        uint assetMetadata = abi.encode(token, amount).snarkHash();
        uint leaf = hasher.poseidon([commitment, assetMetadata]);
        uint leafIndex = insert(leaf);
        emit Deposit(commitment, token, amount, leafIndex, block.timestamp);
        return leafIndex;
    }

    function withdraw(
        uint[8] calldata flatProof,
        uint root,
        uint subsetRoot,
        uint nullifier,
        address token,
        uint amount,
        address recipient,
        uint refund,
        address relayer,
        uint fee
    )
        public
        payable
        nonReentrant
        returns (bool)
    {
        if (nullifiers[nullifier]) revert NoteAlreadySpent();
        if (!isKnownRoot(root)) revert UnknownRoot();
        if (fee > amount) revert FeeExceedsAmount();
        uint assetMetadata = abi.encode(token, amount).snarkHash();
        uint withdrawMetadata = abi.encode(recipient, refund, relayer, fee).snarkHash();
        if (!_verifyWithdrawFromSubsetProof(
            flatProof,
            root,
            subsetRoot,
            nullifier,
            assetMetadata,
            withdrawMetadata
        )) revert InvalidZKProof();
        nullifiers[nullifier] = true;
        if (refund > 0) {
            payable(recipient).transfer(refund);
        }
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if (msg.value != (refund+amount)) revert MsgValueInvalid();
            if (fee > 0) {
                payable(recipient).transfer(amount - fee);
                payable(relayer).transfer(fee);
            } else {
                payable(recipient).transfer(amount);
            }
        } else {
            if (msg.value != refund) revert MsgValueInvalid();
            if (fee > 0) {
                IERC20(token).safeTransfer(recipient, amount - fee);
                IERC20(token).safeTransfer(relayer, fee);
            } else {
                IERC20(token).safeTransfer(recipient, amount);
            }
        }
        return true;
    }
}