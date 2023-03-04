#!/bin/bash

TARGET=$1
TAU=$2
NUM_PUBLIC_INPUTS=$3

if [ ! -f "./circuits/out/${TARGET}.r1cs" ] \
    || [ ! -f "./circuits/out/${TARGET}_js/${TARGET}.wasm" ] \
    || [ ! -f "./circuits/out/${TARGET}.sym" ]
then
    circom ./circuits/$TARGET.circom \
		-o=./circuits/out --r1cs --sym --wasm
    echo $TARGET circuit compiled!
else
    echo $TARGET circuit already compiled!
fi

if [ -f "./powers_of_tau/powersOfTau28_hez_final_$TAU.ptau" ]; then
    echo powersOfTau28_hez_final_$TAU.ptau found!
else
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_$TAU.ptau \
        -O ./powers_of_tau/powersOfTau28_hez_final_$TAU.ptau
fi

if [ ! -f "./circuits/out/${TARGET}_0000.zkey" ]
then
    echo generating zkp proving and verifying keys!
    snarkjs g16s \
		./circuits/out/$TARGET.r1cs \
		./powers_of_tau/powersOfTau28_hez_final_$TAU.ptau \
		./circuits/out/${TARGET}_0000.zkey -v
    echo $TARGET groth16 setup complete!
else
    echo $TARGET groth16 setup already complete!
fi

if [ ! -f "./circuits/out/${TARGET}_final.zkey" ]
then
    snarkjs zkc \
		./circuits/out/${TARGET}_0000.zkey ./circuits/out/${TARGET}_final.zkey -v \
		-e='vitaliks simple mixer'
    echo $TARGET contribution complete!
else
    echo $TARGET contribution already complete!
fi

if [ ! -f "./circuits/out/${TARGET}_verifier.json" ]
then
    snarkjs zkev \
		./circuits/out/${TARGET}_final.zkey \
		./circuits/out/${TARGET}_verifier.json
    echo $TARGET verifier json exported!
else
    echo $TARGET verifier json already exported!
fi

if [ ! -f "./circuits/out/${TARGET}_verifier.sol" ]
then
	snarkjs zkesv \
		./circuits/out/${TARGET}_final.zkey \
		./circuits/out/${TARGET}_verifier.sol
    echo $TARGET verifier template contract exported!
else
    echo $TARGET verifier template contract already exported!
fi

if [ ! -f "./contracts/verifiers/${TARGET}_verifier.sol" ]
then
    python3 ./scripts/export_verifier.py $TARGET $NUM_PUBLIC_INPUTS
    echo $TARGET verifier contract exported!
else
    echo $TARGET verifier contract already exported!
fi