Semantics of Elrond and Mandos
==============================

This repository the semantics of the [MultiversX](https://multiversx.com/) (formerly Elrond) blockchain in [K](https://github.com/runtimeverification/k) on top of WebAssembly semantics ([KWasm](https://github.com/kframework/wasm-semantics)).


## Installation

### Dependencies

* Python3
* [WABT v1.0.13](https://github.com/WebAssembly/wabt/tree/1.0.13)
* K Framework ([version](./deps/k_release))
* [Poetry](https://python-poetry.org/docs/#installing-with-the-official-installer)
* [Rustup and `sc-meta`](https://docs.multiversx.com/developers/meta/sc-meta)

### Installing Dependencies

Python3 and WABT should be installable via your system's package manager alongside with the follwoing other dependencies.
We use the Ubuntu package manager as an example:
```bash
sudo apt-get install --yes               \
                     autoconf            \
                     libtool             \
                     cmake               \
                     curl                \
                     wget                \
                     libcrypto++-dev     \
                     libprocps-dev       \
                     libsecp256k1-dev    \
                     libssl-dev          \
                     pandoc              \
                     python3             \
                     python3-pip         \
                     python3-venv        \
                     wabt
```

#### K Framework

You need to install the [K Framework](https://kframework.org/) on your system. While you can build it [from soucre](https://github.com/runtimeverification/k?tab=readme-ov-file#prerequisite-install-guide), the fastest way is via the [kup package manager](https://github.com/runtimeverification/kup).

To install `kup` simply run
```bash
bash <(curl https://kframework.org/install)
```
Once `kup` is installed, to get the correct version of K run:
```bash
kup install k.openssl.procps.secp256k1 --version v$(cat deps/k_release)
```

#### Poetry

To install Poetry you can use the following command
```bash
curl -sSL https://install.python-poetry.org | python3 -
```
For more complete instructions see the [official installer](https://python-poetry.org/docs/#installing-with-the-official-installer).

#### Rustup

To install Rust and the necessary crates you have to [install `rustup`](https://www.rust-lang.org/tools/install), which can be done by ruuning the following on a Unix-like OS:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
Or, if you want to install a more fine-tuned version for this project:
```bash
wget -O rustup.sh https://sh.rustup.rs && \
chmod +x rustup.sh && \
./rustup.sh --verbose --default-toolchain nightly-2023-12-11 --target wasm32-unknown-unknown -y
```

#### `sc-meta`

[`sc-meta`](https://docs.multiversx.com/developers/meta/sc-meta) is the [MultiversX](https://multiversx.com/) smart contract managing tool. To install it, you can run the following
```bash
cargo install multiversx-sc-meta --locked
```
However, if you run into problems with the above command, this might be because of your `rustup` version. Try installing it with a nightly version of `rustup` alongside your current one:
```bash
rustup install nightly
```
and to install `sc-meta` with the nightly version run:
```bash
cargo +nightly install multiversx-sc-meta --locked
```
If the above doesn't succeed try installing a [less recent version](https://crates.io/crates/multiversx-sc-meta/versions) of the tool. For instance, to install version `0.48.1` run:
```bash
cargo +nightly install multiversx-sc-meta --locked --version 0.48.1
```

See [Dockerfile](./Dockerfile) for additional installation details.

### Building the semantics

Compile the semantics with:

```shell
$ make build
```

It will build [`MANDOS`](./mandos.md) as the main module using the LLVM backend. The compiled definition will be placed under `./build/defn`.

Then the tests can be run with:

```shell
$ make test
```

### Installing `kmultiversx`

`kmultiversx` is a Python package providing libraries and CLI tools to interact with the semantics.
To install `kmultiversx` and its dependencies into a virtual environment, run

```
# from the 'elrond-semantics' directory
poetry -C kmultiversx install
```

After the installation, the Python package `kmultiversx` and CLI tools `mandos` and `kasmer` will be available via the `poetry run` command

```
poetry -C kmultiversx run mandos --help
poetry -C kmultiversx run kasmer --help
```

Or you can activate the virtual environment managed by `poetry` and use the commands directly

```
poetry -C kmultiversx shell
mandos --help
```

Alternatively, you can install `kmultiversx` globally

```
make -C kmultiversx build
pip install kmultiversx/dist/*.whl
mandos --help
kasmer --help
```

## Run

To run Mandos tests, first build the contract:

```shell
$ sc-meta all build "<path-to-contract-directory>" --wasm-symbols
```

Then run Mandos scenarios with:

```shell
poetry -C kmultiversx run mandos --definition .build/defn/llvm/mandos-kompiled <path-to-mandos-file>
```

Or with a globally installed instance

```shell
mandos --definition .build/defn/llvm/mandos-kompiled <path-to-mandos-file>
```

Example:

```shell
$ sc-meta all build "deps/mx-sdk-rs/contracts/examples/multisig" --wasm-symbols
...
INFO:projects.core:Build ran.
INFO:projects.core:WASM file generated: /path/to/multisig/output/multisig.wasm
$ mandos deps/mx-sdk-rs/contracts/examples/multisig/scenarios/changeBoard.scen.json
```

## Rule Coverage

Compile the semantics with `K_COVERAGE=true` to enable the coverage analysis. This will make `krun` generate coverage data after every execution:

```
$ make build K_COVERAGE=true
```

Execute the programs to measure rule coverage for:

```
$ make test
```

Run the coverage analysis. This will list the locations of the rules that are not exercised.

```
$ make -s rule-coverage
deps/wasm-semantics/elrond-config.md:163:10
deps/wasm-semantics/elrond-config.md:322:10
deps/wasm-semantics/elrond-config.md:324:10
...
```

The coverage files generated by `krun` are located under the build directory (`.build/defn/llvm/mandos-kompiled`). To clean up the coverage data generated, run `make clean-coverage`.

## Writing Property Tests

### Create a test contract

To begin writing tests for your smart contract, you'll first need to create an empty contract using __sc-meta__.

```shell
sc-meta new --template empty test_adder
```

Next, add [`testapi`](./src/testapi) as a dependency to your project. This package contains auxiliary external functions specifically designed for testing, implemented as WASM host functions.

```
$ cargo add <path to src/testapi/>
```

### Initializing the test contract

The testing API provides the test contract with special abilities that regular contracts do not have, such as accessing the storage of other contracts and deploying contracts using local WASM file paths.

We will use the `init` function to deploy the contract(s) involved in our test cases and create an initial state for running the test cases. This can be thought of as the equivalent of the `setState` and `scDeploy` steps in scenario tests.

```rs
fn init(&self, code_path: ManagedBuffer)
```

The `init` function takes a path to the contract's wasm file as an argument and utilizes the `testapi::deploy_contract function` to deploy it. This function works similarly to the `scDeploy` step in the scenario format.

```rs
let adder = testapi::deploy_contract(
        &owner,              // address of the owner account
        5000000000000,       // some gas
        &BigUint::zero(),    // value
        &code_path,          // path to wasm file
        &adder_init_args,
);
self.adder_address().set(&adder);
```

Once you've implemented the init function, it's essential to make sure the test runner knows the correct file path to use when deploying the test contract. To achieve this, you'll need to create a `kasmer.json` file in the root directory of your test contract. In this file, specify the relative path to the contract's WASM file that you want to deploy for testing.

For example, assuming your test contract is named `test_adder`, and you want to deploy the `adder.wasm` contract located in the ../../../deps/mx-sdk-rs/contracts/examples/adder/output/ directory, your `kasmer.json` file should look like this:

```json
{
  "contract_paths": [
    "../mx-sdk-rs/contracts/examples/adder/output/adder.wasm"
  ]
}
```

By providing the correct file path in the `kasmer.json` file, the test runner will be able to deploy the specified contract during the testing process. With the `init` function in place and the contract file path specified, you are now ready to write test cases in endpoints.

### Writing test cases in endpoints

In our testing approach, test cases are organized as endpoints, clearly labeled with the 'test_' prefix for easy identification.

```rs
#[endpoint(test_call_add)]
fn test_call_add(&self, value: BigUint)
```

These endpoints can accept parameters, enabling us to express the contract's properties parametrically by varying these variables. This flexibility allows us to execute tests with fuzzing techniques or prove them using symbolic execution.

Within each endpoint, we interact with the contract deployed during the `init` phase and employ the testing API to make specific assertions. These assertions serve as validation checks, ensuring that the contract behaves as intended and produces the expected outcomes during testing. 

In certain testing scenarios, it becomes necessary to simulate actions from another account. To achieve this, we employ a feature known as "pranks."

Pranks enable the test contract to act as another account temporarily. We initiate a prank by using the `testapi::start_prank(&acct_addr)` function, where `acct_addr` represents the address of the account we wish to impersonate. Once the prank is started, any calls made by the test contract will be executed as if they were sent from the specified `acct_addr`. This allows us to test various functionalities from the perspective of that particular account.

For instance, let's consider the following code snippet:

```rs
testapi::start_prank(&owner);
let res = self.send_raw().direct_egld_execute(
    &adder, 
    &BigUint::from(0u32), 
    5000000, 
    &ManagedBuffer::from(b"add"),
    &adder_init_args,
);
testapi::stop_prank();
```

In this example, we initiate a prank using the `owner` account address. Subsequently, we execute a call to the contract `adder` as if it were invoked from the `owner` account. Once the intended actions are completed, we stop the prank using `testapi::stop_prank()`.

After executing the call to the `adder` contract through a prank, it's common to observe changes in the contract's storage. To verify whether the expected changes have occurred, we can access the storage of the account using `testapi::get_storage`. In the following code snippet, we retrieve the value stored under the key "sum" in the storage of the `adder` contract:

```rs
let sum_as_bytes = testapi::get_storage(&adder, &ManagedBuffer::from(b"sum")); 
let sum = BigUint::from(sum_as_bytes);
```

Once we have obtained the stored value, we can then proceed to make assertions to verify its correctness. In this example, we are checking if the `sum` value is equal to the sum of the initial value (`INIT_SUM`) and the current `value`:

```rs
testapi::assert(sum == (value + INIT_SUM));
```

By combining pranks with storage access and assertions, we can comprehensively test the behavior of our Smart Contracts, ensuring their accuracy and robustness in various scenarios.

### Running tests

To run the tests for your Smart Contracts, ensure that you have fulfilled the following prerequisites:

1. Compile the semantics by executing `make build-kasmer`.
2. Add a `<path to adder contract>/multicontract.toml` file to the adder contract, something like:
    ```
    [settings]
    main = "main"

    [contracts.main]
    name = "adder"
    add-unlabelled = true
    allocator = "fail"
    stack-size = "1 pages"
    ```
    The stack-size should be as low as possible, while also allowing the contract
    to run without errors. Also, if the contract does not need it, the allocator
    should be "fail".
3. Compile the contract using `sc-meta all build <path to adder contract>`.
4. Install the `hypothesis` library by running `pip3 install hypothesis`. This library will be utilized for concrete execution with fuzzing.

Now, follow these steps to run the test contract:

Build the test contract by executing
```shell
sc-meta all build <path to test contract>
```


Run the `kasmer` tool with the test contract's path as the argument:

```shell
kasmer --definition-dir .build/defn/llvm/kasmer-kompiled --directory <path to test contract>
```

The `kasmer` tool will deploy the test contract using the arguments specified in the `kasmer.json` file located in the test directory. It will extract the names and argument types of the test endpoints. Subsequently, the script will test these endpoints using random inputs generated with the `hypothesis` library, enabling fuzz testing. If it encounters an input that falsifies the assertions made in the test cases, it attempts to shrink the input and identify a minimal failing example.

By following these steps, you can efficiently and comprehensively evaluate your Smart Contracts, ensuring their correctness and reliability in various scenarios and inputs.
