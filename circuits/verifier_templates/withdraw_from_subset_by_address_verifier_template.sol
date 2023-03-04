// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ProofLib.sol";

contract WithdrawFromSubsetByAddressVerifier {
    using ProofLib for ProofLib.G1Point;
    using ProofLib for ProofLib.G2Point;

    function withdrawFromSubsetByAddressVerifyingKey() internal pure returns (ProofLib.VerifyingKey memory vk) {
// VERIFYING_KEY
    }

    function _verifyWithdrawFromSubsetByAddressProof(
        uint[8] calldata flatProof,
        uint root,
        uint addressRoot,
        uint subsetRoot,
        uint nullifier,
        uint assetMetadata,
        uint withdrawMetadata
    ) internal view returns (bool) {
        if (root >= ProofLib.snark_scalar_field
            || addressRoot >= ProofLib.snark_scalar_field
            || subsetRoot >= ProofLib.snark_scalar_field
            || nullifier >= ProofLib.snark_scalar_field
            || assetMetadata >= ProofLib.snark_scalar_field
            || withdrawMetadata >= ProofLib.snark_scalar_field
        ) revert ProofLib.GteSnarkScalarField();

        ProofLib.Proof memory proof;
        proof.A = ProofLib.G1Point(flatProof[0], flatProof[1]);
        proof.B = ProofLib.G2Point([flatProof[2], flatProof[3]], [flatProof[4], flatProof[5]]);
        proof.C = ProofLib.G1Point(flatProof[6], flatProof[7]);

        ProofLib.VerifyingKey memory vk = withdrawFromSubsetByAddressVerifyingKey();
        ProofLib.G1Point memory vk_x = ProofLib.G1Point(0, 0);
        vk_x = vk_x.addition(vk.IC[1].scalar_mul(root));
        vk_x = vk_x.addition(vk.IC[2].scalar_mul(addressRoot));
        vk_x = vk_x.addition(vk.IC[3].scalar_mul(subsetRoot));
        vk_x = vk_x.addition(vk.IC[4].scalar_mul(nullifier));
        vk_x = vk_x.addition(vk.IC[5].scalar_mul(assetMetadata));
        vk_x = vk_x.addition(vk.IC[6].scalar_mul(withdrawMetadata));
        vk_x = vk_x.addition(vk.IC[0]);
        return proof.A.negate().pairingProd4(
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}