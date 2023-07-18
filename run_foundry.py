import argparse
import glob
import random
from os.path import join

from hypothesis import given, settings, Verbosity
from hypothesis.strategies import integers, tuples

from run_elrond_tests import *
from pyk.prelude.utils import token
from pyk.prelude.collections import map_of
from pyk.kast.inner import KSort
from pyk.kast.kast import kast_term
from pyk.kore.syntax import Pattern
from pyk.ktool.krun import _krun, KRunOutput

INPUT_FILE_NAME = 'foundry.json'

def load_input_json(test_dir):
    try:
      with open(join(test_dir , INPUT_FILE_NAME), 'r') as f:
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
    contract_wasm_modules = { bytes(f, 'ascii'): load_wasm(f) for f in contract_wasm_paths }
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
        [k_addr, token(1), token(100000), KApply(".Code", []), token(b''), KMapBytesToBytes([])]
      )
    # the test contract's address will be 'k-test'
    k_test_addr = mandos_argument_to_kbytes('sc:k-test')
    new_address = KApply('newAddress', [k_addr, token(1), k_test_addr])

    # deploy the test contract
    arguments = ListBytes(wrapBytes(token(k)) for k in contract_wasms)
    gas = token(5000000000000)
    deploy_cmd = KApply('deployTx', [k_addr, token(0), test_wasm, arguments, gas, token(0)])

    # initialization steps
    init_steps = KSequence([init_main_acct, new_address, deploy_cmd])
    
    # create an empty config and embed init steps
    empty_conf = krun.definition.init_config(KSort('GeneratedTopCell'))

    conf, subst = split_config_from(empty_conf)
    subst['K_CELL'] = init_steps
    subst['WASMSTORE_CELL'] = map_of({token(path): mod  for path, mod in contract_wasms.items() })
    conf_with_steps = Subst(subst)(conf)

    return run_config_and_check_empty(krun, conf_with_steps)

def run_kore_term(
    krun: KRun,
    pattern: Pattern
) -> KInner:
    with krun._temp_file() as ntf:
        pattern.write(ntf)
        ntf.write('\n')
        ntf.flush()

        proc_res = _krun(
            command=krun.command,
            input_file=Path(ntf.name),
            definition_dir=krun.definition_dir,
            output=KRunOutput.JSON,
            parser='cat',
            term=True,
            check=True,
        )
    
    return kast_term(json.loads(proc_res.stdout), KInner)

def run_config_and_check_empty(krun, conf):
    conf_kore = krun.kast_to_kore(conf, KSort('GeneratedTopCell'))
    final_conf = run_kore_term(krun, conf_kore)
    sym_conf, subst = split_config_from(final_conf)
    k_cell = subst['K_CELL']
    if not isinstance(k_cell, KSequence) or k_cell.arity != 0:
        print(krun.pretty_print( subst['VMOUTPUT_CELL'] ), file=sys.stderr)
        raise ValueError(f'k cell not empty')
    
    return final_conf, sym_conf, subst

def run_test(krun, sym_conf, init_subst, endpoint, args):
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
        'expect': {
            'status': '0'
        }
    }
    tx_steps = KSequence(get_steps_sc_call(step))

    init_subst['K_CELL'] = tx_steps
    conf_with_steps = Subst(init_subst)(sym_conf)
    
    run_config_and_check_empty(krun, conf_with_steps)
    
# Test metadata
TEST_PREFIX = 'test_'

def get_test_endpoints(test_dir: str):

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

# All the values generated are in the Mandos format

def big_uint():
    return integers(min_value=0).map(str)

def type_to_strategy(typ: str):
    if typ == 'BigUint':
        return big_uint()
    else:
        raise TypeError(f'Cannot create random {typ}')

def arg_types_to_strategy(types):
    strs = (type_to_strategy(t) for t in types)
    return tuples(*strs)

def test_with_hypothesis(krun, sym_conf, init_subst, endpoint, arg_types):
    
    def test(args):
        run_test(krun, sym_conf, init_subst, endpoint, args)
        
    test.__name__ = endpoint     # show endpoint name in hypothesis logs

    args_strategy = arg_types_to_strategy(arg_types)
    given(args_strategy)(
        settings(
            deadline=5000,       # set time limit for for individual run
            max_examples=10,     # 20 is enough for demo purposes
            verbosity=Verbosity.verbose,
        )(test)
    )()

# Main Script
DESCRIPTION = '''
Concrete execution for MultiversX Foundry-like tests.
This is not the intended front-end of the tool, it is for developers\' use only.
'''

def main():

    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument('-d', '--directory',
                        required=True,
                        help='path to the test contract')
    parser.add_argument('-s', '--seed',
                        required=False,
                        type=int,
                        help='set RNG seed')
    args = parser.parse_args()


    if args.seed is not None:
        random.seed(args.seed)

    
    test_dir = args.directory
    
    # Load test parameters in JSON
    input_json = load_input_json(test_dir)
    
    print("Loading WASM files...")
    # Test contract's wasm module
    test_wasm = load_wasm(find_test_wasm_path(test_dir))
    
    # Load dependency contracts' wasm modules
    wasm_paths = (join(test_dir, p) for p in input_json['contract_paths'])
    contract_wasms = load_contract_wasms(wasm_paths)

    krun = KRun(Path('.build/defn/llvm/foundry-kompiled'))

    print("Initializing the test...")
    _init_conf, sym_conf, init_subst = deploy_test(krun, test_wasm, contract_wasms)

    test_endpoints = get_test_endpoints(args.directory)

    for endpoint, arg_types in test_endpoints.items():
        print(f'Testing "{endpoint}"')
        test_with_hypothesis(krun, sym_conf, init_subst, endpoint, arg_types)

    
if __name__ == "__main__":
    main()