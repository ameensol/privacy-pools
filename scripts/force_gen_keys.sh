#!/bin/bash

TARGET=$1
TAU=$2
NUM_PUBLIC_INPUTS=$3

circom ./circuits/$TARGET.circom \
    -o=./circuits/out --r1cs --sym --wasm
echo $TARGET circuit compiled!

if [ -f "./powers_of_tau/powersOfTau28_hez_final_$TAU.ptau" ]; then
    echo powersOfTau28_hez_final_$TAU.ptau found!
else
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_$TAU.ptau \
        -O ./powers_of_tau/powersOfTau28_hez_final_$TAU.ptau
fi

echo generating zkp proving and verifying keys!
snarkjs g16s \
    ./circuits/out/$TARGET.r1cs \
    ./powers_of_tau/powersOfTau28_hez_final_$TAU.ptau \
    ./circuits/out/${TARGET}_0000.zkey -v
echo $TARGET groth16 setup complete!
snarkjs zkc \
    ./circuits/out/${TARGET}_0000.zkey ./circuits/out/${TARGET}_final.zkey -v \
    -e='vitaliks simple mixer'
echo $TARGET contribution complete!

snarkjs zkev \
    ./circuits/out/${TARGET}_final.zkey \
    ./circuits/out/${TARGET}_verifier.json
echo $TARGET verifier json exported!

snarkjs zkesv \
    ./circuits/out/${TARGET}_final.zkey \
    ./circuits/out/${TARGET}_verifier.sol
echo $TARGET verifier template contract exported!

python3 ./scripts/export_verifier.py $TARGET $NUM_PUBLIC_INPUTS
echo $TARGET verifier contract exported!