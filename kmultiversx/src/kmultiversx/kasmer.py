from __future__ import annotations

import glob
import json
import sys
from os.path import join
from typing import TYPE_CHECKING, Iterable, Mapping, cast

import pyk.kllvm.load_static  # noqa: F401
from hypothesis import Phase, Verbosity, given, settings
from hypothesis.strategies import integers, tuples
from pyk.cterm import CTerm, cterm_build_claim
from pyk.kast.inner import KApply, KSequence, KSort, KVariable, Subst
from pyk.kast.manip import split_config_from
from pyk.kllvm.parser import parse_pattern
from pyk.konvert import _kast_to_kore
from pyk.kore.parser import KoreParser
from pyk.kore.syntax import App
from pyk.prelude.collections import list_of, map_of, set_of
from pyk.prelude.kint import leInt
from pyk.prelude.ml import mlEqualsTrue
from pyk.prelude.utils import token
from pyk.utils import ensure_dir_path
from pykwasm.kwasm_ast import KInt

from kmultiversx.scenario import (
    KList,
    KMapBytesToBytes,
    KWasmString,
    ListBytes,
    get_steps_sc_call,
    mandos_argument_to_kbytes,
    wrapBytes,
)
from kmultiversx.utils import (
    KasmerRunError,
    kast_to_json_str,
    krun_config,
    llvm_interpret_raw,
    load_wasm,
    read_kasmer_runtime,
)

if TYPE_CHECKING:
    from pathlib import Path

    from hypothesis.strategies import SearchStrategy
    from pyk.kast.inner import KInner
    from pyk.kast.outer import KClaim
    from pyk.kore.syntax import Pattern
    from pyk.ktool.kprint import KPrint
    from pyk.ktool.krun import KRun

INPUT_FILE_NAME = 'kasmer.json'
TEST_PREFIX = 'test_'

ROOT_ACCT_ADDR = 'address:k'
TEST_SC_ADDR = 'sc:k-test'

REC_LIMIT = 4000


def load_input_json(test_dir: str) -> dict:
    try:
        with open(join(test_dir, INPUT_FILE_NAME), 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f'{INPUT_FILE_NAME!r} not found in "{test_dir!r}"') from None


def find_test_wasm_path(test_dir: str) -> str:
    test_wasm_path = glob.glob(test_dir + '/output/*.wasm')
    # TODO this loads the first wasm file in the directory. what if there are multiple wasm files?
    if test_wasm_path:
        return test_wasm_path[0]
    else:
        raise ValueError(f'WASM file not found: {test_dir}/output/?.wasm')


def load_contract_wasms(contract_wasm_paths: Iterable[str]) -> dict[bytes, KInner]:
    contract_wasm_modules = {bytes(f, 'ascii'): load_wasm(f) for f in contract_wasm_paths}

    return contract_wasm_modules


def set_exit_code(i: int) -> KInner:
    return KApply('setExitCode', [KInt(i)])


def deploy_test(krun: KRun, test_wasm: KInner, contract_wasms: dict[bytes, KInner]) -> tuple[KInner, dict[str, KInner]]:
    """
    1. create a main account: 'k'
    2. reserve a new address for the test contract: owner = 'k', contract address = 'k-test'
    3. deploy the test contract from account 'k': 'k-test'
    """
    # create the root account
    k_addr = mandos_argument_to_kbytes(ROOT_ACCT_ADDR)
    init_main_acct = KApply(
        'setAccount',
        [
            k_addr,
            token(1),
            token(100000),
            KApply('.Code', []),
            token(b''),
            KMapBytesToBytes([]),
        ],
    )

    # the test contract's address will be 'k-test'
    k_test_addr = mandos_argument_to_kbytes(TEST_SC_ADDR)
    new_address = KApply('newAddress', [k_addr, token(1), k_test_addr])

    # deploy the test contract
    arguments = ListBytes(wrapBytes(token(k)) for k in contract_wasms)
    gas = token(5000000000000)
    deploy_cmd = KApply('deployTx', [k_addr, token(0), test_wasm, arguments, gas, token(0)])

    # initialization steps
    init_steps = KSequence(
        [
            set_exit_code(1),
            init_main_acct,
            new_address,
            deploy_cmd,
            KApply(
                'checkExpectStatus',
                [KApply('OK', [])],
            ),
            set_exit_code(0),
        ]
    )

    # create an empty config and embed init steps
    empty_conf = read_kasmer_runtime()

    conf, subst = split_config_from(empty_conf)
    subst['K_CELL'] = init_steps
    subst['WASMSTORE_CELL'] = map_of({cast('KInner', token(path)): mod for path, mod in contract_wasms.items()})
    conf_with_steps = Subst(subst)(conf)

    _, sym_conf, subst = run_config_and_check_empty(krun, conf_with_steps)

    subst['WASMSTORE_CELL'] = map_of({})
    return sym_conf, subst


def run_config_and_check_empty(
    krun: KRun, conf: KInner, pipe_stderr: bool = False
) -> tuple[KInner, KInner, dict[str, KInner]]:
    final_conf = krun_config(krun, conf, pipe_stderr=pipe_stderr)
    sym_conf, subst = split_config_from(final_conf)
    k_cell = subst['K_CELL']
    if not isinstance(k_cell, KSequence) or k_cell.arity != 0:
        print(krun.pretty_print(k_cell))
        raise KasmerRunError(
            k_cell=subst['K_CELL'],
            vm_output=subst['VMOUTPUT_CELL'],
            logging=subst['LOGGING_CELL'],
            final_conf=final_conf,
            message='k cell not empty',
        )

    return final_conf, sym_conf, subst


def run_pattern_and_check_exit_code(krun: KRun, conf: Pattern, pipe_stderr: bool = False) -> None:
    res = llvm_interpret_raw(krun.definition_dir, conf.text, pipe_stderr)

    if res.returncode != 0:
        kast_conf = krun.kore_to_kast(KoreParser(res.stdout).pattern())
        sym_conf, subst = split_config_from(kast_conf)
        k_cell = subst['K_CELL']
        print(krun.pretty_print(k_cell))
        raise KasmerRunError(
            k_cell=subst['K_CELL'],
            vm_output=subst['VMOUTPUT_CELL'],
            logging=subst['LOGGING_CELL'],
            final_conf=kast_conf,
            message='exit status is non-zero',
        )


K_STEPS_VAR_KAST = KVariable('K_STEPS')
K_STEPS_VAR_KORE = _kast_to_kore(K_STEPS_VAR_KAST)


def run_test(krun: KRun, sym_conf: Pattern, endpoint: str, args: tuple[str, ...]) -> None:
    step = {
        'tx': {
            'from': ROOT_ACCT_ADDR,
            'to': TEST_SC_ADDR,
            'function': endpoint,
            'value': '0',
            'arguments': args,
            'gasLimit': '5,000,000,000',
            'gasPrice': '0',
        },
        'expect': {'status': '0'},
    }
    tx_steps = KSequence([set_exit_code(1)] + get_steps_sc_call(step) + [set_exit_code(0)])

    def subst_k_cell(p: Pattern) -> Pattern:
        if p == K_STEPS_VAR_KORE:
            return krun.kast_to_kore(tx_steps)
        return p

    test_conf = sym_conf.top_down(subst_k_cell)

    try:
        run_pattern_and_check_exit_code(krun, test_conf, pipe_stderr=True)
    except RuntimeError as rte:
        if rte.args[0].startswith('Command krun exited with code 1'):
            raise RuntimeError(f'Test failed for input input: {args}') from None
        raise rte


# Test metadata


def get_test_endpoints(test_dir: str) -> Mapping[str, tuple[str, ...]]:
    abi_paths = glob.glob(test_dir + '/output/*.abi.json')
    # TODO this loads the first wasm file in the directory. what if there are multiple wasm files?
    if abi_paths:
        abi_path = abi_paths[0]
    else:
        raise ValueError(f'ABI file not found: {test_dir}/output/?.abi.json')

    with open(abi_path, 'r') as f:
        abi_json = json.load(f)

    endpoints = {}
    for endpoint in abi_json['endpoints']:
        name = endpoint['name']
        if not name.startswith(TEST_PREFIX):
            continue

        inputs = tuple(i['type'] for i in endpoint['inputs'])

        endpoints[name] = inputs

    return endpoints


# Hypothesis strategies


def type_to_strategy(typ: str) -> SearchStrategy[str]:
    if typ == 'BigUint':
        return integers(min_value=0).map(str)
    if typ == 'u32':
        return integers(min_value=0, max_value=4294967295).map(str)
    if typ == 'u64':
        return integers(min_value=0, max_value=18446744073709551615).map(str)
    raise TypeError(f'Cannot create random {typ}')


def arg_types_to_strategy(types: Iterable[str]) -> SearchStrategy[tuple[str, ...]]:
    strs = (type_to_strategy(t) for t in types)
    return tuples(*strs)


# Hypothesis test runner


def test_with_hypothesis(krun: KRun, sym_conf: Pattern, endpoint: str, arg_types: Iterable[str], verbose: bool) -> None:
    def test(args: tuple[str, ...]) -> None:
        # set the recursion limit every time because hypothesis changes it
        if sys.getrecursionlimit() < REC_LIMIT:
            sys.setrecursionlimit(REC_LIMIT)

        try:
            run_test(krun, sym_conf, endpoint, args)
        except KasmerRunError as kre:
            message = 'Test failed:'
            message += f'\n\tendpoint: {endpoint}'
            message += f'\n\tvm output: {krun.pretty_print(kre.vm_output)}'
            message += f'\n\tlogging: {krun.pretty_print(kre.logging)}'

            if verbose:
                message += f'\n\tfinal configuration: {krun.pretty_print(kre.final_conf)}'

            raise ValueError(message) from None

    test.__name__ = endpoint  # show endpoint name in hypothesis logs

    args_strategy = arg_types_to_strategy(arg_types)
    given(args_strategy)(
        settings(
            deadline=50000,  # set time limit for individual runs
            max_examples=50,
            verbosity=Verbosity.verbose,
            phases=(Phase.generate, Phase.target, Phase.shrink),
        )(test)
    )()


def run_concrete(
    krun: KRun,
    test_endpoints: Mapping[str, tuple[str, ...]],
    sym_conf: KInner,
    init_subst: dict[str, KInner],
    verbose: bool = False,
) -> None:
    subst = init_subst.copy()
    subst['K_CELL'] = K_STEPS_VAR_KAST
    init_conf = Subst(subst)(sym_conf)
    conf_with_var = krun.kast_to_kore(init_conf)

    if isinstance(conf_with_var, App) and conf_with_var.symbol == 'inj':
        # kast_to_kore for some reason sometimes makes a sort injection for the generatedTop cell, which the llvm interpreter rejects
        conf_with_var = conf_with_var.args[0]

    for endpoint, arg_types in test_endpoints.items():
        print(f'Testing {endpoint !r}')
        test_with_hypothesis(krun, conf_with_var, endpoint, arg_types, verbose)
        print(f'Passed {endpoint !r}')


# Claim generation


def generate_claims(
    kprint: KPrint,
    test_endpoints: Mapping[str, tuple[str, ...]],
    sym_conf: KInner,
    init_subst: dict[str, KInner],
    output_dir: Path,
    pretty_print: bool = False,
) -> None:
    output_dir = ensure_dir_path(output_dir)

    for endpoint, arg_types in test_endpoints.items():
        claim, _, _ = generate_claim(endpoint, arg_types, sym_conf, init_subst)

        if pretty_print:
            txt = kprint.pretty_print(claim)
            ext = 'k'
        else:
            txt = kast_to_json_str(claim)
            ext = 'json'

        output_file = output_dir / f'{endpoint}-spec.{ext}'
        output_file.write_text(txt)


def generate_claim(
    func: str,
    arg_types: tuple[str, ...],
    sym_conf: KInner,
    init_subst: dict[str, KInner],
) -> tuple[KClaim, CTerm, CTerm]:
    root_acc = mandos_argument_to_kbytes(ROOT_ACCT_ADDR)
    test_sc = mandos_argument_to_kbytes(TEST_SC_ADDR)
    vars, ctrs = make_vars_and_constraints(arg_types)
    args = vars_to_bytes_list(vars)
    steps = KSequence(
        [
            set_exit_code(1),
            KApply(
                'callTx',
                (
                    root_acc,
                    test_sc,
                    KInt(0),
                    KList([]),
                    KWasmString(func),
                    args,
                    KInt(5000000000),
                    KInt(0),
                ),
            ),
            KApply(
                'checkExpectStatus',
                [KApply('OK', [])],
            ),
            set_exit_code(0),
        ]
    )

    lhs_subst = build_lhs_subst(init_subst, steps)
    conf_with_steps = Subst(lhs_subst)(sym_conf)
    lhs = CTerm(conf_with_steps, [mlEqualsTrue(c) for c in ctrs])

    rhs_subst = build_rhs_subst(lhs_subst)
    conf_rhs = Subst(rhs_subst)(sym_conf)
    rhs = CTerm(conf_rhs)

    claim, _ = cterm_build_claim(f'{func}', lhs, rhs)

    return claim, lhs, rhs


def build_lhs_subst(init_subst: dict[str, KInner], steps: KInner) -> dict[str, KInner]:
    subst = init_subst.copy()

    subst['K_CELL'] = steps
    subst['CHECKEDACCOUNTS_CELL'] = set_of(())
    subst['COMMANDS_CELL'] = KSequence()
    subst['INSTRS_CELL'] = KSequence()
    subst['CALLSTACK_CELL'] = list_of(())
    subst['INTERIMSTATES_CELL'] = list_of(())
    subst['VMOUTPUT_CELL'] = KVariable('VMOUTPUT_CELL', 'VMOutput')
    subst['LOGGING_CELL'] = KVariable('LOGGING_CELL', 'String')
    subst['EXIT_CODE_CELL'] = token(0)
    subst['PRANK_CELL'] = token(False)

    return subst


def build_rhs_subst(rhs_subst: dict[str, KInner]) -> dict[str, KInner]:
    # start from RHS
    subst = rhs_subst.copy()

    # ignore
    del subst['ACCOUNTS_CELL']
    del subst['LOGS_CELL']
    del subst['PREVBLOCKTIMESTAMP_CELL']
    del subst['PREVBLOCKNONCE_CELL']
    del subst['PREVBLOCKROUND_CELL']
    del subst['PREVBLOCKEPOCH_CELL']
    del subst['PREVBLOCKRANDOMSEED_CELL']
    del subst['CURBLOCKTIMESTAMP_CELL']
    del subst['CURBLOCKNONCE_CELL']
    del subst['CURBLOCKROUND_CELL']
    del subst['CURBLOCKEPOCH_CELL']
    del subst['CURBLOCKRANDOMSEED_CELL']
    del subst['TXCOUNT_CELL']
    subst['VMOUTPUT_CELL'] = KVariable('VMOUTPUT_CELL_R', 'VMOutput')
    subst['LOGGING_CELL'] = KVariable('LOGGING_CELL_R', 'String')

    # expect
    subst['K_CELL'] = KSequence()
    subst['CHECKEDACCOUNTS_CELL'] = set_of(())
    subst['COMMANDS_CELL'] = KSequence()
    subst['INSTRS_CELL'] = KSequence()
    subst['CALLSTACK_CELL'] = list_of(())
    subst['INTERIMSTATES_CELL'] = list_of(())
    subst['PRANK_CELL'] = token(False)
    subst['EXIT_CODE_CELL'] = token(0)

    return subst


def vars_to_bytes_list(vars: tuple[KVariable, ...]) -> KInner:
    return ListBytes(wrapBytes(var_to_bytes(var)) for var in vars)


def var_to_bytes(var: KVariable) -> KInner:
    sort = var.sort

    if sort == KSort('Int'):
        return KApply(
            'Int2Bytes(_,_,_)_BYTES-HOOKED_Bytes_Int_Endianness_Signedness',  # TODO add the 'symbol' attribute in domains.md to have a readable name
            [
                var,
                KApply('bigEndianBytes', ()),
                KApply('signedBytes', ()),
            ],
        )

    raise TypeError(f'Cannot convert sort {sort} to Bytes')


def make_vars_and_constraints(types: tuple[str, ...]) -> tuple[tuple[KVariable, ...], tuple[KInner, ...]]:
    vars: tuple[KVariable, ...] = ()
    ctrs: tuple[KInner, ...] = ()
    for i, typ in enumerate(types):
        var, ctr = make_var_and_constraints(f'ARG_{i}', typ)
        vars = vars + (var,)
        ctrs = ctrs + ctr

    return vars, ctrs


def make_var_and_constraints(id: str, typ: str) -> tuple[KVariable, tuple[KInner, ...]]:
    """
    Create a K variable and constraints from a type
    """

    sort = type_to_sort(typ)
    var = KVariable(id, sort)
    ctrs = type_to_constraint(typ, var)

    return var, ctrs


def type_to_sort(typ: str) -> KSort:
    if typ == 'BigUint':
        return KSort('Int')
    if typ == 'u32':
        return KSort('Int')
    if typ == 'u64':
        return KSort('Int')
    raise TypeError(f'Unsupported type {typ}')


def type_to_constraint(typ: str, var: KVariable) -> tuple[KInner, ...]:
    if typ == 'BigUint':
        return (leInt(KInt(0), var),)
    if typ == 'u32':
        return (leInt(KInt(0), var), leInt(var, KInt(4294967295)))
    if typ == 'u64':
        return (leInt(KInt(0), var), leInt(var, KInt(18446744073709551615)))
    raise TypeError(f'Unsupported type {typ}')
