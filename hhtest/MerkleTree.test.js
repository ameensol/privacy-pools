const { expect } = require('chai');
const { ethers } = require('hardhat');
const { poseidonContract } = require('circomlibjs');
const {
    MerkleTree,
    utils,
    poseidon,
} = require('vmtree-sdk');
const { deployBytes } = require('../scripts/hardhat.utils');

const ALLOWED = utils.getZero("allowed");

describe("Poseidon MerkleTree", function() {
    before(async () => {
        const abi = poseidonContract.generateABI(2);
        const bytecode = poseidonContract.createCode(2);
        this.poseidon = await deployBytes("Poseidon", abi, bytecode);
        const factory = await ethers.getContractFactory("MerkleTree");
        this.merkleTreeContract = await factory.deploy(this.poseidon.address, ALLOWED);
        this.merkleTree = new MerkleTree({hasher: poseidon, levels: 20, baseString: "allowed"});
        this.roots = [this.merkleTree.root];
    });

    it('should have the zero root', async () => {
        expect((await this.merkleTreeContract.getLatestRoot()).toString())
            .to.be.equal(this.merkleTree.root.toString());
    });

    it('should have the next root', async () => {
        await this.merkleTreeContract.testInsert(0);
        await this.merkleTree.insert(0);
        this.roots.push(this.merkleTree.root);
        expect((await this.merkleTreeContract.getLatestRoot()).toString())
            .to.be.equal(this.merkleTree.root.toString());
    });

    it('should remember the first root', async () => {
        expect((await this.merkleTreeContract.isKnownRoot(this.roots[0])))
            .to.be.true;
    });

    it('should work for the next few roots', async () => {
        const elements = [42, 69, 420, 343, 216, 8675309, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55];
        for (const element of elements) {
            await this.merkleTreeContract.testInsert(element);
            await this.merkleTree.insert(element);
            this.roots.push(this.merkleTree.root);
            expect((await this.merkleTreeContract.getLatestRoot()).toString())
                .to.be.equal(this.merkleTree.root.toString());
        };

        for (const root of this.roots) {
            expect((await this.merkleTreeContract.isKnownRoot(root))).to.be.true;
        }
    }).timeout(10000);
});