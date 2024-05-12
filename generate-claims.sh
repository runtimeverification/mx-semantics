#!/usr/bin/env bash

set -e -o pipefail

poetry -C kmultiversx install

make build-kasmer

# Adder

sc-meta all build --path deps/mx-sdk-rs/contracts/examples/adder --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/foundrylike --wasm-symbols --no-wasm-opt
wasm2wat deps/mx-sdk-rs/contracts/examples/adder/output/adder.wasm -o generated_claims/w-adder.wat
wasm2wat tests/contracts/foundrylike/output/foundrylike.wasm -o generated_claims/w-foundrylike.wat
poetry -C kmultiversx run -- kasmer --directory "tests/contracts/foundrylike" --gen-claims 2>&1 | tee kasmer.log

# Coindrip

for f in $(find deps/coindrip-protocol-sc/ -name 'Cargo.toml')
do
  cat $f | sed 's/0.39.2/0.48.0/'  | sed 's/0.47.4/0.48.0/' > tmp.rs
  mv tmp.rs $f
done
sc-meta all build --path deps/coindrip-protocol-sc --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_coindrip --wasm-symbols --no-wasm-opt
wasm2wat deps/coindrip-protocol-sc/output/coindrip.wasm -o generated_claims/w-coindrip.wat
wasm2wat tests/contracts/test_coindrip/output/test_coindrip.wasm -o generated_claims/w-test_coindrip.wat
poetry -C kmultiversx run -- kasmer --directory "tests/contracts/test_coindrip" --gen-claims 2>&1 | tee kasmer.log

# Crowdfunding

sc-meta all build --path deps/mx-sdk-rs/contracts/examples/crowdfunding-esdt --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_crowdfunding-esdt --wasm-symbols --no-wasm-opt
wasm2wat deps/mx-sdk-rs/contracts/examples/crowdfunding-esdt/output/crowdfunding-esdt.wasm -o generated_claims/w-crowdfunding-esdt.wat
wasm2wat tests/contracts/test_crowdfunding-esdt/output/test_crowdfunding-esdt.wasm -o generated_claims/w-test_crowdfunding-esdt.wat
poetry -C kmultiversx run -- kasmer --directory "tests/contracts/test_crowdfunding-esdt" --gen-claims 2>&1 | tee kasmer.log

# Pair

for f in $(find deps/mx-exchange-sc/dex/pair -name 'Cargo.toml')
do
  cat $f | sed 's/0.46.1/0.48.0/' > tmp.rs
  mv tmp.rs $f
done

sc-meta all build --path deps/mx-exchange-sc/dex/pair --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_pair --wasm-symbols --no-wasm-opt
wasm2wat deps/mx-exchange-sc/dex/pair/output/pair.wasm -o generated_claims/w-pair.wat
wasm2wat tests/contracts/test_pair/output/test_pair.wasm -o generated_claims/w-test_pair.wat
poetry -C kmultiversx run -- kasmer --directory "tests/contracts/test_pair" --gen-claims 2>&1 | tee kasmer.log

# Multisig

sc-meta all build --path deps/mx-sdk-rs/contracts/examples/multisig --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_multisig --wasm-symbols --no-wasm-opt
wasm2wat deps/mx-sdk-rs/contracts/examples/multisig/output/multisig.wasm -o generated_claims/w-multisig.wat
wasm2wat tests/contracts/test_multisig/output/test_multisig.wasm -o generated_claims/w-test_multisig.wat
poetry -C kmultiversx run -- kasmer --directory "tests/contracts/test_multisig" --gen-claims 2>&1 | tee kasmer.log

# NFT

sc-meta all build --path tests/contracts/test_nft --wasm-symbols --no-wasm-opt
wasm2wat tests/contracts/test_nft/output/test_nft.wasm -o generated_claims/w-test_nft.wat
poetry -C kmultiversx run -- kasmer --directory "tests/contracts/test_nft" --gen-claims 2>&1 | tee kasmer.log

