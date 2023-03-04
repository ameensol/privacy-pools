pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/pedersen.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";

template Hash2Nodes() {
    signal input left;
    signal input right;
    signal output hash;

    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== left;
    poseidon.inputs[1] <== right;
    hash <== poseidon.out;
}

template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    out[0] <== (in[1] - in[0])*s + in[0];
    out[1] <== (in[0] - in[1])*s + in[1];
}

template DoubleMerkleProof(levels, expectedValue) {
    signal input leaf;
    signal input path;
    signal input mainProof[levels];
    signal input subsetProof[levels];
    signal output root;
    signal output subsetRoot;

    component selectors1[levels];
    component selectors2[levels];

    component hashers1[levels];
    component hashers2[levels];

    component pathBits = Num2Bits(levels);
    pathBits.in <== path;

    for (var i = 0; i < levels; i++) {
        selectors1[i] = DualMux();
        selectors1[i].in[0] <== i == 0 ? leaf : hashers1[i - 1].hash;
        selectors1[i].in[1] <== mainProof[i];
        selectors1[i].s <== pathBits.out[i];
        hashers1[i] = Hash2Nodes();
        hashers1[i].left <== selectors1[i].out[0];
        hashers1[i].right <== selectors1[i].out[1];

        selectors2[i] = DualMux();
        selectors2[i].in[0] <== i == 0 ? expectedValue : hashers2[i - 1].hash;
        selectors2[i].in[1] <== subsetProof[i];
        selectors2[i].s <== pathBits.out[i];
        hashers2[i] = Hash2Nodes();
        hashers2[i].left <== selectors2[i].out[0];
        hashers2[i].right <== selectors2[i].out[1];
    }

    root <== hashers1[levels - 1].hash;
    subsetRoot <== hashers2[levels - 1].hash;
}

template CommitmentHasher() {
    signal input nullifier;
    signal input secret;
    signal output commitment;
    signal output nullifierHash;

    component commitmentHasher = Pedersen(496);
    component nullifierHasher = Pedersen(248);
    component nullifierBits = Num2Bits(248);
    component secretBits = Num2Bits(248);
    nullifierBits.in <== nullifier;
    secretBits.in <== secret;
    for (var i = 0; i < 248; i++) {
        nullifierHasher.in[i] <== nullifierBits.out[i];
        commitmentHasher.in[i] <== nullifierBits.out[i];
        commitmentHasher.in[i + 248] <== secretBits.out[i];
    }

    commitment <== commitmentHasher.out[0];
    nullifierHash <== nullifierHasher.out[0];
}

template TornadoRescue(levels, expectedValue) {
    // public
    signal input root;
    signal input subsetRoot;
    signal input nullifierHash;
    signal input metadata;

    // private
    signal input nullifier;
    signal input secret;
    signal input path;
    signal input mainProof[levels];
    signal input subsetProof[levels];

    component hasher = CommitmentHasher();
    hasher.nullifier <== nullifier;
    hasher.secret <== secret;
    nullifierHash === hasher.nullifierHash;

    component doubleTree = DoubleMerkleProof(levels, expectedValue);
    doubleTree.leaf <== hasher.commitment;
    doubleTree.path <== path;
    for (var i = 0; i < levels; i++) {
        doubleTree.mainProof[i] <== mainProof[i];
        doubleTree.subsetProof[i] <== subsetProof[i];
    }
    root === doubleTree.root;
    subsetRoot === doubleTree.subsetRoot;

    signal metadataSquare;
    metadataSquare <== metadata * metadata;
}

component main {
    public [
        root,
        subsetRoot,
        nullifierHash,
        metadata
    ]
} = TornadoRescue(
    20,
    // keccak256("allowed") % p
    11954255677048767585730959529592939615262310191150853775895456173962480955685
);