
.PHONY: all clean deps wasm-deps                                           \
        build build-llvm build-haskell                                     \
        elrond-contracts elrond-test elrond-loaded                         \
        elrond-contract-tests elrond-adder-test elrond-delegation-test     \
        test

# Settings
# --------

BUILD_DIR := .build
DEPS_DIR  := deps
DEFN_DIR  := $(BUILD_DIR)/defn
KWASM_SUBMODULE     := $(DEPS_DIR)/wasm-semantics
K_SUBMODULE         := $(KWASM_SUBMODULE)/deps/k
KWASM_BINARY_PARSER := $(KWASM_SUBMODULE)/binary-parser

ELROND_WASM_SUBMODULE  := $(DEPS_DIR)/elrond-wasm-rs
ELROND_ADDER_SUBMODULE := $(ELROND_WASM_SUBMODULE)/examples/adder

ELROND_DELEGATION_SUBMODULE := $(DEPS_DIR)/sc-delegation-rs

ifneq (,$(wildcard $(K_SUBMODULE)/k-distribution/target/release/k/bin/*))
    K_RELEASE ?= $(abspath $(K_SUBMODULE)/k-distribution/target/release/k)
else
    K_RELEASE ?= $(dir $(shell which kompile))..
endif
K_BIN := $(K_RELEASE)/bin
K_LIB := $(K_RELEASE)/lib/kframework
export K_RELEASE

PYTHONPATH := $(K_LIB):$(KWASM_BINARY_PARSER):$(PYTHONPATH)
export PYTHONPATH

KWASM_DIR  := .
KWASM_MAKE := make --directory $(KWASM_SUBMODULE) BUILD_DIR=../../$(BUILD_DIR) RELEASE=$(RELEASE)

export KWASM_DIR

all: build

clean:
	rm -rf $(BUILD_DIR)

# Build Dependencies (K Submodule)
# --------------------------------

K_JAR := $(K_SUBMODULE)/k-distribution/target/release/k/lib/java/kernel-1.0-SNAPSHOT.jar

deps: wasm-deps elrond-contracts

wasm-deps:
	$(KWASM_MAKE) deps

elrond-contracts:
	cd $(ELROND_WASM_SUBMODULE) && env RUSTFLAGS="" ./build-wasm.sh
	ls $(ELROND_ADDER_SUBMODULE)/output/adder.wasm

# Building Definition
# -------------------

KOMPILE_OPTS         := --emit-json

MAIN_MODULE        := MANDOS
MAIN_SYNTAX_MODULE := MANDOS-SYNTAX
MAIN_DEFN_FILE     := elrond

build: build-llvm

# Semantics Build
# ---------------

build-llvm: $(KWASM_SUBMODULE)/$(MAIN_DEFN_FILE).md
	$(KWASM_MAKE) build-llvm                             \
	    DEFN_DIR=../../$(DEFN_DIR)/$(SUBDEFN)            \
	    llvm_main_module=$(MAIN_MODULE)                  \
	    llvm_syntax_module=$(MAIN_SYNTAX_MODULE)         \
	    llvm_main_file=$(MAIN_DEFN_FILE)                 \
	    EXTRA_SOURCE_FILES=$(MAIN_DEFN_FILE).md          \
	    KOMPILE_OPTS="$(KOMPILE_OPTS)"

$(KWASM_SUBMODULE)/$(MAIN_DEFN_FILE).md: $(MAIN_DEFN_FILE).md
	cp $< $@

# Testing
# -------

KRUN_OPTS :=

elrond-contract-tests: elrond-adder-test elrond-delegation-test

test: test-simple elrond-test elrond-contract-tests

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
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< --parser cat > $(ELROND_LOADED)

$(ELROND_LOADED_JSON): $(ELROND_RUNTIME_JSON)
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< --parser cat --output json > $@

$(ELROND_RUNTIME_JSON):
	echo "setExitCode 0" | $(TEST) kast - json > $@

# Elrond Tests
# ------------

TEST_ELROND := python3 run-elrond-tests.py

ELROND_TESTS_DIR := tests/mandos
elrond_tests=$(sort $(wildcard $(ELROND_TESTS_DIR)/*.scen.json))
elrond-test: $(llvm_kompiled)
	$(TEST_ELROND) $(elrond_tests)

ELROND_ADDER_TESTS_DIR=$(ELROND_ADDER_SUBMODULE)/mandos
elrond_adder_tests=$(ELROND_ADDER_TESTS_DIR)/adder.scen.json
elrond-adder-test:
	$(TEST_ELROND) $(elrond_adder_tests) --coverage

elrond_delegation_tests=$(shell find $(ELROND_DELEGATION_SUBMODULE) -name "*.scen.json")
elrond-delegation-test:
	$(TEST_ELROND) $(elrond_delegation_tests) --coverage --log-level per-step
