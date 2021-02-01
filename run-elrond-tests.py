#!/usr/bin/env python3

import argparse
import json
import pyk
import resource
import subprocess
import sys
import tempfile
import os
import wasm2kast

import coverage as cov

from pyk.kast import KSequence, KConstant, KApply, KToken


def KString(value):
    return KToken('"%s"' % value, 'String')

def KWasmString(value):
    return KToken('"%s"' % value, 'WasmStringToken')

def KInt(value : int):
    return KToken(str(value), 'Int')

def KBytes(value: bytes):
    # Change from python bytes repr to bytes repr in K.
    byte_repr = '{}'.format(value)
    if byte_repr.startswith("b'") and byte_repr.endswith("'") :
        byte_repr = 'b"' + byte_repr[2:-1] + '"'
    return KToken(byte_repr, 'Bytes')

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

def config_to_kast_term(config):
    return { 'format' : 'KAST', 'version': 1, 'term': config }

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

def mandos_int_to_kint(mandos_int : str):
    if mandos_int[0:2] == '0x':
        return KInt(int(mandos_int, 16))
    unseparated_int = mandos_int.replace(',', '')
    parsed_int = int(unseparated_int)
    return KInt(parsed_int)

def mandos_argument_to_bytes(argument : str):
    if '|' in argument:
        splits = argument.split('|')
        bs = bytes()
        for s in splits:
            bs += mandos_argument_to_bytes(s)
        return bs
    if argument[0] == 'u':
        [numbitsstr, intstr] = argument[1:].split(':')
        num_bits = int(numbitsstr)
        as_int = int(intstr.replace(',', ''))
        return int.to_bytes(as_int, num_bits // 8, 'big')
    if argument == "":
        return bytes()
    try:
        as_int = int(argument.replace(',', ''))
        num_bytes = 1 + (as_int.bit_length() // 8)
        return int.to_bytes(as_int, num_bytes, 'big')
    except ValueError:
        pass
    if argument[0:2] == '0x':
        byte_array = bytes.fromhex(argument[2:])
        return byte_array
    if argument[0:2] == "''" or argument[0:2] == '``':
        byte_array = bytes(argument[2:], 'ascii')
        return byte_array
    if argument[0:4] == "str:":
        return mandos_argument_to_bytes('``' + argument[4:])
    if argument[0:8] == 'address:':
        padded_addr = argument[8:].ljust(32, '_')
        padded_addr_bytes = bytes(padded_addr[:32], 'ascii')
        return padded_addr_bytes

    raise ValueError("Argument type not yet supported: %s" % argument)

def mandos_argument_to_kbytes(argument: str):
    return KBytes(mandos_argument_to_bytes(argument))

def mandos_argument_to_kargs(argument: str):
    bs = mandos_argument_to_bytes(argument)
    return KApply('tupleArg', [KInt(int.from_bytes(bs, 'big')), KInt(len(bs))])

def mandos_arguments_to_arguments(arguments):
    tokenized = list(map(lambda x: mandos_argument_to_kargs(x), arguments))
    return KList(tokenized)

def mandos_to_set_account(address, sections, filename):
    """Creates a K account cell from a Mandos account description. """
    address_value = mandos_argument_to_kbytes(address)
    nonce_value   = mandos_int_to_kint(sections['nonce'])
    balance_value = mandos_int_to_kint(sections['balance'])
    code_value = KApply(".Code", [])
    if 'code' in sections:
        code_path = get_contract_code(sections['code'], filename)
        if code_path is not None:
            code_value = file_to_module_decl(code)

    storage_pairs = [ (mandos_argument_to_kbytes(k), mandos_argument_to_kbytes(v)) for (k, v) in sections['storage'].items() ]
    storage_value = KMap(storage_pairs)

    set_account_step  = KApply('setAccount', [address_value, nonce_value, balance_value, code_value, storage_value])
    return set_account_step

def mandos_to_check_account(address, sections, filename):
    k_steps = []
    address_value = mandos_argument_to_kbytes(address)
    if ('nonce' in sections) and (sections['nonce'] != '*'):
        nonce_value = mandos_int_to_kint(sections['nonce'])
        k_steps.append(KApply('checkAccountNonce', [address_value, nonce_value]))
    if ('balance' in sections) and (sections['balance'] != '*'):
        balance_value = mandos_int_to_kint(sections['balance'])
        k_steps.append(KApply('checkAccountBalance', [address_value, balance_value]))
    if ('storage' in sections) and (sections['storage'] != '*'):
        storage_pairs = []
        for (k, v) in sections['storage'].items():
            k_bytes = mandos_argument_to_kbytes(k)
            v_bytes = mandos_argument_to_kbytes(v)
            storage_pairs.append((k_bytes, v_bytes))
        storage_value = KMap(storage_pairs)
        k_steps.append(KApply('checkAccountStorage', [address_value, storage_value]))
    if ('code' in sections) and (sections['code'] != '*'):
        code_path = get_contract_code(sections['code'], filename)
        if code_path is None:
            code_path = ""
        code_path = KString(code_path)
        k_steps.append(KApply('checkAccountCode', [address_value, code_path]))

    k_steps.append(KApply('checkedAccount', [address_value]))
    return k_steps

def mandos_to_deploy_tx(tx, filename):
    sender = mandos_argument_to_kbytes(tx['from'])
    value = mandos_int_to_kint(tx['value'])
    arguments = mandos_arguments_to_arguments(tx['arguments']) #TODO
    gasLimit = mandos_int_to_kint(tx['gasLimit'])
    gasPrice = mandos_int_to_kint(tx['gasPrice'])

    code = get_contract_code(tx['contractCode'], filename)
    module = file_to_module_decl(code)

    deployTx = KApply('deployTx', [sender, value, module, arguments, gasLimit, gasPrice])
    return deployTx

def mandos_to_call_tx(tx, filename):
    sender = mandos_argument_to_kbytes(tx['from'])
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(tx['value'])
    function = KWasmString(tx['function'])
    arguments = mandos_arguments_to_arguments(tx['arguments']) #TODO
    gasLimit = mandos_int_to_kint(tx['gasLimit'])
    gasPrice = mandos_int_to_kint(tx['gasPrice'])

    callTx = KApply('callTx', [sender, to, value, function, arguments, gasLimit, gasPrice])
    return callTx

def mandos_to_transfer_tx(tx):
    sender = mandos_argument_to_kbytes(tx['from'])
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(tx['value'])

    transferTx = KApply('transferTx', [sender, to, value])
    return transferTx

def mandos_to_validator_reward_tx(tx):
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(tx['value'])

    rewardTx = KApply('validatorRewardTx', [to, value])
    return rewardTx

def mandos_to_expect(expect):
    """ TODO """
    return KApply('.Expect', [])

def mandos_to_block_info(block_info):
    block_infos = []
    if 'blockTimestamp' in block_info:
        block_infos += [KApply('blockTimestamp', [mandos_int_to_kint(block_info['blockTimestamp'])])]
    if 'blockNonce' in block_info:
        block_infos += [KApply('blockNonce', [mandos_int_to_kint(block_info['blockNonce'])])]
    if 'blockRound' in block_info:
        block_infos += [KApply('blockRound', [mandos_int_to_kint(block_info['blockRound'])])]
    if 'blockEpoch' in block_info:
        block_infos += [KApply('blockEpoch', [mandos_int_to_kint(block_info['blockEpoch'])])]
    return block_infos

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
    with open(filename, 'rb') as f:
        module = wasm2kast.wasm2kast(f, filename)
        return module

def wat_file_to_module_decl(filename : str):
    with open(filename) as f:
        pass
    new_filename = os.path.join(tmpdir, os.path.basename(filename) + '.wasm')
    try:
        wat = subprocess.check_output("wat2wasm %s --output=%s" % (filename, new_filename), shell=True)
    except subprocess.CalledProcessError as e:
        print("Failed: %s" % e.cmd)
        print("return code: %d" % e.returncode)
        print("stdout:")
        print(e.output)
        print("stderr:")
        print(e.stderr)
        raise e
    return wasm_file_to_module_decl(new_filename)

def get_external_file_path(test_file, rel_path_to_new_file):
    test_file_path = os.path.dirname(test_file)
    ext_file = os.path.normpath(os.path.join(test_file_path, rel_path_to_new_file))
    return ext_file

def get_contract_code(code, filename):
    if code[0:5] == 'file:':
        return get_external_file_path(filename, code[5:])
    if code == '':
        return None
    raise Exception('Currently only support getting code from file, or empty code.')

def get_steps_sc_deploy(step, filename):
    tx = mandos_to_deploy_tx(step['tx'], filename)
    expect = mandos_to_expect(step['expect'])
    return [KApply('scDeploy', [tx, expect])]

def get_steps_sc_call(step, filename):
    tx = mandos_to_call_tx(step['tx'], filename)
    expect = mandos_to_expect(step['expect'])
    return [KApply('scCall', [tx, expect])]

def get_steps_transfer(step):
    tx = mandos_to_transfer_tx(step['tx'])
    return [KApply('transfer', [tx])]

def get_steps_validator_reward(step):
    tx = mandos_to_validator_reward_tx(step['tx'])
    return [KApply('validatorReward', [tx])]

def get_steps_new_addresses(new_addresses):
    if new_addresses is None:
        return []
    ret = []
    for new_address in new_addresses:
        creator = mandos_argument_to_kbytes(new_address['creatorAddress'])
        nonce   = mandos_int_to_kint(new_address['creatorNonce'])
        new     = mandos_argument_to_kbytes(new_address['newAddress'])
        ret.append(KApply('newAddress', [creator, nonce, new]))
    return ret

def get_steps_set_state(step, filename):
    k_steps = []
    if 'accounts' in step:
        set_accounts = [ mandos_to_set_account(address, sections, filename) for (address, sections) in step['accounts'].items()]
        k_steps = k_steps + set_accounts
    if 'newAddresses' in step:
        new_addresses = get_steps_new_addresses(step['newAddresses'])
        k_steps = k_steps + new_addresses
    def block_infos_helper(state : str):
        """State is either 'current' or 'previous'"""
        label = state + 'BlockInfo'
        block_infos = mandos_to_block_info(step[label])
        state_block_infos = list(map(lambda x: KApply(label, [x]), block_infos))
        return state_block_infos
    if 'currentBlockInfo' in step:
        curr = block_infos_helper('current')
        k_steps = k_steps + curr
    if 'previousBlockInfo' in step:
        prev = block_infos_helper('previous')
        k_steps = k_steps + prev
    if k_steps == []:
        raise Exception('Step not implemented: %s' % step)
    return k_steps

def get_steps_check_state(step, filename):
    k_steps = []
    if 'accounts' in step:
        for (address, sections) in step['accounts'].items():
            if address != '+':
                k_steps += mandos_to_check_account(address, sections, filename)
        if not '+' in step['accounts'].keys():
            k_steps.append(KApply('checkNoAdditionalAccounts', []))
        k_steps.append(KApply('clearCheckedAccounts', []))
    return k_steps

def get_steps_as_kseq(filename):
    with open(filename, 'r') as f:
        mandos_test = json.loads(f.read())
    if 'name' in mandos_test:
        print('Reading "%s"' % mandos_test['name'])
    if 'comment' in mandos_test:
        print('Comment:\n"%s"' % mandos_test['comment'])

    k_steps = []
    for step in mandos_test['steps']:
        if step['step'] == 'setState':
            k_steps.append((step['step'], get_steps_set_state(step, filename)))
        elif step['step'] == 'scDeploy':
            k_steps.append((step['step'], get_steps_sc_deploy(step, filename)))
        elif step['step'] == 'scCall':
            k_steps.append((step['step'], get_steps_sc_call(step, filename)))
        elif step['step'] == 'checkState':
            k_steps.append((step['step'], get_steps_check_state(step, filename)))
        elif step['step'] == 'externalSteps':
            steps_file = get_external_file_path(filename, step['path'])
            print('Load external: %s' % steps_file)
            k_steps = k_steps + get_steps_as_kseq(steps_file)
        elif step['step'] == 'transfer':
            k_steps.append((step['step'], get_steps_transfer(step)))
        elif step['step'] == 'validatorReward':
            k_steps.append((step['step'], get_steps_validator_reward(step, filename)))
        else:
            raise Exception('Step %s not implemented yet' % step['step'])
    return k_steps

def run_test_file(wasm_config, filename, test_name):
    k_steps = get_steps_as_kseq(filename)

    if args.log_level == 'none' or args.log_level == 'per-file':
        # Flatten the list of k_steps, just run them all in one go.
        k_steps = [ ('full', [ y for (_, x) in k_steps for y in x ]) ]

    for i in range(len(k_steps)):
        (symbolic_config, init_subst) = pyk.splitConfigFrom(wasm_config)
        k_cell = init_subst['K_CELL']
        assert k_cell['node'] == 'KSequence' and k_cell['arity'] == 0, "k cell not empty, contains a sequence of %d items.\nSee %s" % (k_cell['arity'], tmpdir)
        step_name, curr_step = k_steps[i]
        print('Executing step %s' % step_name)
        init_subst['K_CELL'] = KSequence(curr_step)

        init_config = pyk.substitute(symbolic_config, init_subst)

        input_json = config_to_kast_term(init_config)
        krun_args = [ '--term', '--debug']

        # Run: generate a new JSON as a temporary file, then read that as the new wasm state.
        log_intermediate_state("%s_%d_%s.pre" % (test_name, i, step_name), init_config)
        (rc, new_wasm_config, err) = pyk.krunJSON(WASM_definition_llvm_no_coverage_dir, input_json, krunArgs = krun_args, teeOutput=True)
        if rc != 0:
            print('output:\n%s' % new_wasm_config, file=sys.stderr)
            print(pyk.prettyPrintKast(new_wasm_config, WASM_symbols_llvm_no_coverage))
            raise Exception("Received error while running: " + err )

        log_intermediate_state("%s_%d_%s" % (test_name, i, step_name), new_wasm_config)
        wasm_config = new_wasm_config

    return wasm_config

# ... Setup Elrond Wasm

def log_intermediate_state(name, config):
    if args.log_level == 'none':
        return
    with open('%s/%s' % (tmpdir, name), 'w') as f:
        f.write(json.dumps(config_to_kast_term(config)))
    with open('%s/%s.pretty.k' % (tmpdir, name), 'w') as f:
        pretty = pyk.prettyPrintKast(config, WASM_symbols_llvm_no_coverage)
        f.write(pretty)

# Main Script

per_test_coverage = []

for test in tests:
    tmpdir = tempfile.mkdtemp(prefix="mandos_")
    print("Intermediate test outputs stored in:\n%s" % tmpdir)
    wasm_config = pyk.readKastTerm('src/elrond-runtime.loaded.json')
    cells = pyk.splitConfigFrom(wasm_config)[1]
    assert cells['K_CELL']['arity'] == 0

    initial_name = "0000_initial_config"
    with open('%s/%s' % (tmpdir, initial_name), 'w') as f:
        f.write(json.dumps(config_to_kast_term(wasm_config)))

    test_name = os.path.basename(test)
    wasm_config = run_test_file(wasm_config, test, test_name)

    if args.coverage:
        end_config = wasm_config #pyk.readKastTerm(os.path.join(tmpdir, test_name))
        (covered, not_covered) = cov.get_coverage(end_config)
        mods = cov.get_module_filename_map(wasm_config)
        coverage = { 'cov' : covered , 'not_cov': not_covered, 'idx2file' : mods }
        per_test_coverage.append(coverage)

    print()
    print('See %s' % tmpdir)

if args.coverage:
    (_, not_cov) = cov.summarize_coverage(per_test_coverage, unnamed='import')

    print(not_cov)
    text_modules = cov.insert_coverage_on_text_module(not_cov, imports_mod_name='import')
    for module in text_modules:
        for line in module.splitlines():
            print(line.decode('utf8'))
