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

#### SHOULD BE UPSTREAMED ####

def KString(value):
    return KToken('"%s"' % value, 'String')

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

def KInt(value : int):
    return KToken(str(value), 'Int')

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
args = testArgs.parse_args()

tests = args.files

def mandos_int_to_int(mandos_int : str):
    if mandos_int[0:2] == '0x':
        return int(mandos_int, 16)
    unseparated_int = mandos_int.replace(',', '')
    parsed_int = int(unseparated_int)
    return KInt(parsed_int)

def mandos_to_set_account(address, sections):
    """Creates a K account cell from a Mandos account description. """
    address_value = KString(address)
    nonce_value   = mandos_int_to_int(sections['nonce'])
    balance_value = mandos_int_to_int(sections['balance'])
    code_value    = KString(sections['code'])

    storage_pairs = [ (KString(k), KString(v)) for (k, v) in sections['storage'].items() ]
    storage_value = KMap(storage_pairs)

    set_account_step  = KApply('setAccount', [address_value, nonce_value, balance_value, code_value, storage_value])
    return set_account_step

def register(with_name : str):
    return KApply('register', [KString(with_name)])

def wasm_file_to_module_decl(filename : str):
    wat = subprocess.check_output("wasm2wat %s" % filename, shell=True)
    temp = tempfile.NamedTemporaryFile()
    temp.write(wat)
    temp.seek(0)
    (rc, kasted, err) = pyk.kast(WASM_definition_llvm_no_coverage_dir, temp.name, kastArgs = ['--output json'], teeOutput=True)
    if rc != 0:
        print(err, file=sys.stderr)
        sys.exit(rc)
    kasted_json = json.loads(kasted)
    module = kasted_json['term']['args'][0]
    return module

def get_steps_set_state(step, filename):
    if 'accounts' in step:
        set_accounts = [ mandos_to_set_account(address, sections) for (address, sections) in step['accounts'].items()]
        # Get paths of Wasm code, relative to the test location.
        test_file_path = os.path.dirname(filename)
        # TODO: Read the files, convert to text, parse, declare them and register them (with address as key)
        contracts_files = [ (addr, os.path.normpath(os.path.join(test_file_path, sects['code'][5:])))
                        for (addr, sects) in step['accounts'].items()
                        if sects['code'][0:5] == "file:" ]
        # First declare module, then register it
        contract_module_decls = [ [wasm_file_to_module_decl(f), register(a) ] for (a, f) in contracts_files ]
        # Flatten:
        contract_setups = [ step for pair in contract_module_decls for step in pair ]
        k_steps = contract_setups
        k_steps = k_steps + set_accounts
    else:
        # TODO: newAddress and previousBlock
        print('Step not implemented: %s' % step, file=sys.stderr)
        sys.exit(1)
    return k_steps

def run_test_file(wasm_state, filename):
    with open(filename, 'r') as f:
        mandos_test = json.loads(f.read())
    if 'name' in mandos_test:
        print('Executing "%s"' % mandos_test['name'])
    if 'comment' in mandos_test:
        print('Comment:\n"%s"' % mandos_test['comment'])

    (symbolic_config, init_subst) = pyk.splitConfigFrom(wasm_state)
    k_steps = []
    for step in mandos_test['steps']:
        if step['step'] == 'setState':
            k_steps = k_steps + get_steps_set_state(step, filename)
        else:
            print('Step %s not implemented yet' % step['step'], file=sys.stderr)
            sys.exit(1)

    init_subst['K_CELL'] = KSequence(k_steps)

    init_config = pyk.substitute(symbolic_config, init_subst)

    input_json = { 'format' : 'KAST', 'version': 1, 'term': init_config }
    krun_args = [ '--term']

    # Run: generate a new JSON as a temporary file, then read that as the new wasm state.
    (_rc, new_wasm_state, _) = pyk.krunJSON(WASM_definition_llvm_no_coverage_dir, input_json, krunArgs = krun_args, teeOutput=True)

    return new_wasm_state

# ... Setup Elrond Wasm

wasm_state = pyk.readKastTerm('src/elrond-runtime.loaded.json')
cells = pyk.splitConfigFrom(wasm_state)[1]
assert cells['K_CELL']['arity'] == 0

tmpdir = tempfile.mkdtemp(prefix="mandos_")
print("Intermediate test outputs stored in:\n%s" % tmpdir)

initial_name = "0000_initial_config"
with open('%s/%s' % (tmpdir, initial_name), 'w') as f:
    f.write(json.dumps(wasm_state))

for test in tests:
    wasm_state = run_test_file(wasm_state, test)
    test_name = os.path.basename(test)
    with open('%s/%s' % (tmpdir, test_name), 'w') as f:
        f.write(json.dumps(wasm_state))
    with open('%s/%s.pretty.wat' % (tmpdir, test_name), 'w') as f:
        pretty = pyk.prettyPrintKast(wasm_state, WASM_symbols_llvm_no_coverage)
        f.write(pretty)
    cells = pyk.splitConfigFrom(wasm_state)[1]
    k_cell = cells['K_CELL']

    # Check that K cell is empty
    assert k_cell['node'] == 'KSequence' and k_cell['arity'] == 0, "k cell not empty, contains a sequence of %d items" % k_cell['arity']
