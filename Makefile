
.PHONY: all clean deps wasm-deps                                                 \
        build build-llvm build-haskell                                           \
        elrond-clean-sources elrond-loaded                                       \
        test unittest-python mandos-test mandos-coverage test-elrond-contracts   \
        test-elrond-adder test-elrond-crowdfunding-esdt                          \
        test-elrond-multisig test-elrond-basic-features                          \
        test-elrond-addercaller test-elrond-callercallee test-custom-contracts   \
        rule-coverage clean-coverage                                             \

# Settings
# --------

UNAME_S := $(shell uname -s)

BUILD_DIR := .build
DEPS_DIR  := deps
DEFN_DIR  := $(BUILD_DIR)/defn
BUILD_LOCAL   := $(abspath $(BUILD_DIR)/local)
LOCAL_LIB     := $(BUILD_LOCAL)/lib

LIBRARY_PATH       := $(LOCAL_LIB)
C_INCLUDE_PATH     += :$(BUILD_LOCAL)/include
CPLUS_INCLUDE_PATH += :$(BUILD_LOCAL)/include

export LIBRARY_PATH
export C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH

PLUGIN_SUBMODULE := $(abspath $(DEPS_DIR)/plugin)
export PLUGIN_SUBMODULE

KWASM_SUBMODULE     := $(DEPS_DIR)/wasm-semantics
K_SUBMODULE         := $(KWASM_SUBMODULE)/deps/k
KWASM_BINARY_PARSER := $(KWASM_SUBMODULE)/binary-parser

ELROND_SDK_SUBMODULE     := $(DEPS_DIR)/mx-sdk-rs
ELROND_CONTRACT          := $(ELROND_SDK_SUBMODULE)/contracts
ELROND_CONTRACT_EXAMPLES := $(ELROND_CONTRACT)/examples

ifneq (,$(wildcard $(K_SUBMODULE)/k-distribution/target/release/k/bin/*))
    K_RELEASE ?= $(abspath $(K_SUBMODULE)/k-distribution/target/release/k)
else
    K_RELEASE ?= $(dir $(shell which kompile))..
endif
K_BIN := $(K_RELEASE)/bin
K_LIB := $(K_RELEASE)/lib/kframework
export K_OPTS ?= -Xmx16G -Xss512m
export K_RELEASE

PYTHONPATH := $(K_LIB):$(KWASM_BINARY_PARSER):$(PYTHONPATH)
export PYTHONPATH

KWASM_DIR  := .
KWASM_MAKE := make --directory $(KWASM_SUBMODULE) BUILD_DIR=../../$(BUILD_DIR) RELEASE=$(RELEASE)
export KWASM_DIR

all: build

clean:
	rm -rf $(BUILD_DIR)

# Non-K Dependencies
# ------------------

libff_out := $(LOCAL_LIB)/libff.a

libff: $(libff_out)

ifeq ($(UNAME_S),Linux)
    LIBFF_CMAKE_FLAGS=
else
    LIBFF_CMAKE_FLAGS=-DWITH_PROCPS=OFF
endif

$(libff_out): $(PLUGIN_SUBMODULE)/deps/libff/CMakeLists.txt
	@mkdir -p $(PLUGIN_SUBMODULE)/deps/libff/build
	cd $(PLUGIN_SUBMODULE)/deps/libff/build                                                               \
	    && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(BUILD_LOCAL) $(LIBFF_CMAKE_FLAGS) \
	    && make -s -j4                                                                                    \
	    && make install

# Build Dependencies (K Submodule)
# --------------------------------

K_JAR := $(K_SUBMODULE)/k-distribution/target/release/k/lib/java/kernel-1.0-SNAPSHOT.jar

deps: wasm-deps

wasm-deps:
	$(KWASM_MAKE) deps

# Building Definition
# -------------------

HOOK_NAMESPACES    := KRYPTO
KOMPILE_OPTS       := --hook-namespaces \"$(HOOK_NAMESPACES)\" --emit-json

ifneq (,$(K_COVERAGE))
    KOMPILE_OPTS += --coverage
endif

LLVM_KOMPILE_OPTS  := -L$(LOCAL_LIB)                               \
                      $(PLUGIN_SUBMODULE)/plugin-c/plugin_util.cpp \
                      $(PLUGIN_SUBMODULE)/plugin-c/crypto.cpp      \
                      $(PLUGIN_SUBMODULE)/plugin-c/blake2.cpp      \
                      -g -std=c++14 -lff -lcryptopp -lsecp256k1    \
                      -lssl -lcrypto -lprocps

MAIN_MODULE        := MANDOS
MAIN_SYNTAX_MODULE := MANDOS-SYNTAX
MAIN_DEFN_FILE     := mandos

ELROND_FILE_NAMES      := elrond.md                   \
                          elrond-config.md            \
                          elrond-node.md              \
                          auto-allocate.md            \
                          mandos.md                   \
                          wasm-coverage.md            \
                          $(wildcard vmhooks/*.md)

PLUGIN_FILE_NAMES      := blockchain-k-plugin/krypto.md
EXTRA_SOURCES          := $(ELROND_FILE_NAMES) $(PLUGIN_FILE_NAMES)
ELROND_FILES_KWASM_DIR := $(patsubst %,$(KWASM_SUBMODULE)/%,$(ELROND_FILE_NAMES))
PLUGIN_FILES_KWASM_DIR := $(patsubst %,$(KWASM_SUBMODULE)/%,$(PLUGIN_FILE_NAMES))

build: build-llvm

# Semantics Build
# ---------------
llvm_dir      := $(DEFN_DIR)/llvm
llvm_kompiled := $(llvm_dir)/mandos-kompiled/interpreter


build-llvm: $(llvm_kompiled)

$(llvm_kompiled): $(ELROND_FILES_KWASM_DIR) $(PLUGIN_FILES_KWASM_DIR) $(libff_out)
	$(KWASM_MAKE) build-llvm                             \
	    DEFN_DIR=../../$(DEFN_DIR)/$(SUBDEFN)            \
	    llvm_main_module=$(MAIN_MODULE)                  \
	    llvm_syntax_module=$(MAIN_SYNTAX_MODULE)         \
	    llvm_main_file=$(MAIN_DEFN_FILE)                 \
	    EXTRA_SOURCE_FILES="$(EXTRA_SOURCES)"            \
	    KOMPILE_OPTS="$(KOMPILE_OPTS)"                   \
	    LLVM_KOMPILE_OPTS="$(LLVM_KOMPILE_OPTS)"

$(KWASM_SUBMODULE)/%.md: %.md
	cp $< $@

$(KWASM_SUBMODULE)/blockchain-k-plugin/%.md: $(PLUGIN_SUBMODULE)/plugin/%.md
	@mkdir -p $(dir $@)
	cp $< $@

$(KWASM_SUBMODULE)/vmhooks/%.md: vmhooks/%.md
	@mkdir -p $(dir $@)
	cp $< $@

# Testing
# -------

KRUN_OPTS :=

# TODO add test-elrond-lottery-esdt
elrond-contract-deps := test-elrond-adder             \
                        test-elrond-crowdfunding-esdt \
                        test-elrond-multisig          \
                        test-elrond-basic-features
test-elrond-contracts: $(elrond-contract-deps)

test: test-simple mandos-test test-elrond-contracts test-custom-contracts

# Unit Tests
# ----------

TEST  := ./kelrond
CHECK := git --no-pager diff --no-index --ignore-all-space -R

TEST_CONCRETE_BACKEND:= llvm

tests/%.run: tests/%
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< $(KRUN_OPTS) > tests/$*.$(TEST_CONCRETE_BACKEND)-out
	rm -rf tests/$*.$(TEST_CONCRETE_BACKEND)-out

simple_tests := $(wildcard tests/simple/*.wast)

test-simple: $(simple_tests:=.run)

# Elrond Wasm Definitions
# -----------------------

ELROND_LOADED       := src/elrond-runtime.loaded.wat
ELROND_LOADED_JSON  := src/elrond-runtime.loaded.json
ELROND_RUNTIME_JSON := src/elrond-runtime.wat.json

elrond-loaded: $(ELROND_LOADED_JSON) $(ELROND_LOADED)

elrond-clean-sources:
	rm $(ELROND_RUNTIME_JSON) $(ELROND_LOADED_JSON)

$(ELROND_LOADED): $(ELROND_RUNTIME_JSON)
	$(TEST) run-legacy --backend $(TEST_CONCRETE_BACKEND) $< --parser cat > $(ELROND_LOADED)

$(ELROND_LOADED_JSON): $(ELROND_RUNTIME_JSON)
	$(TEST) run-legacy --backend $(TEST_CONCRETE_BACKEND) $< --parser cat --output json > $@

$(ELROND_RUNTIME_JSON):
	echo "setExitCode 0" | $(TEST) kast - json > $@

# Elrond Tests
# ------------

TEST_MANDOS := python3 run-elrond-tests.py


## Mandos Test

MANDOS_TESTS_DIR := tests/mandos
mandos_tests=$(sort $(wildcard $(MANDOS_TESTS_DIR)/*.scen.json))
mandos-test: $(llvm_kompiled)
	$(TEST_MANDOS) $(mandos_tests)

## Mandos Coverage
MANDOS_COV_DIR := tests/coverage
mandos_cov_tests=$(sort $(wildcard $(MANDOS_COV_DIR)/*.scen.json))

mandos-coverage: $(llvm_kompiled)
	$(TEST_MANDOS) $(mandos_cov_tests) --coverage > $(MANDOS_COV_DIR)/coverage.out
	$(CHECK) $(MANDOS_COV_DIR)/coverage.out $(MANDOS_COV_DIR)/coverage-expected.out
	rm $(MANDOS_COV_DIR)/coverage.out

## Adder Test

ELROND_ADDER_DIR := $(ELROND_CONTRACT_EXAMPLES)/adder
elrond_adder_tests=$(shell find $(ELROND_ADDER_DIR) -name "*.scen.json")

test-elrond-adder: $(llvm_kompiled)
	mxpy contract build "$(ELROND_ADDER_DIR)" --wasm-symbols
	$(TEST_MANDOS) $(elrond_adder_tests) --coverage


## Crowdfunding Test

ELROND_CROWDFUNDING_DIR := $(ELROND_CONTRACT_EXAMPLES)/crowdfunding-esdt
elrond_crowdfunding_tests=$(shell find $(ELROND_CROWDFUNDING_DIR) -name "*.scen.json")

test-elrond-crowdfunding-esdt: $(llvm_kompiled)
	mxpy contract build "$(ELROND_CROWDFUNDING_DIR)" --wasm-symbols
	$(TEST_MANDOS) $(elrond_crowdfunding_tests) --coverage

## Multisg Test

ELROND_MULTISIG_DIR=$(ELROND_CONTRACT_EXAMPLES)/multisig
elrond_multisig_tests=$(shell cat tests/multisig.test)

test-elrond-multisig: $(llvm_kompiled)
	mxpy contract build "$(ELROND_MULTISIG_DIR)" --wasm-symbols
	$(TEST_MANDOS) $(elrond_multisig_tests) --coverage

## Basic Feature Test

ELROND_BASIC_FEATURES_DIR=$(ELROND_CONTRACT)/feature-tests/basic-features
ELROND_BASIC_FEATURES_WASM=$(ELROND_BASIC_FEATURES_DIR)/output/basic-features.wasm
elrond_basic_features_tests=$(shell cat tests/basic_features.test)

$(ELROND_BASIC_FEATURES_WASM):
	mxpy contract build "$(ELROND_BASIC_FEATURES_DIR)" --wasm-symbols

# TODO optimize test runner and enable coverage and logging
test-elrond-basic-features: $(elrond_basic_features_tests:=.mandos)

$(ELROND_BASIC_FEATURES_DIR)/scenarios/%.scen.json.mandos: $(llvm_kompiled) $(ELROND_BASIC_FEATURES_WASM)
	$(TEST_MANDOS) $(ELROND_BASIC_FEATURES_DIR)/scenarios/$*.scen.json --log-level none

## Alloc Features Test

ELROND_ALLOC_FEATURES_DIR=$(ELROND_CONTRACT)/feature-tests/alloc-features
ELROND_ALLOC_FEATURES_WASM=$(ELROND_ALLOC_FEATURES_DIR)/output/alloc-features.wasm
elrond_alloc_features_tests=$(shell cat tests/alloc_features.test)

$(ELROND_ALLOC_FEATURES_WASM):
	mxpy contract build "$(ELROND_ALLOC_FEATURES_DIR)" --wasm-symbols

# TODO optimize test runner and enable coverage and logging
test-elrond-alloc-features: $(elrond_alloc_features_tests:=.mandos)

$(ELROND_ALLOC_FEATURES_DIR)/scenarios/%.scen.json.mandos: $(llvm_kompiled) $(ELROND_ALLOC_FEATURES_WASM)
	$(TEST_MANDOS) $(ELROND_ALLOC_FEATURES_DIR)/scenarios/$*.scen.json --log-level none

# Custom contract tests

custom-contracts := test-elrond-addercaller       \
                    test-elrond-callercallee
test-custom-contracts: $(custom-contracts)

## Adder Caller Test

ELROND_ADDERCALLER_DIR := tests/contracts/addercaller
elrond_addercaller_tests=$(shell find $(ELROND_ADDERCALLER_DIR) -name "*.scen.json")
ELROND_MYADDER_DIR := tests/contracts/myadder

test-elrond-addercaller: $(llvm_kompiled)
	mxpy contract build "$(ELROND_MYADDER_DIR)" --wasm-symbols
	mxpy contract build "$(ELROND_ADDERCALLER_DIR)" --wasm-symbols
	$(TEST_MANDOS) $(elrond_addercaller_tests) --coverage

## Caller Callee Test

ELROND_CALLER_DIR := tests/contracts/caller
ELROND_CALLEE_DIR := tests/contracts/callee
elrond_callercallee_tests=$(shell find $(ELROND_CALLER_DIR) -name "*.scen.json")

test-elrond-callercallee: $(llvm_kompiled)
	mxpy contract build "$(ELROND_CALLER_DIR)" --wasm-symbols
	mxpy contract build "$(ELROND_CALLEE_DIR)" --wasm-symbols
	$(TEST_MANDOS) $(elrond_callercallee_tests) --coverage

# Unit Tests
# ----------
PYTHON_UNITTEST_FILES = coverage.py
unittest-python: $(PYTHON_UNITTEST_FILES:=.unit)

%.unit: %
	python3 $<

rule-coverage:
	python3 rule_coverage.py $(llvm_dir)/mandos-kompiled $(ELROND_FILES_KWASM_DIR)

clean-coverage:
	rm $(llvm_dir)/mandos-kompiled/*_coverage.txt $(llvm_dir)/mandos-kompiled/coverage.txt
