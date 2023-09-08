# Privacy Pools with Opt-in or Opt-out Anonymity Sets
This is an attempt at a non-custodial, non-restrictive privacy protocol that allows withdrawals to positively associate with arbitrary subsets of deposits. Users can voluntarily remove themselves from an anonymity set containing stolen or laundered funds, and this is done completely in zero knowledge without sacrificing the privacy of the user.

**This design aims to be a crypto-native solution that allows the community to defend against hackers abusing the anonymity sets of honest users without requiring blanket regulation or sacrificing on crypto ideals.**

This is an opportunity to prove the ingenuity of the crypto community to self regulate and to showcase the awesome power of zero knowledge proofs!

Features:
 -  In addition to proving the existence of an unspent deposit, withdrawals MUST associate with a subset in the deposits tree.
 -  Withdrawals associate with a subset in one of two ways:
    1. Proof of inclusion to a subset of good deposits
    2. Proof of exclusion from a subset of bad deposits
 - Subsets are efficiently represented as a subset merkle root (1 evm word).
 - Subset merkle roots are provided in calldata at the time of withdrawal and validated in the zero knowledge proof, and there are no restrictions on which subset roots can be chosen.
    - It shouldn't be possible to provide an invalid subset root, but even if it was possible, that withdrawal would simply be untrusted by default, because it wouldn't be possible to verify which subset of deposits is represented by a nonsensical root.
 - There's almost no overhead added compared to the minimal design.
 - Funds cannot be locked in the contract, censored, or stolen based on any opinionated list.
 - Over time as communities curate deposit lists, the anonymity set for hackers actually shrinks to include only those bad deposits, **naturally hindering even the possibility of money laundering to occur**.

The fact that every withdrawal must associate with a subset in the deposits tree does not necessarily restrict the anonymity set for a given deposit. Reason: the set of all deposits is a subset of all deposits. Therefore, it is possible to withdraw by associating with the subset of deposits that is the set of all deposits. The way this is done is by proving exclusion from the empty block list.

# Technical Specification
## 💡 This protocol is still a work in progress. This repository is both the technical specification and the minimal initial implementation.

**GOAL:** Design and practically implement Vitalik's idea for a simple tornado cash like privacy pool.

[Paraphrasing from his description in a recent podcast](https://www.youtube.com/clip/Ugkx7LeQPvONM0OFOfAUazyjf0JSj_9y7Tqw), we want to do this *one simple thing*:

> **One simple thing that you can do is you can create a tornado cash like thing where when you withdraw, in addition to just making a zero knowledge proof that proves that you have a valid deposit and that your valid deposit wasn't spent yet, you could also make a zero knowledge proof that says that this withdrawal is not part of one of this subset of deposits or this withdrawal is part of one of this subset of deposits.**

## Description

Since we're only concerned with proving statements about subsets of deposits, we use sparse merkle trees of matching depth to the deposits tree. We refer to specific deposits in subset trees by their actual index in the deposit tree. Only the root of an access tree needs to be posted on-chain, and it can be efficiently verified using off-chain data.

We want to do either proof of inclusion or proof of exclusion. Therefore the zero knowledge proof will have to accommodate both types. We achieve both by adopting the following conventions for our sparse merkle trees:

**Deposit list:**

The zero value of a deposit tree is `keccak256("empty")`.

It’s statisically impossible that a depositor will generate a commitment that collides with the zero value, hence we are certain that the funds can’t be rugged.

**Allow list:**

The zero value of an allowed tree is `keccak256("blocked")`.

Deposits are blocked by default. To allow a deposit, set the value at its index in the allow list to `keccak256("allowed")`.

**Block list:**

The zero value of a blocked tree is `keccak256("allowed")`.

Deposits are allowed by default. To block a deposit, set the value at its index in the block list to `keccak256("blocked")`.

When the proof is generated, the depositor chooses an arbitrary list to prove inclusion or exclusion with, and this is verified in the zero knowledge proof on-chain. In either case of inclusion or exclusion, the proof is only valid if the leaf value at the deposit’s index in the subset tree is equal to `keccak256("allowed")`.

Technically, the blocked value is irrelevant, but the convention makes it easier to transmit lists and generate the associated trees. I think it's possible to create **semi-private access lists** by choosing a different blocked value and privately transmitting the list and the blocked value only to the specific members of the list. Such a root would be unrecoverable from any default permutation of the deposits set. (Any subset root generated from the default values can eventually be found by bruteforcing the merkle roots of all permutations of deposits, which is feasible for small lists).

Strategically choosing allowed and blocked values in this manner simplifies storing and transmitting the subsets because you can represent a subset of deposits with a bit string that has a length at most equal to one plus the index of the last non-default value in the list, where 0 in the bit string denotes the default value for the tree type and 1 in the bit string denotes the opposite value for the tree type.

For example, suppose we wanted to create a block list that blocks deposits 0, 12, 32, and 42. Now consider that the deposits tree has 1000 deposits. We only need to make a bit string of maximum length 42 to fully encode the block list, despite the fact that the deposits tree has many more deposits. E.g.,

```json
{
    "treeType": "blocklist",
    "list": "000000000001000000000000000000010000000001"
}
```


We can take this a step further by omitting all bits up to and including the first non-default value by providing an initial index:

```json
{
    "treeType": "blocklist",
    "firstIndex": 12,
    "list": "000000000000000000010000000001"
}
```

The maximum length of a subset compressed in this form is $2^{20}$ bits, or 128 KiB. Since that’s relatively small, these lists can be stored on-chain in transaction calldata. The list will consume less than 80k gas to be included in calldata up to the 10,000th deposit, less than 800k gas up to the 100,000th deposit, and roughly 8 million gas to post a list up to the final deposit in the tree. In all cases this can fit within the gas limit of a block, and it’s only a one-time cost. We can also use compression to reduce the on-chain footprint.

Depositors reconstruct the subset tree in the browser with only the bit string and the tree type. A given subset tree has a maximum size that’s equal to the maximum size of the deposit tree. So long as the deposit tree merkle proof can be computed in the browser, the proof of inclusion or proof of exclusion can also be computed in the browser, therefore the overhead of adding this proof should not impede the feasibility of the system based on hardware constraints.

The zero knowledge proof will publicly expose the subset root of the block or allow list it belongs to, while maintaining the privacy of the deposit. A withdrawal can associate with any valid subset root. It’s up to social consensus to determine which subsets contain exclusively licit actors (for allow lists) or which subsets contain exclusively illicit actors (for block lists). Remember, a withdrawal can simply use the empty blocklist root to avoid proving membership in any smaller subset of the deposits tree, and the privacy pools cannot steal funds or censor any individuals. It's purely neutral infrastructure that enables a layer of social governance on top of a credibly neutral tool. What the communities decide from there cannot destroy any user's funds.

In the ideal case, the community will natively defend itself against blackhat activity, and this will all be publicly verifiable. Intervention from state actors may not be necessary because money laundering activity may be negligible using this protocol (probably my guess is that regulators would rather the crypto community self-address these issues, so that they don't have to expend resources on this domain). Admittedly, this design adds new layers of complexity that will need to be solved, mainly around curating lists, labelling curated lists, and communicating which lists are good or bad in a user friendly way.

One way to facilitate the decentralized curation of the subsets is to use subset root values as token ids of NFTs. The metadata of the NFTs can point to a block number where the subset bitstring representation and tree type of the list is emitted in a transaction’s calldata. A dao or multisig can mint NFTs of curated subsets, and the user can reconstruct the tree for use in their merkle proofs using entirely on-chain data by browsing a catalogue of community-curated lists represented nicely as an NFT gallery.


# Test Locally
I wrote the circom circuit and several basic unit tests to compute a withdrawal with an additional subset membership proof. You can compile and test it locally on your own machine by running the following commands.
## Clone
```sh
$ git clone https://github.com/ameensol/privacy-pools
$ cd privacy-pools
```

## Install
```sh
$ yarn
```

### Note: requires circom and snarkjs installed in your $PATH

#### snarkjs
```
npm install -g snarkjs
```

#### circom
see: https://docs.circom.io/getting-started/installation/


## Setup
```sh
$ ./scripts/setup.sh
```

## Test
```sh
$ yarn mocha
```
