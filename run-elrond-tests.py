#!/usr/bin/env python3

import argparse
import json
import pyk
import resource
import subprocess
import sys
import sha3
import tempfile
import os
import wasm2kast

import coverage as cov

from pyk.kast import KSequence, KConstant, KApply, KToken


def KString(value):
    return KToken('"%s"' % value, 'String')

def KWasmString(value):
    return KToken('"%s"' % value, 'WasmStringToken')

def KInt(value: int):
    return KToken(str(value), 'Int')

def KBytes(value: bytes):
    # Change from python bytes repr to bytes repr in K.
    byte_repr = '{}'.format(value)
    if byte_repr.startswith("b'") and byte_repr.endswith("'") :
        byte_repr = byte_repr.replace('"', '\\"')
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

WASM_definition_main_file = 'mandos'
WASM_definition_llvm_no_coverage_dir = '.build/defn/llvm'
WASM_definition_llvm_no_coverage_kompiled_dir = WASM_definition_llvm_no_coverage_dir + '/' + WASM_definition_main_file + '-kompiled'
WASM_definition_llvm_no_coverage = pyk.readKastTerm(WASM_definition_llvm_no_coverage_kompiled_dir + '/compiled.json')
WASM_symbols_llvm_no_coverage = pyk.buildSymbolTable(WASM_definition_llvm_no_coverage)

addr_prefix   = "address:"
keccak_prefix = "keccak256:"
u64_prefix    = "u64:"
u32_prefix    = "u32:"
u16_prefix    = "u16:"
u8_prefix     = "u8:"

biguint_prefix = "biguint:"

sys.setrecursionlimit(1500000000)
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

def mandos_int_to_kint(mandos_int: str):
    if mandos_int[0:2] == '0x':
        return KInt(int(mandos_int, 16))
    unseparated_int = mandos_int.replace(',', '')
    parsed_int = int(unseparated_int)
    return KInt(parsed_int)

def mandos_argument_to_bytes(arg):
    if isinstance(arg, str):
        return mandos_string_to_bytes(arg)

    if isinstance(arg, list):
        barr = bytearray()
        for elem in arg:
            barr += bytearray(mandos_argument_to_bytes(elem))
        return bytes(barr)

    if isinstance(arg, dict):
        barr = bytearray()
        for key in sorted(arg.keys()):
            barr += bytearray(mandos_argument_to_bytes(arg[key]))
        return bytes(barr)

    raise ValueError("Argument type not yet supported: %s" % arg)

def mandos_string_to_bytes(raw_str: str):
    if raw_str == "":
        return bytes()

    if '|' in raw_str:
        splits = raw_str.split('|')
        bs = bytearray()
        for s in splits:
            bs += bytearray(mandos_argument_to_bytes(s))
        return bytes(bs)

    if raw_str == "false":
        return bytes()
    if raw_str == "true":
        return bytes([1])

    # string prefix
    if raw_str.startswith('str:'):
        return bytes(raw_str[4:], 'ascii')
    if raw_str.startswith("''") or raw_str.startswith('``'):
        return bytes(raw_str[2:], 'ascii')

    # address
    if raw_str.startswith(addr_prefix):
        padded_addr = raw_str[len(addr_prefix):].ljust(32, '_')
        padded_addr_bytes = bytes(padded_addr[:32], 'ascii')
        return padded_addr_bytes

    # keccak256
    if raw_str.startswith(keccak_prefix):
        input_bytes = mandos_string_to_bytes(raw_str[len(keccak_prefix):])
        k = sha3.keccak_256()
        k.update(input_bytes)
        return bytes.fromhex(k.hexdigest())

    # biguint
    if raw_str.startswith(biguint_prefix):
        bs = bytearray()
        num_int, num_len = convert_string_to_uint(raw_str[len(biguint_prefix):])
        bs += bytearray(num_len.to_bytes(4, 'big'))
        bs += bytearray(num_int.to_bytes(num_len, 'big'))
        return bytes(bs)

    # fixed width number
    if raw_str.startswith(u64_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u64_prefix):], 8)
    if raw_str.startswith(u32_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u32_prefix):], 4)
    if raw_str.startswith(u16_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u16_prefix):], 2)
    if raw_str.startswith(u8_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u8_prefix):], 1)

    # signed integer
    if raw_str.startswith('+') or raw_str.startswith('-'):
        try:
            num_int, num_len = convert_string_to_sint(raw_str)
            return num_int.to_bytes(length=num_len, byteorder='big', signed=True)
        except ValueError:
            pass

    # unsigned integer
    try:
        num_int, num_len = convert_string_to_uint(raw_str)
        return num_int.to_bytes(num_len, 'big')
    except ValueError:
        pass

    raise ValueError("Argument type not yet supported: %s" % raw_str)

def mandos_interpret_as_uint_fixedwidth(raw_str: str, width: int):
    num_int, _ = convert_string_to_uint(raw_str)
    return num_int.to_bytes(width, byteorder='big')

def convert_string_to_uint(raw_str: str):
    num_str = raw_str.replace('_', '')
    num_str = num_str.replace(',', '')

    if num_str.startswith('0x') or num_str.startswith('0X'):
        num_str = num_str[2:]
        str_len = len(num_str)
        if str_len == 0:
            return (0, 0)
        else:
            num_int = int(num_str, 16)
            num_len = (str_len + 1) // 2
            return (num_int, num_len)

    if num_str.startswith('0b') or num_str.startswith('0B'):
        num_str = num_str[2:]
        str_len = len(num_str)
        if str_len == 0:
            return (0, 0)
        else:
            num_int = int(num_str, 2)
            num_len = (str_len + 7) // 8
            return (num_int, num_len)

    num_int = int(num_str)
    if (num_int < 0):
        raise ValueError("Negative number not allowed in this context: %s" % raw_str)
    num_len = (num_int.bit_length() + 7) // 8
    return (num_int, num_len)

def convert_string_to_sint(raw_str: str):
    num_int, _ = convert_string_to_uint(raw_str[1:])
    if raw_str.startswith('-'):
        num_int = -num_int
    num_len = (8 + (num_int + (num_int < 0)).bit_length()) // 8
    return (num_int, num_len)

def mandos_argument_to_kbytes(argument: str):
    return KBytes(mandos_argument_to_bytes(argument))

def mandos_arguments_to_klist(arguments: list):
    tokenized = list(map(lambda x: mandos_argument_to_kbytes(x), arguments))
    return KList(tokenized)

def mandos_to_set_account(address, sections, filename, output_dir):
    """Creates a K account cell from a Mandos account description. """
    address_value = mandos_argument_to_kbytes(address)
    nonce_value   = mandos_int_to_kint(sections['nonce'])
    balance_value = mandos_int_to_kint(sections['balance'])
    code_value = KApply(".Code", [])
    if 'code' in sections:
        code_path = get_contract_code(sections['code'], filename)
        if code_path is not None:
            code_value = file_to_module_decl(code_path, output_dir)

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

def mandos_to_deploy_tx(tx, filename, output_dir):
    sender = mandos_argument_to_kbytes(tx['from'])
    value = mandos_int_to_kint(tx['value'])
    arguments = mandos_arguments_to_klist(tx['arguments'])
    gasLimit = mandos_int_to_kint(tx['gasLimit'])
    gasPrice = mandos_int_to_kint(tx['gasPrice'])

    code = get_contract_code(tx['contractCode'], filename)
    module = file_to_module_decl(code, output_dir)

    deployTx = KApply('deployTx', [sender, value, module, arguments, gasLimit, gasPrice])
    return deployTx

def mandos_to_call_tx(tx):
    sender = mandos_argument_to_kbytes(tx['from'])
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(tx['value'])
    function = KWasmString(tx['function'])
    arguments = mandos_arguments_to_klist(tx['arguments'])
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

# TODO: implement checkExpect gas, refund
def mandos_to_expect(expect):
    k_steps = []

    def int_to_kreturncode(status: str):
        if status == "":
            return KApply('OK', [])
        status_int, _ = convert_string_to_uint(status)
        if status_int == 0:
            return KApply('OK', [])
        if status_int == 4:
            return KApply('UserError', [])

        raise ValueError("Status code %s not supported" % status)

    if ('out' in expect) and (expect['out'] != '*'):
        expect_out = mandos_arguments_to_klist(expect['out'])
        k_steps.append(KApply('checkExpectOut', [expect_out]))
    if ('status' in expect) and (expect['status'] != '*'):
        k_steps.append(KApply('checkExpectStatus', [int_to_kreturncode(expect['status'])]))
    if ('message' in expect) and (expect['message'] != '*'):
        k_steps.append(KApply('checkExpectMessage', [mandos_argument_to_kbytes(expect['message'])]))
    if ('logs' in expect) and (expect['logs'] != '*'):
        logs = []
        for log in expect['logs']:
            address = mandos_argument_to_kbytes(log['address'])
            identifier = mandos_argument_to_kbytes(log['identifier'])
            topics = mandos_arguments_to_klist(log['topics'])
            data = mandos_argument_to_kbytes(log['data'])
            logEntry = KApply('logEntry', [address, identifier, topics, data])
            logs.append(logEntry)
        k_steps.append(KApply('checkExpectLogs', [KList(logs)]))
    return k_steps

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
    if 'blockRandomSeed' in block_info:
        block_infos += [KApply('blockRandomSeed', [mandos_argument_to_kbytes(block_info['blockRandomSeed'])])]
    return block_infos

def register(with_name: str):
    return KApply('register', [KString(with_name)])

def file_to_module_decl(filename: str, output_dir):
    if filename[-5:] == '.wasm':
        return wasm_file_to_module_decl(filename)
    if filename[-5:] == '.wast' or filename[-4:] == '.wat':
        return wat_file_to_module_decl(filename, output_dir)
    raise ValueError('Filetype not yet supported: %s' % filename)

def wasm_file_to_module_decl(filename: str):
    # Check that file exists.
    with open(filename, 'rb') as f:
        module = wasm2kast.wasm2kast(f, filename)
        return module

def wat_file_to_module_decl(filename: str, output_dir):
    if not os.path.exists(filename):
        raise Exception("file %s does not exist" % filename)
        
    new_wasm_filename = os.path.join(output_dir, os.path.basename(filename) + '.wasm')
    try:
        wat = subprocess.check_output("wat2wasm %s --output=%s" % (filename, new_wasm_filename), shell=True)
    except subprocess.CalledProcessError as e:
        print("Failed: %s" % e.cmd)
        print("return code: %d" % e.returncode)
        print("stdout:")
        print(e.output)
        print("stderr:")
        print(e.stderr)
        raise e
    return wasm_file_to_module_decl(new_wasm_filename)

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

def get_steps_sc_deploy(step, filename, output_dir):
    k_steps = []
    tx = mandos_to_deploy_tx(step['tx'], filename, output_dir)
    k_steps.append(tx)
    if 'expect' in step:
        expect = mandos_to_expect(step['expect'])
        k_steps += expect
    return k_steps

def get_steps_sc_call(step):
    k_steps = []
    tx = mandos_to_call_tx(step['tx'])
    k_steps.append(tx)
    if 'expect' in step:
        expect = mandos_to_expect(step['expect'])
        k_steps += expect
    return k_steps

def get_steps_sc_query(step):
    tx_field = step['tx']
    if 'from' not in tx_field:
        tx_field['from'] = tx_field['to']
    if 'value' not in tx_field:
        tx_field['value'] = str(0)
    if 'arguments' not in tx_field:
        tx_field['arguments'] = []
    if 'gasLimit' not in tx_field:
        tx_field['gasLimit'] = str(2**64 - 1)
    if 'gasPrice' not in tx_field:
        tx_field['gasPrice'] = str(0)
    return get_steps_sc_call(step)

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

def get_steps_set_state(step, filename, output_dir):
    k_steps = []
    if 'accounts' in step:
        set_accounts = [ mandos_to_set_account(address, sections, filename, output_dir) for (address, sections) in step['accounts'].items() ]
        k_steps = k_steps + set_accounts
    if 'newAddresses' in step:
        new_addresses = get_steps_new_addresses(step['newAddresses'])
        k_steps = k_steps + new_addresses
    if 'currentBlockInfo' in step:
        block_infos = mandos_to_block_info(step['currentBlockInfo'])
        set_current_blockInfos = list(map(lambda x: KApply('setCurBlockInfo', [x]), block_infos))
        k_steps = k_steps + set_current_blockInfos
    if 'previousBlockInfo' in step:
        block_infos = mandos_to_block_info(step['previousBlockInfo'])
        set_previous_blockInfos = list(map(lambda x: KApply('setPrevBlockInfo', [x]), block_infos))
        k_steps = k_steps + set_previous_blockInfos
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

def get_steps_as_kseq(filename, output_dir):
    global args
    with open(filename, 'r') as f:
        mandos_test = json.loads(f.read())
    if 'name' in mandos_test:
        if args.verbose:
            print('Reading "%s"' % mandos_test['name'])
    if 'comment' in mandos_test:
        if args.verbose:
            print('Comment:\n"%s"' % mandos_test['comment'])

    k_steps = []
    for step in mandos_test['steps']:
        if step['step'] == 'setState':
            k_steps.append((step['step'], get_steps_set_state(step, filename, output_dir)))
        elif step['step'] == 'scDeploy':
            k_steps.append((step['step'], get_steps_sc_deploy(step, filename, output_dir)))
        elif step['step'] == 'scCall':
            k_steps.append((step['step'], get_steps_sc_call(step)))
        elif step['step'] == 'scQuery':
            k_steps.append((step['step'], get_steps_sc_query(step)))
        elif step['step'] == 'checkState':
            k_steps.append((step['step'], get_steps_check_state(step, filename)))
        elif step['step'] == 'externalSteps':
            steps_file = get_external_file_path(filename, step['path'])
            print('Load external: %s' % steps_file)
            k_steps = k_steps + get_steps_as_kseq(steps_file, output_dir)
        elif step['step'] == 'transfer':
            k_steps.append((step['step'], get_steps_transfer(step)))
        elif step['step'] == 'validatorReward':
            k_steps.append((step['step'], get_steps_validator_reward(step)))
        else:
            raise Exception('Step %s not implemented yet' % step['step'])
    return k_steps

def run_test_file(template_wasm_config, test_file_path, output_dir, cmd_args):
    global args
    test_name = os.path.basename(test_file_path)
    k_steps = get_steps_as_kseq(test_file_path, output_dir)
    final_config = None

    if cmd_args.log_level == 'none' or cmd_args.log_level == 'per-file':
        # Flatten the list of k_steps, just run them all in one go.
        k_steps = [ ('full', [ y for (_, x) in k_steps for y in x ]) ]

    (symbolic_config, init_subst) = pyk.splitConfigFrom(template_wasm_config)

    for i in range(len(k_steps)):
        step_name, curr_step = k_steps[i]
        if args.verbose:
            print('Executing step %s' % step_name)
        init_subst['K_CELL'] = KSequence(curr_step)

        init_config = pyk.substitute(symbolic_config, init_subst)

        input_json = config_to_kast_term(init_config)
        krun_args = [ '--term', '--debug']

        # Run: generate a new JSON as a temporary file, then read that as the new wasm state.
        if cmd_args.log_level != 'none':
            log_intermediate_state("%s_%d_%s.pre" % (test_name, i, step_name), init_config, output_dir)
        (rc, new_wasm_config, err) = pyk.krunJSONLegacy(WASM_definition_llvm_no_coverage_dir, input_json, krunArgs = krun_args, teeOutput=True)
        if rc != 0:
            print('output:\n%s' % new_wasm_config, file=sys.stderr)
            print(pyk.prettyPrintKast(new_wasm_config, WASM_symbols_llvm_no_coverage))
            raise Exception("Received error while running: " + err )

        final_config = new_wasm_config

        if cmd_args.log_level != 'none':
            log_intermediate_state("%s_%d_%s" % (test_name, i, step_name), new_wasm_config, output_dir)

        # Check if the k cell is empty
        (symbolic_config, init_subst) = pyk.splitConfigFrom(new_wasm_config)
        k_cell = init_subst['K_CELL']
        assert k_cell['node'] == 'KSequence' and k_cell['arity'] == 0, "k cell not empty, contains a sequence of %d items.\nSee %s" % (k_cell['arity'], output_dir)

    return final_config

# ... Setup Elrond Wasm

def log_intermediate_state(name, config, output_dir):
    with open('%s/%s' % (output_dir, name), 'w') as f:
        f.write(json.dumps(config_to_kast_term(config)))
    with open('%s/%s.pretty.k' % (output_dir, name), 'w') as f:
        pretty = pyk.prettyPrintKast(config, WASM_symbols_llvm_no_coverage)
        f.write(pretty)

# Main Script
args = None

def run_tests():
    global args
    testArgs = argparse.ArgumentParser(description='')
    testArgs.add_argument('files', metavar='N', type=str, nargs='+', help='')
    testArgs.add_argument('--coverage', action='store_true', help='Display test coverage data.')
    testArgs.add_argument('--log-level', choices=['none', 'per-file', 'per-step'], default='per-file')
    testArgs.add_argument('--verbose', action='store_true', help='')
    args = testArgs.parse_args()
    tests = args.files

    per_test_coverage = []

    template_wasm_config = pyk.readKastTerm('src/elrond-runtime.loaded.json')
    cells = pyk.splitConfigFrom(template_wasm_config)[1]
    assert cells['K_CELL']['arity'] == 0

    coverage = cov.Coverage()
    for test in tests:
        if args.verbose:
            print("Running test %s" % test)
        tmpdir = tempfile.mkdtemp(prefix="mandos_")
        if args.verbose:
            print("Intermediate test outputs stored in:\n%s" % tmpdir)

        initial_name = "0000_initial_config"
        with open('%s/%s' % (tmpdir, initial_name), 'w') as f:
            f.write(json.dumps(config_to_kast_term(template_wasm_config)))

        result_wasm_config = run_test_file(template_wasm_config, test, tmpdir, args)

        if args.coverage:
            end_config = result_wasm_config #pyk.readKastTerm(os.path.join(tmpdir, test_name))

            collect_data_func = lambda entry: (int(entry['args'][0]['token']), int(entry['args'][1]['token']))

            func_cov_filter_func = lambda term: 'label' in term and term['label'] == 'fcd'
            func_cov = cov.get_coverage_data(end_config, 'COVEREDFUNCS_CELL', func_cov_filter_func, collect_data_func)

            block_cov_filter_func = lambda term: 'label' in term and term['label'] == 'blockUid'
            block_cov = cov.get_coverage_data(end_config, 'COVEREDBLOCK_CELL', block_cov_filter_func, collect_data_func)

            mods = cov.get_module_filename_map(result_wasm_config)

            cov_data = { 'func_cov': func_cov, 'block_cov': block_cov, 'idx2file': mods }

            coverage.add_coverage(cov_data, unnamed='import')

        if args.verbose:
            print('See %s' % tmpdir)
            print()

    if args.coverage:
        text_modules = cov.insert_coverage_on_text_module(coverage, imports_mod_name='import')
        for module in text_modules:
            for line in module.splitlines():
                print(line.decode('utf8'))


if __name__ == "__main__":
    run_tests()
