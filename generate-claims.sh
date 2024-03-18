#!/usr/bin/env bash

set -e -o pipefail

poetry -C kmultiversx install

# Adder

sc-meta all build --path deps/mx-sdk-rs/contracts/examples/adder --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/foundrylike --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/foundrylike" --gen-claims 2>&1 | tee kasmer.log

# Coindrip

for f in $(find deps/coindrip-protocol-sc/ -name 'Cargo.toml')
do
  cat $f | sed 's/0.39.2/0.47.4/' > tmp.rs
  mv tmp.rs $f
done
sc-meta all build --path deps/coindrip-protocol-sc --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_coindrip --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/test_coindrip" --gen-claims 2>&1 | tee kasmer.log

# Crowdfunding

sc-meta all build --path deps/mx-sdk-rs/contracts/examples/crowdfunding-esdt --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_crowdfunding-esdt --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/test_crowdfunding-esdt" --gen-claims 2>&1 | tee kasmer.log

# Pair

sc-meta all build --path deps/mx-exchange-sc/dex/pair --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_pair --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/test_pair" --gen-claims 2>&1 | tee kasmer.log

# Multisig

sc-meta all build --path deps/mx-sdk-rs/contracts/examples/multisig --wasm-symbols --no-wasm-opt
sc-meta all build --path tests/contracts/test_multisig --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/test_multisig" --gen-claims 2>&1 | tee kasmer.log
