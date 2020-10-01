#!/usr/bin/env python3

import argparse
import json
import pyk
import resource
import subprocess
import sys
import tempfile
import os

from pyk.kast import KSequence, KConstant, KApply, KToken

POSITIVE_COVERAGE_CELL = "COVEREDFUNCS_CELL"
NEGATIVE_COVERAGE_CELL = "NOTCOVEREDFUNCS_CELL"

tmpdir = tempfile.mkdtemp(prefix="mandos_")
print("Intermediate test outputs stored in:\n%s" % tmpdir)

#### SHOULD BE UPSTREAMED ####

def KString(value):
    return KToken('"%s"' % value, 'String')

def KWasmString(value):
    return KToken('"%s"' % value, 'WasmStringToken')

def KMap(kitem_pairs):
    """Takes a list of pairs of KItems and produces a Map with them as keys and values."""
    if len(kitem_pairs) == 0:
        return KApply(".Map", [])
    ((k, v), tail) = (kitem_pairs[0], kitem_pairs[1:])
    res = KApply("_|->_", [k, v])
    for (k, v) in tail:
        new_item = KApply("_|->_", [k, v])
        res = KApply("_Map_", [res, new_item])
    return res

def KList(items):
    list_items = list(map(lambda x: KApply("ListItem", [x]), items))
    def KList_aux(lis):
        if lis == []:
            return KApply(".List", [])
        head = lis[0]
        tail = KList_aux(lis[1:])
        return KApply("_List_", [head, tail])
    return KList_aux(list_items)

def KInt(value : int):
    return KToken(str(value), 'Int')

def config_to_kast_term(config):
    return { 'format' : 'KAST', 'version': 1, 'term': config }

def filter_term(filter_func, term):
    res = []
    if filter_func(term):
        res.append(term)
    if 'args' in term:
        for arg in term['args']:
            for child in filter_term(filter_func, arg):
                res.append(child)
    return res

###############################

WASM_definition_main_file = 'elrond'
WASM_definition_llvm_no_coverage_dir = '.build/defn/llvm'
WASM_definition_llvm_no_coverage_kompiled_dir = WASM_definition_llvm_no_coverage_dir + '/' + WASM_definition_main_file + '-kompiled'
WASM_definition_llvm_no_coverage = pyk.readKastTerm(WASM_definition_llvm_no_coverage_kompiled_dir + '/compiled.json')
WASM_symbols_llvm_no_coverage = pyk.buildSymbolTable(WASM_definition_llvm_no_coverage)

sys.setrecursionlimit(1500000000)
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

testArgs = argparse.ArgumentParser(description='')
testArgs.add_argument('files', metavar='N', type=str, nargs='+', help='')
testArgs.add_argument('--coverage', action='store_true', help='Display test coverage data.')
testArgs.add_argument('--log-level', choices=['none', 'per-file', 'per-step'], default='per-file')
args = testArgs.parse_args()

tests = args.files

def mandos_int_to_int(mandos_int : str):
    if mandos_int[0:2] == '0x':
        return KInt(int(mandos_int, 16))
    unseparated_int = mandos_int.replace(',', '')
    parsed_int = int(unseparated_int)
    return KInt(parsed_int)

def mandos_to_set_account(address, sections):
    """Creates a K account cell from a Mandos account description. """
    address_value = KWasmString(address)
    nonce_value   = mandos_int_to_int(sections['nonce'])
    balance_value = mandos_int_to_int(sections['balance'])
    code_value    = KWasmString(sections['code'])

    storage_pairs = [ (KString(k), KString(v)) for (k, v) in sections['storage'].items() ]
    storage_value = KMap(storage_pairs)

    set_account_step  = KApply('setAccount', [address_value, nonce_value, balance_value, code_value, storage_value])
    return set_account_step

def mandos_argument_to_bytes(argument : str):
    if argument == "":
        return KApply('tupleArg', [KInt(0), KInt(0)])
    try:
        as_int = int(argument)
        num_bytes = 1 + (as_int.bit_length() // 8)
        return KApply('tupleArg', [KInt(as_int), KInt(num_bytes)])
    except ValueError:
        pass
    if argument[0:2] == '0x':
        as_int = int(argument, 16)
        byte_array = bytes.fromhex(argument[2:])
        num_bytes = len(byte_array)
        return KApply('tupleArg', [KInt(as_int), KInt(num_bytes)])

    raise ValueError("Argument type not yet supported: %s" % argument)

def mandos_arguments_to_arguments(arguments):
    tokenized = list(map(lambda x: mandos_argument_to_bytes(x), arguments))
    return KList(tokenized)

def mandos_to_deploy_tx(tx, filename):
    sender = KWasmString(tx['from'])
    value = mandos_int_to_int(tx['value'])
    arguments = mandos_arguments_to_arguments(tx['arguments']) #TODO
    gasLimit = mandos_int_to_int(tx['gasLimit'])
    gasPrice = mandos_int_to_int(tx['gasPrice'])

    code = get_contract_code(tx['contractCode'], filename)
    module = file_to_module_decl(code)

    deployTx = KApply('deployTx', [sender, value, module, arguments, gasLimit, gasPrice])
    return deployTx

def mandos_to_call_tx(tx, filename):
    sender = KWasmString(tx['from'])
    to = KWasmString(tx['to'])
    value = mandos_int_to_int(tx['value'])
    function = KWasmString(tx['function'])
    arguments = mandos_arguments_to_arguments(tx['arguments']) #TODO
    gasLimit = mandos_int_to_int(tx['gasLimit'])
    gasPrice = mandos_int_to_int(tx['gasPrice'])

    callTx = KApply('callTx', [sender, to, value, function, arguments, gasLimit, gasPrice])
    return callTx

def mandos_to_expect(expect):
    """ TODO """
    return KApply('.Expect', [])

def register(with_name : str):
    return KApply('register', [KString(with_name)])

def file_to_module_decl(filename : str):
    if filename[-5:] == '.wasm':
        return wasm_file_to_module_decl(filename)
    if filename[-5:] == '.wast' or filename[-4:] == '.wat':
        return wat_file_to_module_decl(filename)
    raise ValueError('Filetype not yet supported: %s' % filename)

def wasm_file_to_module_decl(filename : str):
    # Check that file exists.
    with open(filename) as f:
        pass
    try:
        wat = subprocess.check_output("wasm2wat %s" % filename, shell=True)
        with open('%s/%s' % (tmpdir, os.path.basename(filename) + ".pretty.wat"), 'wb') as f:
            f.write(wat)
    except subprocess.CalledProcessError as e:
        print("Failed: %s" % e.cmd)
        print("return code: %d" % e.returncode)
        print("stdout:")
        print(e.output)
        print("stderr:")
        print(e.stderr)
        raise e
    temp = tempfile.NamedTemporaryFile()
    temp.write(wat)
    temp.seek(0)
    return wat_file_to_module_decl(temp.name)

def wat_file_to_module_decl(filename : str):
    (rc, kasted, err) = pyk.kast(WASM_definition_llvm_no_coverage_dir, filename, kastArgs = ['--output', 'json'], teeOutput=True)
    if rc != 0:
        raise Exception("Received error while kast-ing: " + err )
    kasted_json = json.loads(kasted)
    module = kasted_json['term']['args'][0]
    return module

def get_contract_code(code, filename):
    if code[0:5] == 'file:':
        test_file_path = os.path.dirname(filename)
        code_file = os.path.normpath(os.path.join(test_file_path, code[5:]))
        return code_file
    if code == '':
        return None
    raise Exception('Currently only support getting code from file, or empty code.')

def get_steps_sc_call(step, filename):
    tx = mandos_to_deploy_tx(step['tx'])
    expect = mandos_to_expect(step['expect'])
    return [KApply('scCall', [tx, expect])]

def get_steps_sc_deploy(step, filename):
    tx = mandos_to_deploy_tx(step['tx'], filename)
    expect = mandos_to_expect(step['expect'])
    return [KApply('scDeploy', [tx, expect])]

def get_steps_sc_call(step, filename):
    tx = mandos_to_call_tx(step['tx'], filename)
    expect = mandos_to_expect(step['expect'])
    return [KApply('scCall', [tx, expect])]

def get_steps_new_addresses(new_addresses):
        if new_addresses is None:
            return []
        ret = []
        for new_address in new_addresses:
            creator = KWasmString(new_address['creatorAddress'])
            nonce   = mandos_int_to_int(new_address['creatorNonce'])
            new     = KWasmString(new_address['newAddress'])
            ret.append(KApply('newAddress', [creator, nonce, new]))
        return ret

def get_steps_set_state(step, filename):
    if 'accounts' in step:
        set_accounts = [ mandos_to_set_account(address, sections) for (address, sections) in step['accounts'].items()]
        # Get paths of Wasm code, relative to the test location.
        # TODO: Read the files, convert to text, parse, declare them and register them (with address as key)
        contracts_files = [ (addr, get_contract_code(sects['code'], filename)) for (addr, sects) in step['accounts'].items() ]
        contracts_files = [ (addr, code) for (addr, code) in contracts_files if code is not None ]
        # First declare module, then register it
        contract_module_decls = [ [file_to_module_decl(f), register(a) ] for (a, f) in contracts_files ]
        # Flatten:
        contract_setups = [ step for pair in contract_module_decls for step in pair ]
        k_steps = contract_setups
        k_steps = k_steps + set_accounts

        new_addresses = get_steps_new_addresses(step['newAddresses']) if 'newAddresses' in step else []
        k_steps = k_steps + new_addresses
    else:
        print('Step not implemented: %s' % step, file=sys.stderr)
        sys.exit(1)
    return k_steps

def run_test_file(wasm_config, filename, test_name):
    with open(filename, 'r') as f:
        mandos_test = json.loads(f.read())
    if 'name' in mandos_test:
        print('Executing "%s"' % mandos_test['name'])
    if 'comment' in mandos_test:
        print('Comment:\n"%s"' % mandos_test['comment'])

    (symbolic_config, init_subst) = pyk.splitConfigFrom(wasm_config)
    k_steps = []
    for step in mandos_test['steps']:
        if step['step'] == 'setState':
            k_steps.append((step['step'], get_steps_set_state(step, filename)))
        elif step['step'] == 'scDeploy':
            k_steps.append((step['step'], get_steps_sc_deploy(step, filename)))
        elif step['step'] == 'scCall':
            k_steps.append((step['step'], get_steps_sc_call(step, filename)))
        elif step['step'] == 'checkState':
            # TODO Skipping for now, not important for coverage.
            pass
        else:
            raise Exception('Step %s not implemented yet' % step['step'])

    if args.log_level == 'none' or args.log_level == 'per-file':
        # Flatten the list of k_steps, just run them all in one go.
        k_steps = [ ('full', [ y for (_, x) in k_steps for y in x ]) ]

    for i in range(len(k_steps)):
        step_name, curr_step = k_steps[i]
        init_subst['K_CELL'] = KSequence(curr_step)

        init_config = pyk.substitute(symbolic_config, init_subst)

        input_json = config_to_kast_term(init_config)
        krun_args = [ '--term', '--debug']

        # Run: generate a new JSON as a temporary file, then read that as the new wasm state.
        (rc, new_wasm_config, err) = pyk.krunJSON(WASM_definition_llvm_no_coverage_dir, input_json, krunArgs = krun_args, teeOutput=True)
        if rc != 0:
            raise Exception("Received error while running: " + err )

        log_intermediate_state("%s_%d_%s" % (test_name, i, step_name), new_wasm_config)

    return new_wasm_config

# ... Setup Elrond Wasm

# Displaying Coverage Data
def get_coverage(term):
    cells = pyk.splitConfigFrom(term)[1]
    pos = cells[POSITIVE_COVERAGE_CELL]
    neg = cells[NEGATIVE_COVERAGE_CELL]
    filter_func = lambda term: 'label' in term and term['label'] == 'fcd'
    pos_fcds = filter_term(filter_func, pos)
    neg_fcds = filter_term(filter_func, neg)
    def fcd_data(fcd):
        mod = fcd['args'][0]['token']
        addr = fcd['args'][1]['token']
        oid_node = fcd['args'][2]
        oid = oid_node['token'] if 'token' in oid_node else None
        return (mod, addr, oid)
    pos_ids = [ fcd_data(fcd) for fcd in pos_fcds ]
    neg_ids = [ fcd_data(fcd) for fcd in neg_fcds ]
    return (pos_ids, neg_ids)

def log_intermediate_state(name, config):
    with open('%s/%s' % (tmpdir, name), 'w') as f:
        f.write(json.dumps(config_to_kast_term(config)))
    with open('%s/%s.pretty.wat' % (tmpdir, name), 'w') as f:
        pretty = pyk.prettyPrintKast(config, WASM_symbols_llvm_no_coverage)
        f.write(pretty)

# Main Script

wasm_config = pyk.readKastTerm('src/elrond-runtime.loaded.json')
cells = pyk.splitConfigFrom(wasm_config)[1]
assert cells['K_CELL']['arity'] == 0

initial_name = "0000_initial_config"
with open('%s/%s' % (tmpdir, initial_name), 'w') as f:
    f.write(json.dumps(config_to_kast_term(wasm_config)))


for test in tests:
    test_name = os.path.basename(test)
    wasm_config = run_test_file(wasm_config, test, test_name)
    cells = pyk.splitConfigFrom(wasm_config)[1]
    k_cell = cells['K_CELL']

    # Check that K cell is empty
    assert k_cell['node'] == 'KSequence' and k_cell['arity'] == 0, "k cell not empty, contains a sequence of %d items" % k_cell['arity']

    if args.coverage:
        end_config = wasm_config #pyk.readKastTerm(os.path.join(tmpdir, test_name))
        (covered, uncovered) = get_coverage(end_config)
        print('Covered:')
        [ print(f) for f in covered ]
        print()
        print('Not Covered:')
        [ print(f) for f in uncovered ]

        print()
        print('See %s' % tmpdir)
