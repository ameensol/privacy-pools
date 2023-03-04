// const chalk = require('chalk');
// const { expect } = require('chai');
// const { BigNumber } = require('@ethersproject/bignumber');
// const { keccak256 } = require('@ethersproject/solidity');
// const {
//     MerkleTree,
//     generateProof,
//     verifyProof,
//     utils,
//     poseidon,
// } = require('vmtree-sdk');

// const VERIFIER_JSON = require('../circuits/out/withdraw_from_subset_by_address_verifier.json');
// const WASM_FNAME = "./circuits/out/withdraw_from_subset_by_address_js/withdraw_from_subset_by_address.wasm";
// const ZKEY_FNAME = "./circuits/out/withdraw_from_subset_by_address_final.zkey";
// const ALLOWED = utils.getZero("allowed");
// const BLOCKED = utils.getZero("blocked");
// const ZKP_TEST_TIMEOUT = 20000; // alter if necessary.
// // console.log("Allowed value:", ALLOWED);
// // console.log("Blocked value:", BLOCKED);

// function hashAssetMetadata({token, denomination}) {
//     return BigNumber.from(
//         keccak256(["address", "uint"], [token, denomination])
//     ).mod(utils.F.p.toString());
// };

// function hashWithdrawMetadata({recipient, relayer, fee}) {
//     return BigNumber.from(
//         keccak256(["address", "address", "uint"], [recipient, relayer, fee])
//     ).mod(utils.F.p.toString());
// };

// function verifyMerkleProof({pathElements, pathIndices, leaf, root}) {
//     pathElements.forEach((element, i) => {
//         leaf = !pathIndices[i] ?
//             poseidon([leaf, element]) : poseidon([element, leaf]);
//     });
//     return leaf == root;
// }

// describe("withdraw_from_subset_by_address.circom (JS tests edition)", function() {
//     before(async () => {
//         utils.stringifyBigInts(BigNumber.from(0))
//         this.proofCounter = 0;
//         this.secrets = utils.unsafeRandomLeaves(42);
//         this.commitments = new Array(42);
//         this.assetMetadata = hashAssetMetadata({
//             token: "0x0000000000000000000000000000000000000000",
//             denomination: "1000000000000000000"
//         });
//         this.withdrawMetadata = hashWithdrawMetadata({
//             recipient: "0x0000000000000000000000000000000000000000",
//             relayer: "0x0000000000000000000000000000000000000000",
//             fee: "0"
//         })

//         this.secrets.forEach((secret, i) => {
//             this.commitments[i] = poseidon([
//                 poseidon([secret]),
//                 this.assetMetadata
//             ]);
//         });
//         this.deposit_tree = new MerkleTree({ hasher: poseidon, leaves: this.commitments, baseString: "empty"});
//     });

//     it("should be able to generate proofs of inclusion in an allow subset", async () => {
//         this.allowlist_tree = new MerkleTree({
//             hasher: poseidon,
//             baseString: "blocked",
//             leaves: [ ALLOWED, BLOCKED, BLOCKED, BLOCKED, ALLOWED, BLOCKED, BLOCKED, ALLOWED ]
//         });
//         const leaf = ALLOWED;
//         const root = this.allowlist_tree.root;
//         console.log('\tAllowlist root:', root);
//         const paths = [0, 4, 7];
//         for (const path of paths) { try {
//             const { pathIndices, pathElements } = await this.allowlist_tree.path(path);
//             expect(verifyMerkleProof({
//                 leaf,
//                 root,
//                 pathElements,
//                 pathIndices
//             })).to.be.true;
//         } catch (err) { console.error(err); }};
//     });

//     it("should be able to generate valid zkps using the proof of inclusion in allowlist", async () => {
//         const assetMetadata = this.assetMetadata;
//         const withdrawMetadata = this.withdrawMetadata;
//         const paths = [0, 4, 7];
//         console.log(chalk.green("The following zkp proof generation times include instantiating the deposit merkle tree and the allowlist tree"));
//         for (const path of paths) { try {
//             console.time(`proof ${this.proofCounter}`);
//             const deposit_tree = new MerkleTree({ hasher: poseidon, leaves: this.commitments, baseString: "empty"});
//             const allowlist_tree = new MerkleTree({
//                 hasher: poseidon,
//                 baseString: "blocked",
//                 leaves: [ ALLOWED, BLOCKED, BLOCKED, BLOCKED, ALLOWED, BLOCKED, BLOCKED, ALLOWED ]
//             });
//             const { pathElements: mainProof, pathRoot: root } = await deposit_tree.path(path);
//             const { pathElements: subsetProof, pathRoot: subsetRoot } = await allowlist_tree.path(path);
//             // const { pathElements: mainProof, pathRoot: root } = await this.deposit_tree.path(path);
//             // const { pathElements: subsetProof, pathRoot: subsetRoot } = await this.allowlist_tree.path(path);
//             const secret = this.secrets[path];
//             const nullifier = poseidon([secret, 1n, path]);
//             const input = utils.stringifyBigInts({
//                 root,
//                 subsetRoot,
//                 nullifier,
//                 assetMetadata,
//                 withdrawMetadata,
//                 secret,
//                 path,
//                 mainProof,
//                 subsetProof
//             });
//             const { proof, publicSignals } = await generateProof({
//                 input,
//                 wasmFileName: WASM_FNAME,
//                 zkeyFileName: ZKEY_FNAME
//             });
//             console.timeEnd(`proof ${this.proofCounter++}`);
//             expect(await verifyProof({proof, publicSignals, verifierJson: VERIFIER_JSON})).to.be.true;
//         } catch (err) { console.error(err); }}
//     }).timeout(ZKP_TEST_TIMEOUT);

//     it("should be able to generate proofs of exclusion in a block subset", async () => {
//         this.blocklist_tree = new MerkleTree({
//             hasher: poseidon,
//             baseString: "allowed",
//             leaves: [ ALLOWED, BLOCKED, BLOCKED, BLOCKED, ALLOWED, BLOCKED, BLOCKED, ALLOWED ]
//         });
//         const leaf = ALLOWED;
//         const root = this.blocklist_tree.root;
//         console.log('\tBlocklist root:', root);
//         const paths = [0, 4, 7];
//         for (const path of paths) { try {
//             const { pathIndices, pathElements } = await this.blocklist_tree.path(path);
//             expect(verifyMerkleProof({
//                 leaf,
//                 root,
//                 pathElements,
//                 pathIndices
//             })).to.be.true;
//         } catch (err) { console.error(err); }}
//     });

//     it("should be able to generate valid zkps using the proof of exclusion in blocklist", async () => {
//         const assetMetadata = this.assetMetadata;
//         const withdrawMetadata = this.withdrawMetadata;
//         const paths = [0, 4, 7];
//         console.log(chalk.blue("The following zkp proof generation times do not include instantiating the deposit merkle tree and the allowlist tree"));
//         for (const path of paths) { try {
//             console.time(`proof ${this.proofCounter}`);
//             const { pathElements: mainProof, pathRoot: root } = await this.deposit_tree.path(path);
//             const { pathElements: subsetProof, pathRoot: subsetRoot } = await this.blocklist_tree.path(path);
//             const secret = this.secrets[path];
//             const nullifier = poseidon([secret, 1n, path]);
//             const input = utils.stringifyBigInts({
//                 root,
//                 subsetRoot,
//                 nullifier,
//                 assetMetadata,
//                 withdrawMetadata,
//                 secret,
//                 path,
//                 mainProof,
//                 subsetProof
//             });
//             const { proof, publicSignals } = await generateProof({
//                 input,
//                 wasmFileName: WASM_FNAME,
//                 zkeyFileName: ZKEY_FNAME
//             });
//             console.timeEnd(`proof ${this.proofCounter++}`);
//             expect(await verifyProof({proof, publicSignals, verifierJson: VERIFIER_JSON})).to.be.true;
//         } catch (err) { console.error(err); }}
//     }).timeout(ZKP_TEST_TIMEOUT);

//     after(() => process.exit());
// });