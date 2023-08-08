#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
from pyk.kast.inner import KSequence, KInner, KToken, KApply, Subst, KSort
from pyk.ktool.krun import KRun
from pyk.kast.manip import split_config_from
from pyk.prelude.collections import set_of
import resource
import subprocess
import sys
from Cryptodome.Hash import keccak
import tempfile
import os
import wasm2kast
from kwasm_ast import KString, KInt, KBytes

def flatten(l):
    return [item for sublist in l for item in sublist]

def wrapBytes(bs: KInner):
    assert bs.sort == KSort('Bytes')
    return KApply('wrapBytes', [bs])

def KWasmString(value):
    return KToken('"%s"' % value, 'WasmStringToken')

def KMap(kitem_pairs, empty_map:str=".Map", map_item:str="_|->_", map_concat:str="_Map_"):
    """Takes a list of pairs of KItems and produces a Map with them as keys and values."""
    if len(kitem_pairs) == 0:
        return KApply(empty_map, [])
    ((k, v), tail) = (kitem_pairs[0], kitem_pairs[1:])
    res = KApply(map_item, [k, v])
    for (k, v) in tail:
        new_item = KApply(map_item, [k, v])
        res = KApply(map_concat, [res, new_item])
    return res

def KMapBytesToBytes(kitem_pairs):
    return KMap(
        kitem_pairs,
        empty_map=".MapBytesToBytes",
        map_item="_Bytes2Bytes|->_",
        map_concat="_MapBytesToBytes_")

def KList(items, list_item:str="ListItem", empty:str=".List", concat:str="_List_"):
    list_items = list(map(lambda x: KApply(list_item, [x]), items))
    def KList_aux(lis):
        if lis == []:
            return KApply(empty, [])
        head = lis[0]
        tail = KList_aux(lis[1:])
        return KApply(concat, [head, tail])
    return KList_aux(list_items)

def ListBytes(items):
    return KList(items, empty=".ListBytes", list_item="ListBytesItem", concat="_ListBytes_")

def config_to_kast_term(config):
    return { 'format' : 'KAST', 'version': 2, 'term': config.to_dict() }

###############################

WASM_definition_main_file = 'mandos'
WASM_definition_llvm_dir = Path('.build/defn/llvm')
WASM_definition_llvm_kompiled_dir = WASM_definition_llvm_dir / (WASM_definition_main_file + '-kompiled')

addr_prefix   = "address:"
sc_prefix     = "sc:"
keccak_prefix = "keccak256:"
u64_prefix    = "u64:"
u32_prefix    = "u32:"
u16_prefix    = "u16:"
u8_prefix     = "u8:"

biguint_prefix = "biguint:"
nested_prefix  = "nested:"

# number of zero bytes every smart contract address begins with.
sc_addr_num_leading_zeros = 8

# sc_addr_reserved_prefix_len is the number of zero bytes every smart contract address begins with.
# Its value is 10.
# 10 = 8 zeros for all SC addresses + 2 zeros as placeholder for the VM type.
sc_addr_reserved_prefix_len = sc_addr_num_leading_zeros + 2

sys.setrecursionlimit(2100000000)
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

    raise ValueError(f'Argument type not yet supported: {arg}')

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
        addr_arg = raw_str[len(addr_prefix):]
        return address_expression(addr_arg)

    # smart contract address
    if raw_str.startswith(sc_prefix):
        addr_arg = raw_str[len(sc_prefix):]
        return sc_expression(addr_arg)

    # keccak256
    if raw_str.startswith(keccak_prefix):
        input_bytes = mandos_string_to_bytes(raw_str[len(keccak_prefix):])
        k = keccak.new(digest_bits=256)
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

    if raw_str.startswith(nested_prefix):
        return interpret_nested_bytes(raw_str[len(nested_prefix):])

    # unsigned integer
    try:
        num_int, num_len = convert_string_to_uint(raw_str)
        return num_int.to_bytes(num_len, 'big')
    except ValueError:
        pass

    raise ValueError("Argument type not yet supported: %s" % raw_str)

def interpret_nested_bytes(raw_str):
    nested_bytes = mandos_string_to_bytes(raw_str)
    length_bytes = len(nested_bytes).to_bytes(4, 'big')
    return length_bytes + nested_bytes

def address_expression(addr_arg: str) -> bytes:
    return create_address_optional_shard_id(addr_arg, 0)

def create_address_optional_shard_id(input: str, num_leading_zeros: int) -> bytes:
    # TODO implement addresses with optional shard ID: https://github.com/multiversx/mx-chain-scenario-go/blob/3d0b8aea51a94fe640bf1c62a78dd5b4abbad459/expression/interpreter/functions.go#L52
    zero_padded = "\0" * num_leading_zeros + input
    padded_addr = zero_padded.ljust(32, '_')
    padded_addr_bytes = bytes(padded_addr[:32], 'ascii')
    return padded_addr_bytes

def sc_expression(input: str) -> bytes:
    addr = create_address_optional_shard_id(input, sc_addr_reserved_prefix_len)
    # TODO insert VM type: https://github.com/multiversx/mx-chain-scenario-go/blob/3d0b8aea51a94fe640bf1c62a78dd5b4abbad459/expression/interpreter/functions.go#L78
    return addr

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
    bs = mandos_argument_to_bytes(argument)
    return KBytes(bs)

def mandos_arguments_to_klist(arguments: list):
    tokenized = list(map(lambda x: mandos_argument_to_kbytes(x), arguments))
    wrapped = list(map(wrapBytes, tokenized))
    return ListBytes(wrapped)

def mandos_to_set_account(address, sections, filename, output_dir):
    """Creates a K account cell from a Mandos account description. """
    address_value = mandos_argument_to_kbytes(address)
    nonce_value   = mandos_int_to_kint(sections.get('nonce', '0'))
    balance_value = mandos_int_to_kint(sections.get('balance', '0'))
    owner_value   = mandos_argument_to_kbytes(sections.get('owner', ''))
    code_value = KApply(".Code", [])
    if 'code' in sections:
        code_path = get_contract_code(sections['code'], filename)
        if code_path is not None:
            code_value = file_to_module_decl(code_path, output_dir)

    storage_pairs = [ (mandos_argument_to_kbytes(k), mandos_argument_to_kbytes(v)) for (k, v) in sections.get('storage', {}).items() ]
    storage_pairs = [ (wrapBytes(k), wrapBytes(v)) for (k, v) in storage_pairs ]
    storage_value = KMapBytesToBytes(storage_pairs)

    set_account_steps = [KApply('setAccount', [address_value, nonce_value, balance_value, code_value, owner_value, storage_value])]

    if 'esdt' in sections:
        for k, v in sections['esdt'].items():
            tok_id = mandos_argument_to_kbytes(k)
            value = mandos_to_esdt_value(v)
            step = KApply('setEsdtBalance', [address_value, tok_id, value])
            set_account_steps.append(step)

    return set_account_steps

# ESDT value is either an integer (compact) or a dictionary (full) 
def mandos_to_esdt_value(v):
    try:
        return mandos_int_to_kint(v)
    except TypeError:
        # TODO properly parse 'instances'
        return mandos_int_to_kint(v['instances'][0]['balance'])

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
        storage_pairs = [ (wrapBytes(k), wrapBytes(v)) for (k, v) in storage_pairs ]
        storage_value = KMapBytesToBytes(storage_pairs)
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
    value = mandos_int_to_kint(getEgldValue(tx))
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
    value = mandos_int_to_kint(getEgldValue(tx))
    esdt_value = mandos_esdt_to_klist(tx.get('esdtValue', []))
    function = KWasmString(tx['function'])
    arguments = mandos_arguments_to_klist(tx['arguments'])
    gasLimit = mandos_int_to_kint(tx['gasLimit'])
    gasPrice = mandos_int_to_kint(tx['gasPrice'])

    callTx = KApply('callTx', [sender, to, value, esdt_value, function, arguments, gasLimit, gasPrice])
    return callTx

def mandos_esdt_to_klist(esdt_values):
    def esdt(esdt_value):
        tok_id = mandos_argument_to_kbytes(esdt_value['tokenIdentifier'])
        value = mandos_int_to_kint(esdt_value['value'])
        nonce = mandos_int_to_kint(esdt_value.get('nonce', '0'))
        return KApply('esdtTransfer', [tok_id, value, nonce])

    return KList(esdt(i) for i in esdt_values)


def mandos_to_transfer_tx(tx):
    sender = mandos_argument_to_kbytes(tx['from'])
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(getEgldValue(tx))
    
    transferTx = KApply('transferTx', [sender, to, value])
    return transferTx

def mandos_to_validator_reward_tx(tx):
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(getEgldValue(tx))
    rewardTx = KApply('validatorRewardTx', [to, value])
    return rewardTx

def getEgldValue(tx):
    # backwards compatibility
    if 'value' in tx:
        return tx['value']
    return tx.get('egldValue', "0")

# TODO: implement checkExpect gas, refund
def mandos_to_expect(expect):
    k_steps = []

    def int_to_kreturncode(status: str):
        if status == "":
            return KApply('OK', [])
        status_int, _ = convert_string_to_uint(status)

        STATUS_CODES = {
            0: 'OK',
            1: 'FunctionNotFound',         
            2: 'FunctionWrongSignature',
            3: 'ContractNotFound',
            4: 'UserError',
            5: 'OutOfGas',
            6: 'AccountCollision',
            7: 'OutOfFunds',
            8: 'CallStackOverFlow',
            9: 'ContractInvalid',
            10: 'ExecutionFailed',
            11: 'UpgradeFailed',
            12: 'SimulateFailed',
        }

        if status_int in STATUS_CODES:
            return KApply(STATUS_CODES[status_int], [])
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
            identifier = mandos_argument_to_kbytes(log['endpoint'])
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

def mandos_to_query_tx(tx):
    to = mandos_argument_to_kbytes(tx['to'])
    function = KWasmString(tx['function'])
    arguments = mandos_arguments_to_klist(tx.get('arguments', []))

    queryTx = KApply('queryTx', [to, function, arguments])
    return queryTx

def get_steps_sc_query(step):
    k_steps = []

    tx = mandos_to_query_tx(step['tx'])
    k_steps.append(tx)

    if 'expect' in step:
        expect = mandos_to_expect(step['expect'])
        k_steps += expect
    
    return k_steps

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
        k_steps = k_steps + flatten(set_accounts)
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
            address_bytes = [mandos_argument_to_kbytes(a) for a in step['accounts'].keys()]
            all_addresses = set_of(address_bytes)
            k_steps.append(KApply('checkNoAdditionalAccounts', [all_addresses]))
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

def run_test_file(krun: KRun, template_wasm_config, test_file_path, output_dir, cmd_args):
    global args
    test_name = os.path.basename(test_file_path)
    k_steps = get_steps_as_kseq(test_file_path, output_dir)
    final_config = None

    if cmd_args.log_level == 'none' or cmd_args.log_level == 'per-file':
        # Flatten the list of k_steps, just run them all in one go.
        k_steps = [ ('full', [ y for (_, x) in k_steps for y in x ]) ]

    (symbolic_config, init_subst) = split_config_from(template_wasm_config)

    for i in range(len(k_steps)):
        step_name, curr_step = k_steps[i]
        if args.verbose:
            print('Executing step %s' % step_name)
        init_subst['K_CELL'] = KSequence(curr_step)

        init_config = Subst(init_subst)(symbolic_config)

        # Run: generate a new JSON as a temporary file, then read that as the new wasm state.
        if cmd_args.log_level != 'none':
            log_intermediate_state(krun, "%s_%d_%s.pre" % (test_name, i, step_name), init_config, output_dir)

        new_config = krun_config(krun, init_config=init_config)
        final_config = new_config

        if cmd_args.log_level != 'none':
            log_intermediate_state(krun, "%s_%d_%s" % (test_name, i, step_name), final_config, output_dir)

        # Check if the k cell is empty
        symbolic_config, init_subst = split_config_from(new_config)
        k_cell = init_subst['K_CELL']

        if not isinstance(k_cell, KSequence) or k_cell.arity != 0:
            raise ValueError(f'k cell not empty, contains a sequence of {k_cell.arity} items.\nSee {output_dir}')

    return final_config

def krun_config(krun: KRun, init_config: KInner) -> KInner:
    kore_config = krun.kast_to_kore(init_config, sort=KSort('GeneratedTopCell'))
    kore_config = krun.run_kore_term(kore_config)
    return krun.kore_to_kast(kore_config)

# ... Setup Elrond Wasm

def log_intermediate_state(krun: KRun, name, config, output_dir):
    with open('%s/%s' % (output_dir, name), 'w') as f:
        f.write(json.dumps(config_to_kast_term(config)))
    with open('%s/%s.pretty.k' % (output_dir, name), 'w') as f:
        pretty = krun.pretty_print(config)
        f.write(pretty)

# Main Script
args = None

def run_tests():
    global args
    testArgs = argparse.ArgumentParser(description='')
    testArgs.add_argument('files', metavar='N', type=str, nargs='+', help='')
    testArgs.add_argument('--log-level', choices=['none', 'per-file', 'per-step'], default='per-file')
    testArgs.add_argument('--verbose', action='store_true', help='')
    args = testArgs.parse_args()
    tests = args.files

    krun = KRun(WASM_definition_llvm_kompiled_dir)
    
    with open('src/elrond-runtime.loaded.json', 'r') as f:
        runtime_json = json.load(f)
        template_wasm_config = KInner.from_dict(runtime_json['term'])
    
    _, cells = split_config_from(template_wasm_config)
    assert cells['K_CELL'].arity == 0

    for test in tests:
        if args.verbose:
            print("Running test %s" % test)
        tmpdir = tempfile.mkdtemp(prefix="mandos_")
        if args.verbose:
            print("Intermediate test outputs stored in:\n%s" % tmpdir)

        initial_name = "0000_initial_config"
        with open('%s/%s' % (tmpdir, initial_name), 'w') as f:
            f.write(json.dumps(config_to_kast_term(template_wasm_config)))

        run_test_file(krun, template_wasm_config, test, tmpdir, args)

        if args.verbose:
            print('See %s' % tmpdir)
            print()

if __name__ == "__main__":
    run_tests()
