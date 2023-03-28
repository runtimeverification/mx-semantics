Semantics of Elrond and Mandos
==============================

This repository is work-in-progress, and currently a fork of [KWasm](https://github.com/kframework/wasm-semantics).

Elrond-specific code is in `elrond.md` and `run-elrond-tests.py`.

## Installation

### Dependencies

* Python3
* WABT
* K framework ([version](./deps/wasm-semantics/deps/k_release))
* `pyk` ([version](./deps/wasm-semantics/deps/pyk_release))
* Crypto++
* Rustup
* [mxpy](https://docs.multiversx.com/sdk-and-tools/sdk-py/installing-mxpy/)

See [Dockerfile](./Dockerfile) for installation.

### Build

Compile the semantics with:

```shell
$ make build
```

It will build [`MANDOS`](./mandos.md) as the main module using the LLVM backend. The compiled definition will be placed under `./build/defn`.

Then the tests can be run with:

```shell
$ make test
```

If you modify the K files, you should re-build the pre-made sources:

```shell
$ make elrond-clean-sources
$ make elrond-loaded
```

### Run

To run Mandos tests, first build the contract:

```shell
$ mxpy contract build "<path-to-contract-directory>" --wasm-symbols
```

Then run Mandos scenarios with:

```shell
$ python3 run-elrond-tests.py <path-to-mandos-file>
```

__Important__: `run-elrond-tests.py` makes use of Python modules implemented in the `wasm-semantics` submodule. For the time being, it requires setting the `PYTHONPATH` environment variable.

```shell
$ export PYTHONPATH=$(pwd)/deps/wasm-semantics/binary-parser:$PYTHONPATH
```

Example:

```shell
$ mxpy contract build "deps/mx-sdk-rs/contracts/examples/multisig" --wasm-symbols
...
INFO:projects.core:Build ran.
INFO:projects.core:WASM file generated: /path/to/multisig/output/multisig.wasm
$ python3 run-elrond-tests.py deps/mx-sdk-rs/contracts/examples/multisig/scenarios/changeBoard.scen.json
```

Pass `--coverage` flag (and possibly multiple scenario files) for coverage analysis:

```shell
$ python3 run-elrond-tests.py --coverage \
    deps/mx-sdk-rs/contracts/examples/multisig/scenarios/changeBoard.scen.json          \
    deps/mx-sdk-rs/contracts/examples/multisig/scenarios/changeQuorum.scen.json         \
    deps/mx-sdk-rs/contracts/examples/multisig/scenarios/changeQuorum_tooBig.scen.json  \
```
