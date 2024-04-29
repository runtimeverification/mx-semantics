.PHONY: all                                                                      \
        test-elrond-adder test-elrond-crowdfunding-esdt                          \
        test-elrond-multisig test-elrond-basic-features                          \
        test-elrond-alloc-features test-elrond-composability-features            \
        test-elrond-addercaller test-elrond-callercallee test-custom-contracts   \
        rule-coverage clean-coverage runtime-json test-elrond-nft-minter         \


# Settings
# --------

ELROND_SDK_SUBMODULE     := deps/mx-sdk-rs
ELROND_CONTRACT          := $(ELROND_SDK_SUBMODULE)/contracts
ELROND_CONTRACT_EXAMPLES := $(ELROND_CONTRACT)/examples


all: build


# Building Definition
# -------------------

K_OPTS     := -Xmx8G -Xss512m
POETRY     := poetry -C kmultiversx
POETRY_RUN := $(POETRY) run

.PHONY: kmultiversx
kmultiversx:
	$(POETRY) install --no-ansi

.PHONY: build
build: build-mandos

.PHONY: build-mandos
build-mandos: kmultiversx
	K_OPTS='$(K_OPTS)' $(POETRY) run kdist -v build mx-semantics.llvm-mandos

.PHONY: build-kasmer
build-kasmer: kmultiversx
	K_OPTS='$(K_OPTS)' $(POETRY) run kdist -v build mx-semantics.llvm-kasmer

.PHONY: build-haskell
build-haskell: kmultiversx
	$(POETRY) run kdist -v build mx-semantics.haskell-\* -j2

.PHONY: build-all
build-all: kmultiversx
	K_OPTS='$(K_OPTS)' $(POETRY) run kdist -v build mx-semantics.\* -j4

.PHONY: clean
clean: kmultiversx
	$(POETRY) run kdist clean
	$(MAKE) -C $(PLUGIN_SUBMODULE) clean

# Runtime
# -------

ESDT_SYSTEM_SC_DIR  := src/esdt-system-sc
ESDT_SYSTEM_SC_WASM := $(ESDT_SYSTEM_SC_DIR)/output/esdt-system-sc.wasm

$(ESDT_SYSTEM_SC_WASM): sc-build/$(ESDT_SYSTEM_SC_DIR)

runtime-json: build-mandos build-kasmer $(ESDT_SYSTEM_SC_WASM)
	$(POETRY) run runtime $(ESDT_SYSTEM_SC_WASM)


# Testing
# -------

KRUN_OPTS :=

# TODO add test-elrond-lottery-esdt
elrond-contract-deps := test-elrond-adder             \
                        test-elrond-crowdfunding-esdt \
                        test-elrond-multisig          \
                        test-elrond-basic-features    \
                        test-elrond-alloc-features    \
                        test-elrond-composability-features
test-elrond-contracts: $(elrond-contract-deps)

test: test-simple mandos-test test-elrond-contracts test-custom-contracts

# Unit Tests
# ----------

TEST  := $(POETRY) run -- kelrond
CHECK := git --no-pager diff --no-index --ignore-all-space -R

TEST_CONCRETE_BACKEND:= llvm

tests/%.run: tests/%
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< $(KRUN_OPTS) > tests/$*.$(TEST_CONCRETE_BACKEND)-out
	rm -rf tests/$*.$(TEST_CONCRETE_BACKEND)-out

simple_tests := $(wildcard tests/simple/*.wast)

test-simple: $(simple_tests:=.run)

# Elrond Tests
# ------------

TEST_MANDOS := $(POETRY_RUN) mandos

sc-build/%:
	sc-meta all build --path $* --wasm-symbols --no-wasm-opt

## Mandos Test

MANDOS_TESTS_DIR := tests/mandos
mandos_tests=$(sort $(wildcard $(MANDOS_TESTS_DIR)/*.scen.json))
mandos-test: build
	$(TEST_MANDOS) $(mandos_tests)

## Adder Test

ELROND_ADDER_DIR := $(ELROND_CONTRACT_EXAMPLES)/adder
elrond_adder_tests=$(shell find $(ELROND_ADDER_DIR) -name "*.scen.json")

test-elrond-adder: build sc-build/$(ELROND_ADDER_DIR)
	$(TEST_MANDOS) $(elrond_adder_tests)


## Crowdfunding Test

ELROND_CROWDFUNDING_DIR := $(ELROND_CONTRACT_EXAMPLES)/crowdfunding-esdt
elrond_crowdfunding_tests=$(shell find $(ELROND_CROWDFUNDING_DIR) -name "*.scen.json")

test-elrond-crowdfunding-esdt: build sc-build/$(ELROND_CROWDFUNDING_DIR)
	$(TEST_MANDOS) $(elrond_crowdfunding_tests)

## Multisg Test

ELROND_MULTISIG_DIR=$(ELROND_CONTRACT_EXAMPLES)/multisig
elrond_multisig_tests=$(shell cat tests/multisig.test)

test-elrond-multisig: build sc-build/$(ELROND_MULTISIG_DIR)
	$(TEST_MANDOS) $(elrond_multisig_tests)

# NFT Tests

test-elrond-nft-minter: build sc-build/$(ELROND_CONTRACT_EXAMPLES)/nft-minter
	$(TEST_MANDOS) $(shell find $(ELROND_CONTRACT_EXAMPLES)/nft-minter -name "*.scen.json")

## Basic Feature Test

ELROND_BASIC_FEATURES_DIR=$(ELROND_CONTRACT)/feature-tests/basic-features
ELROND_BASIC_FEATURES_WASM=$(ELROND_BASIC_FEATURES_DIR)/output/basic-features.wasm
elrond_basic_features_tests=$(shell cat tests/basic_features.test)


ELROND_ESDT_SC_MOCK_DIR=$(ELROND_CONTRACT)/feature-tests/esdt-system-sc-mock
ELROND_ESDT_SC_MOCK_WASM=$(ELROND_ESDT_SC_MOCK_DIR)/output/esdt-system-sc-mock.wasm

$(ELROND_BASIC_FEATURES_WASM): sc-build/$(ELROND_BASIC_FEATURES_DIR)
$(ELROND_ESDT_SC_MOCK_WASM): sc-build/$(ELROND_ESDT_SC_MOCK_DIR)

# TODO optimize test runner and enable logging
test-elrond-basic-features: $(elrond_basic_features_tests:=.mandos)

$(ELROND_BASIC_FEATURES_DIR)/scenarios/%.scen.json.mandos: build $(ELROND_BASIC_FEATURES_WASM) $(ELROND_ESDT_SC_MOCK_WASM)
	$(TEST_MANDOS) $(ELROND_BASIC_FEATURES_DIR)/scenarios/$*.scen.json --log-level none

tests/custom-scenarios/basic-features/%.scen.json.mandos: build $(ELROND_BASIC_FEATURES_WASM) $(ELROND_ESDT_SC_MOCK_WASM)
	$(TEST_MANDOS) tests/custom-scenarios/basic-features/$*.scen.json --log-level none

## Alloc Features Test

ELROND_ALLOC_FEATURES_DIR=$(ELROND_CONTRACT)/feature-tests/alloc-features
ELROND_ALLOC_FEATURES_WASM=$(ELROND_ALLOC_FEATURES_DIR)/output/alloc-features.wasm
elrond_alloc_features_tests=$(shell cat tests/alloc_features.test)

$(ELROND_ALLOC_FEATURES_WASM): sc-build/$(ELROND_ALLOC_FEATURES_DIR)

# TODO optimize test runner and enable logging
test-elrond-alloc-features: $(elrond_alloc_features_tests:=.mandos)

$(ELROND_ALLOC_FEATURES_DIR)/scenarios/%.scen.json.mandos: build $(ELROND_ALLOC_FEATURES_WASM)
	$(TEST_MANDOS) $(ELROND_ALLOC_FEATURES_DIR)/scenarios/$*.scen.json --log-level none

## Composability Features Test

elrond_composability_features_tests=$(shell cat tests/composability_features.test)
test-elrond-composability-features: $(elrond_composability_features_tests:=.mandos)

ELROND_COMPOSABILITY_FEATURES_DIR=$(ELROND_CONTRACT)/feature-tests/composability

composability_contracts := vault              \
                           promises-features  \
						   forwarder          \
                           forwarder-queue    \
                           forwarder-raw      \
                           proxy-test-first
composability_builds := $(patsubst %,sc-build/$(ELROND_COMPOSABILITY_FEATURES_DIR)/%,$(composability_contracts))

$(ELROND_COMPOSABILITY_FEATURES_DIR)/%.scen.json.mandos: build $(composability_builds)
	$(TEST_MANDOS) $(ELROND_COMPOSABILITY_FEATURES_DIR)/$*.scen.json --log-level none

tests/custom-scenarios/composability-features/%.scen.json.mandos: build $(composability_builds)
	$(TEST_MANDOS) tests/custom-scenarios/composability-features/$*.scen.json --log-level none

# Custom contract tests

custom-contracts := test-elrond-addercaller \
                    test-elrond-callercallee
test-custom-contracts: $(custom-contracts)

## Adder Caller Test

ELROND_ADDERCALLER_DIR := tests/contracts/addercaller
elrond_addercaller_tests=$(shell find $(ELROND_ADDERCALLER_DIR) -name "*.scen.json")
ELROND_MYADDER_DIR := tests/contracts/myadder

test-elrond-addercaller: build sc-build/$(ELROND_MYADDER_DIR) sc-build/$(ELROND_ADDERCALLER_DIR)
	$(TEST_MANDOS) $(elrond_addercaller_tests)

## Caller Callee Test

ELROND_CALLER_DIR := tests/contracts/caller
ELROND_CALLEE_DIR := tests/contracts/callee
elrond_callercallee_tests=$(shell find $(ELROND_CALLER_DIR) -name "*.scen.json")

test-elrond-callercallee: build sc-build/$(ELROND_CALLER_DIR) sc-build/$(ELROND_CALLEE_DIR)
	$(TEST_MANDOS) $(elrond_callercallee_tests)

## Kasmer Test API tests

TEST_KASMER := $(POETRY_RUN) kasmer

TEST_TESTAPI_DIR := tests/contracts/test_testapi
testapi_tests=$(shell find $(TEST_TESTAPI_DIR) -name "*.scen.json")

test-testapi: build-kasmer sc-build/$(TEST_TESTAPI_DIR)
	$(TEST_KASMER) -d $(TEST_TESTAPI_DIR)

# Coverage
# --------

ELROND_FILE_NAMES := elrond.md                   \
                     elrond-config.md            \
                     elrond-node.md              \
                     esdt.md                     \
                     auto-allocate.md            \
                     mandos.md                   \
                     kasmer.md                   \
                     $(wildcard data/*.k)        \
                     $(wildcard vmhooks/*.md)

rule-coverage: kmultiversx
	$(eval MANDOS_KOMPILED := $(shell $(POETRY_RUN) kdist which mx-semantics.llvm-mandos))
	$(eval KWASM_SRC_DIR   := $(shell $(POETRY_RUN) python -c 'from pykwasm.kdist.plugin import K_DIR; print(K_DIR)'))
	$(eval ELROND_FILES    := $(patsubst %,$(KWASM_SRC_DIR)/%,$(ELROND_FILE_NAMES)))
	python3 rule_coverage.py $(MANDOS_KOMPILED) $(ELROND_FILES)

clean-coverage: kmultiversx
	$(eval MANDOS_KOMPILED := $(shell $(POETRY_RUN) kdist which mx-semantics.llvm-mandos))
	rm $(MANDOS_KOMPILED)/*_coverage.txt $(MANDOS_KOMPILED)/coverage.txt
