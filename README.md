Semantics of Elrond and Mandos
==============================

This repository is work-in-progress, and currently a fork of [KWasm](https://github.com/kframework/wasm-semantics).

Elrond-specific code is in `elrond.md` and `run-elrond-tests.py`.

Dependencies
------------

For running tests in the Mandos JSON format:

* Python3
* WABT (see Dockerfile for installation)

Build and Run
-------------

Follow the "Installing/Building" instructions below, for KWasm.
Instead of building the KWasm test embedder, it will build the `MANDOS` module as the main module.

**Important**: Some KWasm functionality is broken, such as running the `tests/simple` tests.

After building, make the Elrond dependencies:

```
make elrond-deps
```

Then the tests can be run with:

```
make elrond-test
```

If you modify the Wasm contracts in Erlond, or update the K files, you should re-build the pre-made sources:

```
make elrond-loaded
```
