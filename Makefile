
.PHONY: all clean deps wasm-deps                                           \
        build build-llvm build-haskell                                     \
        elrond-deps elrond-test elrond-loaded

# Settings
# --------

BUILD_DIR := .build
DEPS_DIR  := deps
DEFN_DIR  := $(BUILD_DIR)/defn
KWASM_SUBMODULE := $(DEPS_DIR)/wasm-semantics
K_SUBMODULE     := $(KWASM_SUBMODULE)/deps/k

ELROND_DELEGATION_SUBMODULE := $(DEPS_DIR)/sc-delegation-rs/v0_3

ifneq (,$(wildcard $(K_SUBMODULE)/k-distribution/target/release/k/bin/*))
    K_RELEASE ?= $(abspath $(K_SUBMODULE)/k-distribution/target/release/k)
else
    K_RELEASE ?= $(dir $(shell which kompile))..
endif
K_BIN := $(K_RELEASE)/bin
K_LIB := $(K_RELEASE)/lib/kframework
export K_RELEASE

KWASM_DIR  := .
KWASM_MAKE := make --directory $(KWASM_SUBMODULE) BUILD_DIR=../../$(BUILD_DIR) RELEASE=$(RELEASE)

export KWASM_DIR

all: build

clean:
	rm -rf $(BUILD_DIR)

# Build Dependencies (K Submodule)
# --------------------------------

K_JAR := $(K_SUBMODULE)/k-distribution/target/release/k/lib/java/kernel-1.0-SNAPSHOT.jar

deps: elrond-deps wasm-deps

elrond-deps:
	cd $(ELROND_DELEGATION_SUBMODULE) && rustup toolchain install nightly && rustup target add wasm32-unknown-unknown  && rustc --version && cargo install wasm-snip && cargo build

wasm-deps:
	$(KWASM_MAKE) deps

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

# Unit Tests
# ----------

TEST  := ./kelrond
CHECK := git --no-pager diff --no-index --ignore-all-space -R

TEST_CONCRETE_BACKEND:= llvm

llvm_kompiled := $(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE)-kompiled/compiled.txt

tests/%.run: tests/% $(llvm_kompiled)
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< > tests/$*.$(TEST_CONCRETE_BACKEND)-out
	rm -rf tests/$*.$(TEST_CONCRETE_BACKEND)-out

simple_tests := $(wildcard tests/simple/*.wast)

test-simple: $(simple_tests:=.run)

# Elrond Wasm Definitions
# -----------------------

ELROND_RUNTIME_JSON := src/elrond-runtime.wat.json
ELROND_LOADED       := src/elrond-runtime.loaded.wat
ELROND_LOADED_JSON  := src/elrond-runtime.loaded.json

elrond-loaded: $(ELROND_LOADED_JSON) $(ELROND_LOADED)

elrond-clean-sources:
	rm $(ELROND_RUNTIME_JSON) $(ELROND_LOADED_JSON)

$(ELROND_LOADED): $(ELROND_RUNTIME_JSON)
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< --parser cat > $(ELROND_LOADED)

$(ELROND_LOADED_JSON): $(ELROND_RUNTIME_JSON)
	$(TEST) run --backend $(TEST_CONCRETE_BACKEND) $< --parser cat --output json > $@

$(ELROND_RUNTIME_JSON):
	echo "noop" | $(TEST) kast - json > $@

# Elrond Tests
# ------------

ELROND_TESTS_DIR=$(ELROND_DELEGATION_SUBMODULE)/test/integration/main
elrond_tests=$(sort $(wildcard $(ELROND_TESTS_DIR)/*.steps.json))
elrond-test:
	python3 run-elrond-tests.py $(elrond_tests)

