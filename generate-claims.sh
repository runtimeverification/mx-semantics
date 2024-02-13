#!/usr/bin/env bash

set -e -o pipefail

# Adder

mxpy contract build --path deps/mx-sdk-rs/contracts/examples/adder --wasm-symbols --no-wasm-opt
mxpy contract build --path tests/contracts/foundrylike --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/foundrylike" --gen-claims 2>&1 | tee kasmer.log

# Coindrip

# mxpy contract build --path deps/coindrip-protocol-sc --wasm-symbols --no-wasm-opt
# mxpy contract build --path tests/contracts/test_coindrip --wasm-symbols --no-wasm-opt
# K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/test_coindrip" --gen-claims 2>&1 | tee kasmer.log

# Crowdfunding

mxpy contract build --path deps/mx-sdk-rs/contracts/examples/crowdfunding-esdt --wasm-symbols --no-wasm-opt
mxpy contract build --path tests/contracts/test_crowdfunding-esdt --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/test_crowdfunding-esdt" --gen-claims 2>&1 | tee kasmer.log

# Pair

mxpy contract build --path deps/mx-exchange-sc/dex/pair --wasm-symbols --no-wasm-opt
mxpy contract build --path tests/contracts/test_pair --wasm-symbols --no-wasm-opt
K_OPTS="-Xmx8192m" kbuild kompile llvm-kasmer && poetry -C kmultiversx run -- kasmer --definition-dir $(kbuild which llvm-kasmer) --directory "tests/contracts/test_pair" --gen-claims 2>&1 | tee kasmer.log

