import argparse
import glob
from os.path import join
from subprocess import CompletedProcess
from typing import Mapping

from hypothesis import given, settings, Verbosity
from hypothesis.strategies import integers, tuples
from pyk.prelude.utils import token
from pyk.prelude.collections import list_of, map_of
from pyk.kast.inner import KSort, KVariable
from pyk.kast.kast import kast_term
from pyk.kore.syntax import Pattern
from pyk.ktool.kprint import _kast, KAstInput, KAstOutput
from pyk.ktool.krun import _krun, KRunOutput
from pyk.cterm import CTerm, build_claim
from pyk.utils import ensure_dir_path
from pyk.prelude.kint import leInt
from pyk.prelude.ml import mlEqualsTrue

from run_elrond_tests import *

INPUT_FILE_NAME = 'foundry.json'

def load_input_json(test_dir):
    try:
        with open(join(test_dir, INPUT_FILE_NAME), 'r') as f:
            return json.load(f)
    except FileNotFoundError as e:
        raise FileNotFoundError('"{INPUT_FILE_NAME}" not found in "{test_dir}"')


def load_wasm(filename):
    with open(filename, 'rb') as f:
        return wasm2kast.wasm2kast(f, filename)


def find_test_wasm_path(test_dir):
    test_wasm_path = glob.glob(test_dir + '/output/*.wasm')
    # TODO this loads the first wasm file in the directory. what if there are multiple wasm files?
    if test_wasm_path:
        return test_wasm_path[0]
    else:
        raise ValueError(f'WASM file not found: {test_dir}/output/?.wasm')


def load_contract_wasms(contract_wasm_paths):
    contract_wasm_modules = {
        bytes(f, 'ascii'): load_wasm(f) for f in contract_wasm_paths
    }
    return contract_wasm_modules


def deploy_test(krun, test_wasm, contract_wasms):
    """
    1. create a main account: 'k'
    2. reserve a new address for the test contract: owner = 'k', contract address = 'k-test'
    3. deploy the test contract from account 'k': 'k-test'
    """
    # create the root account
    k_addr = mandos_argument_to_kbytes('address:k')
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
    k_test_addr = mandos_argument_to_kbytes('sc:k-test')
    new_address = KApply('newAddress', [k_addr, token(1), k_test_addr])

    # deploy the test contract
    arguments = ListBytes(wrapBytes(token(k)) for k in contract_wasms)
    gas = token(5000000000000)
    deploy_cmd = KApply(
        'deployTx', [k_addr, token(0), test_wasm, arguments, gas, token(0)]
    )

    # initialization steps
    init_steps = KSequence([init_main_acct, new_address, deploy_cmd])

    # create an empty config and embed init steps
    empty_conf = krun.definition.init_config(KSort('GeneratedTopCell'))

    conf, subst = split_config_from(empty_conf)
    subst['K_CELL'] = init_steps
    subst['WASMSTORE_CELL'] = map_of(
        {token(path): mod for path, mod in contract_wasms.items()}
    )
    conf_with_steps = Subst(subst)(conf)

    _, sym_conf, subst = run_config_and_check_empty(krun, conf_with_steps)

    subst['WASMSTORE_CELL'] = map_of({})

    return sym_conf, subst

def run_config(krun: KRun, conf: KInner, log=False) -> CompletedProcess:
    with krun._temp_file() as fkast:
        conf_dict = { 'format': 'KAST', 'version': 2, 'term': conf.to_dict() }
        json.dump(conf_dict, fkast)
        fkast.flush()

        kast_res = _kast(
            fkast.name,
            sort='GeneratedTopCell',
            input=KAstInput.JSON,
            output=KAstOutput.KORE,
            check=True,
            definition_dir=krun.definition_dir,
        )
        if log:
            print(kast_res.stdout)
        with krun._temp_file() as ntf:
            ntf.write(kast_res.stdout)
            ntf.flush()

            return _krun(
                command=krun.command,
                input_file=Path(ntf.name),
                definition_dir=krun.definition_dir,
                output=KRunOutput.JSON,
                parser='cat',
                term=True,
                check=False,
                pipe_stderr=True,
            )


def parse_proc_res(proc_res: CompletedProcess) -> KInner:
    return kast_term(json.loads(proc_res.stdout), KInner)


def run_config_and_check_empty(krun: KRun, conf: KInner) -> tuple[KInner, KInner, dict[str, KInner]]:
    final_conf = parse_proc_res(run_config(krun, conf))
    sym_conf, subst = split_config_from(final_conf)
    k_cell = subst['K_CELL']
    if not isinstance(k_cell, KSequence) or k_cell.arity != 0:
        print(krun.pretty_print(subst['VMOUTPUT_CELL']), file=sys.stderr)
        print(krun.pretty_print(subst['K_CELL']), file=sys.stderr)
        raise ValueError(f'k cell not empty:\n { krun.pretty_print(final_conf) }')

    return final_conf, sym_conf, subst


def run_test(krun: KRun, sym_conf, init_subst, endpoint, args):
    step = {
        'tx': {
            'from': 'address:k',
            'to': 'sc:k-test',
            'function': endpoint,
            'value': '0',
            'arguments': args,
            'gasLimit': '5,000,000,000',
            'gasPrice': '0',
        },
        'expect': {'status': '0'},
    }
    tx_steps = KSequence([KApply('setExitCode', [KInt(1)])] + get_steps_sc_call(step) + [KApply('setExitCode', [KInt(0)])])
    
    subst = init_subst.copy()
    subst['K_CELL'] = tx_steps
    conf_with_steps = Subst(subst)(sym_conf)
    
    proc_res = run_config(krun, conf_with_steps)
    if proc_res.returncode:
        raise RuntimeError(f'Run failed: {args}')
    
# Test metadata
TEST_PREFIX = 'test_'


def get_test_endpoints(test_dir: str) -> Mapping[str, tuple[str, ...]]:
    abi_path = glob.glob(test_dir + '/output/*.abi.json')
    # TODO this loads the first wasm file in the directory. what if there are multiple wasm files?
    if abi_path:
        abi_path = abi_path[0]
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


def type_to_strategy(typ: str):
    if typ == 'BigUint':
        return integers(min_value=0).map(str)
    if typ == 'u32':
        return integers(min_value=0, max_value=4294967295).map(str)
    raise TypeError(f'Cannot create random {typ}')


def arg_types_to_strategy(types):
    strs = (type_to_strategy(t) for t in types)
    return tuples(*strs)


def test_with_hypothesis(krun, sym_conf, init_subst, endpoint, arg_types):
    def test(args):
        run_test(krun, sym_conf, init_subst, endpoint, args)

    test.__name__ = endpoint  # show endpoint name in hypothesis logs

    args_strategy = arg_types_to_strategy(arg_types)
    given(args_strategy)(
        settings(
            deadline=50000,  # set time limit for individual runs
            max_examples=10,  # enough for demo
            verbosity=Verbosity.verbose,
        )(test)
    )()


# Claim generation

def generate_claims(
    krun: KRun,
    test_endpoints: Mapping[str, tuple[str, ...]],
    sym_conf: KInner,
    init_subst: KInner,
    output_dir: Path,
):
    output_dir = ensure_dir_path(output_dir)

    for endpoint, arg_types in test_endpoints.items():
        claim = generate_claim(endpoint, arg_types, sym_conf, init_subst)

        output_file = output_dir / f'{endpoint}-spec.k'
        
        txt = krun.pretty_print(claim) # TODO wrap this in a spec module with imports

        with open(output_file, 'w') as output_file:

            output_file.write(txt)


def generate_claim(func: str, arg_types: tuple[str, ...], sym_conf, init_subst):
    root_acc = mandos_argument_to_kbytes('address:k')
    test_sc = mandos_argument_to_kbytes('sc:test')
    vars, ctrs = make_vars_and_constraints(arg_types)
    args = vars_to_bytes_list(vars)
    steps = KSequence(
        [
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
        ]
    )

    conf_with_steps = Subst(lhs_subst(init_subst, steps))(sym_conf)

    lhs = CTerm(conf_with_steps, [mlEqualsTrue(c) for c in ctrs])

    conf_rhs = Subst(rhs_subst(init_subst))(sym_conf)
    rhs = CTerm(conf_rhs)

    claim, _ = build_claim(f'{func}', lhs, rhs)

    return claim


def lhs_subst(init_subst, steps):
    
    subst = {
        'K_CELL': steps,
        'CHECKEDACCOUNTS_CELL': set_of(()),
        'COMMANDS_CELL': KSequence(),
        'INSTRS_CELL': KSequence(),
        'CALLSTACK_CELL': list_of(()),
        'INTERIMSTATES_CELL': list_of(()),
        'EXITCODE_CELL': KInt(0),
        'PRANK_CELL': KToken('false', KSort('Bool')),
    }
    
    copy_cells = [
        'NEWADDRESSES_CELL',
        'ACCOUNTS_CELL',
        'PREVBLOCKEPOCH_CELL',
        'PREVBLOCKNONCE_CELL',
        'PREVBLOCKRANDOMSEED_CELL',
        'PREVBLOCKROUND_CELL',
        'PREVBLOCKTIMESTAMP_CELL',
        'CURBLOCKEPOCH_CELL',
        'CURBLOCKNONCE_CELL',
        'CURBLOCKRANDOMSEED_CELL',
        'CURBLOCKROUND_CELL',
        'CURBLOCKTIMESTAMP_CELL',
    ]
    
    for c in copy_cells:
        subst[c] = init_subst[c]
    
    return subst


def rhs_subst(init_subst):
    
    subst = {
        'K_CELL': KSequence(),
        'CHECKEDACCOUNTS_CELL': set_of(()),
        'COMMANDS_CELL': KSequence(),
        'INSTRS_CELL': KSequence(),
        'CALLSTACK_CELL': list_of(()),
        'INTERIMSTATES_CELL': list_of(()),
        'PRANK_CELL': KToken('false', KSort('Bool')),
    }

    return subst


def vars_to_bytes_list(vars: tuple[KVariable, ...]) -> tuple[KInner, ...]:
    return ListBytes(var_to_byte(var) for var in vars)


def var_to_byte(var: KVariable):
    sort = var.sort

    if sort == KSort('Int'):
        return KApply(
            'Int2Bytes',
            [
                var,
                KToken('BE', 'Endianness'),
                KToken('Signed', 'Signedness'),
            ],
        )

    raise TypeError(f'Cannot convert sort {sort} to Bytes')


def make_vars_and_constraints(
    types: tuple[str, ...]
) -> tuple[tuple[KVariable, ...], tuple[KInner, ...]]:
    vars: tuple[KVariable, ...] = ()
    ctrs: tuple[KInner, ...] = ()
    for i, typ in enumerate(types):
        var, ctr = make_var_and_constraints(f'ARG_{i}', typ)
        vars = vars + (var,)
        ctrs = ctrs + ctr

    return vars, ctrs


def make_var_and_constraints(id: str, typ: str) -> tuple[KVariable, tuple[KInner, ...]]:
    '''
    Create a K variable and constraints from a type
    '''
    sort = type_to_sort(typ)
    var = KVariable(id, sort)
    ctrs = type_to_constraint(typ, var)

    return var, ctrs


def type_to_sort(typ: str):
    if typ == 'BigUint':
        return KSort('Int')
    if typ == 'u32':
        return KSort('Int')
    raise TypeError(f'Unsupported type {typ}')


def type_to_constraint(typ: str, var: KVariable) -> tuple[KInner, ...]:
    if typ == 'BigUint':
        return (leInt(KInt(0), var),)
    if typ == 'u32':
        return (leInt(KInt(0), var), leInt(var, KInt(4294967295)))
    raise TypeError(f'Unsupported type {typ}')


# Main Script

DESCRIPTION = '''
Concrete execution for MultiversX Foundry-like tests.
This is not the intended front-end of the tool, it is for developers\' use only.
'''


def main():
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument(
        '-d', '--directory', required=True, help='path to the test contract'
    )
    parser.add_argument(
        '--gen-claims',
        dest='gen_claims',
        action='store_true',
        help='generate claims for symbolic testing',
    )
    parser.add_argument(
        '--output-dir',
        dest='output_dir',
        required=False,
        help='directory to store generated claims',
    )
    args = parser.parse_args()

    test_dir = args.directory

    # Load test parameters in JSON
    input_json = load_input_json(test_dir)

    print('Loading WASM files...')
    # Test contract's wasm module
    test_wasm = load_wasm(find_test_wasm_path(test_dir))

    # Load dependency contracts' wasm modules
    wasm_paths = (join(test_dir, p) for p in input_json['contract_paths'])
    contract_wasms = load_contract_wasms(wasm_paths)

    krun = KRun(Path('.build/defn/llvm/foundry-kompiled'))

    print('Initializing the test...')
    sym_conf, init_subst = deploy_test(krun, test_wasm, contract_wasms)
    print('Initialization done.')

    test_endpoints = get_test_endpoints(args.directory)
    print(f'Tests: { list(test_endpoints.keys()) }')

    if args.gen_claims:
        if args.output_dir:
            output_dir = Path(args.output_dir)
        else:
            output_dir = Path('generated_claims')

        print('Generating claims:', output_dir)
        generate_claims(krun, test_endpoints, sym_conf, init_subst, output_dir)
    else:
        run_concrete(krun, test_endpoints, sym_conf, init_subst)


def run_concrete(
    krun: KRun,
    test_endpoints: Mapping[str, tuple[str, ...]],
    sym_conf: KInner,
    init_subst: KInner,
):
    for endpoint, arg_types in test_endpoints.items():
        print(f'Testing "{endpoint}"')
        test_with_hypothesis(krun, sym_conf, init_subst, endpoint, arg_types)

if __name__ == '__main__':
    main()
