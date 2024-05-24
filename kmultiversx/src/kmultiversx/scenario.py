from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from typing import TYPE_CHECKING, Iterable, Optional

from Cryptodome.Hash import keccak
from pyk.cli.utils import dir_path
from pyk.kast.inner import KApply, KSequence, KToken, Subst
from pyk.kast.manip import split_config_from
from pyk.kdist import kdist
from pyk.ktool.krun import KRun
from pyk.prelude.collections import set_of
from pykwasm.kwasm_ast import KBytes, KInt, KString

from kmultiversx.utils import (
    flatten,
    kast_to_json_str,
    krun_config,
    load_wasm,
    load_wasm_from_mxsc,
    read_mandos_runtime,
)

if TYPE_CHECKING:
    from pyk.kast.inner import KInner


def wrapBytes(bs: KInner) -> KInner:  # noqa: N802
    return KApply('wrapBytes', [bs])


def KWasmString(value: str) -> KToken:  # noqa: N802
    return KToken('"%s"' % value, 'WasmStringToken')


def KMap(  # noqa: N802
    kitem_pairs: list[tuple[KInner, KInner]],
    empty_map: str = '.Map',
    map_item: str = '_|->_',
    map_concat: str = '_Map_',
) -> KInner:
    """Takes a list of pairs of KItems and produces a Map with them as keys and values."""
    if len(kitem_pairs) == 0:
        return KApply(empty_map, [])
    ((k, v), tail) = (kitem_pairs[0], kitem_pairs[1:])
    res = KApply(map_item, [k, v])
    for k, v in tail:
        new_item = KApply(map_item, [k, v])
        res = KApply(map_concat, [res, new_item])
    return res


def KMapBytesToBytes(kitem_pairs: list[tuple[KInner, KInner]]) -> KInner:  # noqa: N802
    return KMap(kitem_pairs, empty_map='.MapBytesToBytes', map_item='_Bytes2Bytes|->_', map_concat='_MapBytesToBytes_')


def KList(  # noqa: N802
    items: Iterable[KInner], list_item: str = 'ListItem', empty: str = '.List', concat: str = '_List_'
) -> KInner:
    list_items = [KApply(list_item, [x]) for x in items]

    def KList_aux(lis: list[KApply]) -> KInner:  # noqa: N802
        if lis == []:
            return KApply(empty, [])
        head = lis[0]
        tail = KList_aux(lis[1:])
        return KApply(concat, [head, tail])

    return KList_aux(list_items)


def ListBytes(items: Iterable[KInner]) -> KInner:  # noqa: N802
    return KList(items, empty='.ListBytes', list_item='ListBytesItem', concat='_ListBytes_')


###############################

addr_prefix = 'address:'
sc_prefix = 'sc:'
keccak_prefix = 'keccak256:'
u64_prefix = 'u64:'
u32_prefix = 'u32:'
u16_prefix = 'u16:'
u8_prefix = 'u8:'

biguint_prefix = 'biguint:'
nested_prefix = 'nested:'

# number of zero bytes every smart contract address begins with.
sc_addr_num_leading_zeros = 8

# sc_addr_reserved_prefix_len is the number of zero bytes every smart contract address begins with.
# Its value is 10.
# 10 = 8 zeros for all SC addresses + 2 zeros as placeholder for the VM type.
sc_addr_reserved_prefix_len = sc_addr_num_leading_zeros + 2

sys.setrecursionlimit(1500000000)


def mandos_int_to_int(mandos_int: str, default_when_empty: int | None = None) -> int:
    if mandos_int == '' and default_when_empty is not None:
        return default_when_empty
    if mandos_int[0:2] == '0x':
        return int(mandos_int, 16)
    unseparated_int = mandos_int.replace(',', '')
    return int(unseparated_int)


def mandos_int_to_kint(mandos_int: str, default_when_empty: int | None = None) -> KToken:
    parsed_int = mandos_int_to_int(mandos_int, default_when_empty)
    return KInt(parsed_int)


def mandos_argument_to_bytes(arg: str | list | dict) -> bytes:
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


def mandos_string_to_bytes(raw_str: str) -> bytes:
    if raw_str == '':
        return bytes()

    if '|' in raw_str:
        splits = raw_str.split('|')
        bs = bytearray()
        for s in splits:
            bs += bytearray(mandos_argument_to_bytes(s))
        return bytes(bs)

    if raw_str == 'false':
        return bytes()
    if raw_str == 'true':
        return bytes([1])

    # string prefix
    if raw_str.startswith('str:'):
        return bytes(raw_str[4:], 'ascii')
    if raw_str.startswith("''") or raw_str.startswith('``'):
        return bytes(raw_str[2:], 'ascii')

    # address
    if raw_str.startswith(addr_prefix):
        addr_arg = raw_str[len(addr_prefix) :]
        return address_expression(addr_arg)

    # smart contract address
    if raw_str.startswith(sc_prefix):
        addr_arg = raw_str[len(sc_prefix) :]
        return sc_expression(addr_arg)

    # keccak256
    if raw_str.startswith(keccak_prefix):
        input_bytes = mandos_string_to_bytes(raw_str[len(keccak_prefix) :])
        k = keccak.new(digest_bits=256)
        k.update(input_bytes)
        return bytes.fromhex(k.hexdigest())

    # biguint
    if raw_str.startswith(biguint_prefix):
        bs = bytearray()
        num_int, num_len = convert_string_to_uint(raw_str[len(biguint_prefix) :])
        bs += bytearray(num_len.to_bytes(4, 'big'))
        bs += bytearray(num_int.to_bytes(num_len, 'big'))
        return bytes(bs)

    # fixed width number
    if raw_str.startswith(u64_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u64_prefix) :], 8)
    if raw_str.startswith(u32_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u32_prefix) :], 4)
    if raw_str.startswith(u16_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u16_prefix) :], 2)
    if raw_str.startswith(u8_prefix):
        return mandos_interpret_as_uint_fixedwidth(raw_str[len(u8_prefix) :], 1)

    # signed integer
    if raw_str.startswith('+') or raw_str.startswith('-'):
        try:
            num_int, num_len = convert_string_to_sint(raw_str)
            return num_int.to_bytes(length=num_len, byteorder='big', signed=True)
        except ValueError:
            pass

    if raw_str.startswith(nested_prefix):
        return interpret_nested_bytes(raw_str[len(nested_prefix) :])

    # unsigned integer
    try:
        num_int, num_len = convert_string_to_uint(raw_str)
        return num_int.to_bytes(num_len, 'big')
    except ValueError:
        pass

    raise ValueError(f'Argument type not yet supported: {raw_str}')


def interpret_nested_bytes(raw_str: str) -> bytes:
    nested_bytes = mandos_string_to_bytes(raw_str)
    length_bytes = len(nested_bytes).to_bytes(4, 'big')
    return length_bytes + nested_bytes


def address_expression(addr_arg: str) -> bytes:
    return create_address_optional_shard_id(addr_arg, 0)


def create_address_optional_shard_id(input: str, num_leading_zeros: int) -> bytes:
    # TODO implement addresses with optional shard ID: https://github.com/multiversx/mx-chain-scenario-go/blob/3d0b8aea51a94fe640bf1c62a78dd5b4abbad459/expression/interpreter/functions.go#L52
    zero_padded = '\0' * num_leading_zeros + input
    padded_addr = zero_padded.ljust(32, '_')
    padded_addr_bytes = bytes(padded_addr[:32], 'ascii')
    return padded_addr_bytes


def sc_expression(input: str) -> bytes:
    addr = create_address_optional_shard_id(input, sc_addr_reserved_prefix_len)
    # TODO insert VM type: https://github.com/multiversx/mx-chain-scenario-go/blob/3d0b8aea51a94fe640bf1c62a78dd5b4abbad459/expression/interpreter/functions.go#L78
    return addr


def mandos_interpret_as_uint_fixedwidth(raw_str: str, width: int) -> bytes:
    num_int, _ = convert_string_to_uint(raw_str)
    return num_int.to_bytes(width, byteorder='big')


def convert_string_to_uint(raw_str: str) -> tuple[int, int]:
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
    if num_int < 0:
        raise ValueError(f'Negative number not allowed in this context: {raw_str}')
    num_len = (num_int.bit_length() + 7) // 8
    return (num_int, num_len)


def convert_string_to_sint(raw_str: str) -> tuple[int, int]:
    num_int, _ = convert_string_to_uint(raw_str[1:])
    if raw_str.startswith('-'):
        num_int = -num_int
    num_len = (8 + (num_int + (num_int < 0)).bit_length()) // 8
    return (num_int, num_len)


def mandos_argument_to_kbytes(argument: str) -> KToken:
    bs = mandos_argument_to_bytes(argument)
    return KBytes(bs)


def mandos_arguments_to_klist(arguments: list[str]) -> KInner:
    tokenized = [mandos_argument_to_kbytes(x) for x in arguments]
    wrapped = list(map(wrapBytes, tokenized))
    return ListBytes(wrapped)


def mandos_to_set_account(address: str, sections: dict, filename: str, output_dir: str) -> list[KApply]:
    """Creates a K account cell from a Mandos account description."""
    address_value = mandos_argument_to_kbytes(address)
    nonce_value = mandos_int_to_kint(sections.get('nonce', '0'))
    balance_value = mandos_int_to_kint(sections.get('balance', '0'))
    owner_value = mandos_argument_to_kbytes(sections.get('owner', ''))
    code_value: KInner = KApply('.Code', [])
    if 'code' in sections:
        code_path = get_contract_code(sections['code'], filename)
        if code_path is not None:
            code_value = file_to_module_decl(code_path, output_dir)

    storage_pairs = [
        (mandos_argument_to_kbytes(k), mandos_argument_to_kbytes(v)) for (k, v) in sections.get('storage', {}).items()
    ]
    wrapped_pairs = [(wrapBytes(k), wrapBytes(v)) for (k, v) in storage_pairs]
    storage_value = KMapBytesToBytes(wrapped_pairs)

    set_account_steps = [
        KApply('setAccount', [address_value, nonce_value, balance_value, code_value, owner_value, storage_value])
    ]

    if 'esdt' in sections:
        for k, v in sections['esdt'].items():
            token_kbytes = mandos_argument_to_kbytes(k)

            for nonce, amount, metadata in mandos_to_esdt_instances(v):
                step = KApply('setEsdtBalance', [address_value, token_kbytes, KInt(nonce), metadata, KInt(amount)])
                set_account_steps.append(step)

            roles = mandos_to_esdt_roles(v)
            if roles is not None:
                step = KApply('setEsdtRoles', [address_value, token_kbytes, set_of(roles)])
                set_account_steps.append(step)

            if 'lastNonce' in v:
                last_nonce = mandos_int_to_kint(v['lastNonce'])
                set_account_steps.append(KApply('setEsdtLastNonce', [address_value, token_kbytes, last_nonce]))

    return set_account_steps


def mandos_to_esdt_metadata(instance: dict | None) -> KInner:
    if instance is None:
        return KApply('.esdtMetadata', [])

    nonce = mandos_int_to_int(instance.get('nonce', '0'), 0)
    if nonce == 0:
        return KApply('.esdtMetadata', [])

    return KApply(
        'esdtMetadata',
        [
            mandos_argument_to_kbytes(instance.get('name', '')),
            KInt(nonce),
            mandos_argument_to_kbytes(instance.get('creator', '')),
            mandos_int_to_kint(instance.get('royalties', '0')),
            mandos_argument_to_kbytes(instance.get('hash', '')),
            ListBytes(mandos_argument_to_kbytes(i) for i in instance.get('uris', [])),
            mandos_argument_to_kbytes(instance.get('attributes', '')),
        ],
    )


def mandos_to_esdt_instances(value: str | dict) -> list[tuple[int, int, KInner]]:
    """
    returns (nonce, value, metadata)
    """
    if isinstance(value, str):
        return [(0, mandos_int_to_int(value), mandos_to_esdt_metadata(None))]
    if 'instances' in value:
        res = []
        for inst in value['instances']:
            nonce = inst.get('nonce', '0')
            nonce_int = mandos_int_to_int(nonce, 0)
            balance_int = mandos_int_to_int(inst['balance'])
            metadata = mandos_to_esdt_metadata(inst)
            res.append((nonce_int, balance_int, metadata))

        return res

    return []


ESDT_ROLES = {
    'ESDTRoleLocalMint',
    'ESDTRoleLocalBurn',
    'ESDTRoleNFTCreate',
    'ESDTRoleNFTAddQuantity',
    'ESDTRoleNFTBurn',
    'ESDTRoleNFTAddURI',
    'ESDTRoleNFTUpdateAttributes',
    'ESDTTransferRole',
    'None',
}


def mandos_to_esdt_roles(v: str | dict) -> list[KInner] | None:
    def str_to_kast(s: str) -> KInner:
        if s in ESDT_ROLES:
            return KApply(s, [])
        raise ValueError(f'ESDT role {s} not supported')

    if isinstance(v, str):
        return None
    if 'roles' not in v:
        return None
    return [str_to_kast(r) for r in v['roles']]


def mandos_to_check_account(address: str, sections: dict, filename: str) -> list:
    k_steps: list[KInner] = []
    address_value = mandos_argument_to_kbytes(address)
    if ('nonce' in sections) and (sections['nonce'] != '*'):
        nonce_value = mandos_int_to_kint(sections['nonce'])
        k_steps.append(KApply('checkAccountNonce', [address_value, nonce_value]))
    if ('balance' in sections) and (sections['balance'] != '*'):
        balance_value = mandos_int_to_kint(sections['balance'])
        k_steps.append(KApply('checkAccountBalance', [address_value, balance_value]))
    if ('storage' in sections) and (sections['storage'] != '*'):
        # TODO move storage map creation to a function and reuse in mandos_to_set_account
        storage_pairs = []
        for k, v in sections['storage'].items():
            k_bytes = mandos_argument_to_kbytes(k)
            v_bytes = mandos_argument_to_kbytes(v)
            storage_pairs.append((k_bytes, v_bytes))
        wrapped_pairs = [(wrapBytes(k), wrapBytes(v)) for (k, v) in storage_pairs]
        storage_value = KMapBytesToBytes(wrapped_pairs)
        k_steps.append(KApply('checkAccountStorage', [address_value, storage_value]))
    if ('code' in sections) and (sections['code'] != '*'):
        code_path = get_contract_code(sections['code'], filename)
        if code_path is None:
            code_path = ''
        k_code_path = KString(code_path)
        k_steps.append(KApply('checkAccountCode', [address_value, k_code_path]))
    if ('esdt' in sections) and (sections['esdt'] != '*'):
        for token, value in sections['esdt'].items():
            token_kbytes = mandos_argument_to_kbytes(token)

            # TODO check NFT/SFT metadata
            for nonce, amount, _ in mandos_to_esdt_instances(value):
                step = KApply('checkAccountESDTBalance', [address_value, token_kbytes, KInt(nonce), KInt(amount)])
                k_steps.append(step)

            roles = mandos_to_esdt_roles(value)
            if roles is not None:
                step = KApply('checkEsdtRoles', [address_value, token_kbytes, set_of(roles)])
                k_steps.append(step)

    k_steps.append(KApply('checkedAccount', [address_value]))
    return k_steps


def mandos_to_deploy_tx(tx: dict, filename: str, output_dir: str) -> KInner:
    sender = mandos_argument_to_kbytes(tx['from'])
    value = mandos_int_to_kint(get_egld_value(tx))
    arguments = mandos_arguments_to_klist(tx['arguments'])
    gas_limit = mandos_int_to_kint(tx['gasLimit'])
    gas_price = mandos_int_to_kint(tx.get('gasPrice', '0'), default_when_empty=0)

    code = get_contract_code(tx['contractCode'], filename)
    assert isinstance(code, str)
    module = file_to_module_decl(code, output_dir)

    return KApply('deployTx', [sender, value, module, arguments, gas_limit, gas_price])


def mandos_to_call_tx(tx: dict) -> KInner:
    sender = mandos_argument_to_kbytes(tx['from'])
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(get_egld_value(tx))
    esdt_value = mandos_esdt_to_klist(tx.get('esdtValue', []))
    function = KWasmString(tx['function'])
    arguments = mandos_arguments_to_klist(tx.get('arguments', []))
    gas_limit = mandos_int_to_kint(tx['gasLimit'])
    gas_price = mandos_int_to_kint(tx.get('gasPrice', '0'), default_when_empty=0)

    return KApply('callTx', [sender, to, value, esdt_value, function, arguments, gas_limit, gas_price])


def mandos_esdt_to_klist(esdt_values: list[dict]) -> KInner:
    def esdt(esdt_value: dict) -> KApply:
        tok_id = mandos_argument_to_kbytes(esdt_value['tokenIdentifier'])
        value = mandos_int_to_kint(esdt_value['value'])
        nonce = mandos_int_to_kint(esdt_value.get('nonce', '0'))
        return KApply('esdtTransfer', [tok_id, value, nonce])

    return KList(esdt(i) for i in esdt_values)


def mandos_to_transfer_tx(tx: dict) -> KInner:
    sender = mandos_argument_to_kbytes(tx['from'])
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(get_egld_value(tx))

    return KApply('transferTx', [sender, to, value])


def mandos_to_validator_reward_tx(tx: dict) -> KApply:
    to = mandos_argument_to_kbytes(tx['to'])
    value = mandos_int_to_kint(get_egld_value(tx))

    return KApply('validatorRewardTx', [to, value])


def get_egld_value(tx: dict) -> str:
    # backwards compatibility
    if 'value' in tx:
        return tx['value']
    return tx.get('egldValue', '0')


# TODO: implement checkExpect gas, refund
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


def mandos_to_expect(expect: dict) -> list:
    k_steps = []

    def int_to_kreturncode(status: str) -> KApply:
        if status == '':
            return KApply('OK', [])
        status_int, _ = convert_string_to_uint(status)

        if status_int in STATUS_CODES:
            return KApply(STATUS_CODES[status_int], [])
        raise ValueError(f'Status code {status} not supported')

    if ('out' in expect) and (expect['out'] != '*'):
        expect_out = mandos_arguments_to_klist(expect['out'])
        k_steps.append(KApply('checkExpectOut', [expect_out]))
    if ('status' in expect) and (expect['status'] != '*'):
        k_steps.append(KApply('checkExpectStatus', [int_to_kreturncode(expect['status'])]))
    if ('message' in expect) and (expect['message'] != '*'):
        k_steps.append(KApply('checkExpectMessage', [mandos_argument_to_kbytes(expect['message'])]))
    # Log checks are not implemented in the semantics
    # if ('logs' in expect) and (expect['logs'] != '*'):
    #     logs = []
    #     for log in expect['logs']:
    #         address = mandos_argument_to_kbytes(log['address'])
    #         identifier = mandos_argument_to_kbytes(log['endpoint'])
    #         topics = mandos_arguments_to_klist(log['topics'])
    #         data = mandos_argument_to_kbytes(log['data'])
    #         log_entry = KApply('logEntry', [address, identifier, topics, data])
    #         logs.append(log_entry)
    #     k_steps.append(KApply('checkExpectLogs', [KList(logs)]))
    return k_steps


def mandos_to_block_info(block_info: dict) -> list:
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


def register(with_name: str) -> KInner:
    return KApply('register', [KString(with_name)])


def file_to_module_decl(filename: str, output_dir: str) -> KInner:
    if filename[-5:] == '.wasm':
        return load_wasm(filename)
    if filename[-5:] == '.wast' or filename[-4:] == '.wat':
        return wat_file_to_module_decl(filename, output_dir)
    if filename[-10:] == '.mxsc.json':
        return load_wasm_from_mxsc(filename)

    raise ValueError(f'Filetype not yet supported: {filename}')


def wat_file_to_module_decl(filename: str, output_dir: str) -> KInner:
    if not os.path.exists(filename):
        raise Exception(f'file {filename} does not exist')

    new_wasm_filename = os.path.join(output_dir, os.path.basename(filename) + '.wasm')
    try:
        subprocess.check_output(f'wat2wasm {filename} --output={new_wasm_filename}', shell=True)
    except subprocess.CalledProcessError as e:
        print('Failed: %s' % e.cmd)
        print('return code: %d' % e.returncode)
        print('stdout:')
        print(e.output)
        print('stderr:')
        print(e.stderr)
        raise e
    return load_wasm(new_wasm_filename)


def get_external_file_path(test_file: str, rel_path_to_new_file: str) -> str:
    test_file_path = os.path.dirname(test_file)
    ext_file = os.path.normpath(os.path.join(test_file_path, rel_path_to_new_file))
    return ext_file


def get_contract_code(code: str, filename: str) -> Optional[str]:
    if code[0:5] in ('file:', 'mxsc:'):
        return get_external_file_path(filename, code[5:])
    if code == '':
        return None
    raise Exception('Currently only support getting code from file, or empty code.')


def get_steps_sc_deploy(step: dict, filename: str, output_dir: str) -> list:
    k_steps = []
    tx = mandos_to_deploy_tx(step['tx'], filename, output_dir)
    k_steps.append(tx)
    if 'expect' in step:
        expect = mandos_to_expect(step['expect'])
        k_steps += expect
    return k_steps


def get_steps_sc_call(step: dict) -> list:
    k_steps = []
    tx = mandos_to_call_tx(step['tx'])
    k_steps.append(tx)
    if 'expect' in step:
        expect = mandos_to_expect(step['expect'])
        k_steps += expect
    return k_steps


def mandos_to_query_tx(tx: dict) -> KInner:
    to = mandos_argument_to_kbytes(tx['to'])
    function = KWasmString(tx['function'])
    arguments = mandos_arguments_to_klist(tx.get('arguments', []))

    return KApply('queryTx', [to, function, arguments])


def get_steps_sc_query(step: dict) -> list:
    k_steps = []

    tx = mandos_to_query_tx(step['tx'])
    k_steps.append(tx)

    if 'expect' in step:
        expect = mandos_to_expect(step['expect'])
        k_steps += expect

    return k_steps


def get_steps_transfer(step: dict) -> list:
    tx = mandos_to_transfer_tx(step['tx'])
    return [KApply('transfer', [tx])]


def get_steps_validator_reward(step: dict) -> list[KApply]:
    tx = mandos_to_validator_reward_tx(step['tx'])
    return [KApply('validatorReward', [tx])]


def get_steps_new_addresses(new_addresses: Optional[dict]) -> list[KApply]:
    if new_addresses is None:
        return []
    ret: list[KApply] = []
    for new_address in new_addresses:
        creator = mandos_argument_to_kbytes(new_address['creatorAddress'])
        nonce = mandos_int_to_kint(new_address['creatorNonce'])
        new = mandos_argument_to_kbytes(new_address['newAddress'])
        ret.append(KApply('newAddress', [creator, nonce, new]))
    return ret


def get_steps_set_state(step: dict, filename: str, output_dir: str) -> list[KApply]:
    k_steps: list[KApply] = []
    if 'accounts' in step:
        set_accounts = [
            mandos_to_set_account(address, sections, filename, output_dir)
            for (address, sections) in step['accounts'].items()
        ]
        k_steps = k_steps + flatten(set_accounts)
    if 'newAddresses' in step:
        new_addresses = get_steps_new_addresses(step['newAddresses'])
        k_steps = k_steps + new_addresses
    if 'currentBlockInfo' in step:
        block_infos = mandos_to_block_info(step['currentBlockInfo'])
        set_current_block_infos = [KApply('setCurBlockInfo', [x]) for x in block_infos]
        k_steps = k_steps + set_current_block_infos
    if 'previousBlockInfo' in step:
        block_infos = mandos_to_block_info(step['previousBlockInfo'])
        set_previous_block_infos = [KApply('setPrevBlockInfo', [x]) for x in block_infos]
        k_steps = k_steps + set_previous_block_infos
    if k_steps == []:
        raise Exception('Step not implemented: %s' % step)
    return k_steps


def get_steps_check_state(step: dict, filename: str) -> list:
    k_steps = []
    if 'accounts' in step:
        for address, sections in step['accounts'].items():
            if address != '+':
                k_steps += mandos_to_check_account(address, sections, filename)
        if not '+' in step['accounts'].keys():
            address_bytes = [mandos_argument_to_kbytes(a) for a in step['accounts'].keys()]
            all_addresses = set_of(address_bytes)
            k_steps.append(KApply('checkNoAdditionalAccounts', [all_addresses]))
        k_steps.append(KApply('clearCheckedAccounts', []))
    return k_steps


def get_steps_as_kseq(filename: str, output_dir: str, args: argparse.Namespace) -> list:
    with open(filename, 'r') as f:
        mandos_test = json.loads(f.read())
    if 'name' in mandos_test:
        if args.verbose:
            print('Reading "%s"' % mandos_test['name'])
    if 'comment' in mandos_test:
        if args.verbose:
            print('Comment:"%s"' % mandos_test['comment'])

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
            k_steps = k_steps + get_steps_as_kseq(steps_file, output_dir, args)
        elif step['step'] == 'transfer':
            k_steps.append((step['step'], get_steps_transfer(step)))
        elif step['step'] == 'validatorReward':
            k_steps.append((step['step'], get_steps_validator_reward(step)))
        else:
            raise Exception('Step %s not implemented yet' % step['step'])
    return k_steps


def run_test_file(
    krun: KRun,
    template_wasm_config: KInner,
    test_file_path: str,
    output_dir: str,
    cmd_args: argparse.Namespace,
) -> KInner:
    test_name = os.path.basename(test_file_path)
    k_steps = get_steps_as_kseq(test_file_path, output_dir, cmd_args)
    final_config = template_wasm_config

    if cmd_args.log_level == 'none' or cmd_args.log_level == 'per-file':
        # Flatten the list of k_steps, just run them all in one go.
        k_steps = [('full', [y for (_, x) in k_steps for y in x])]

    (symbolic_config, init_subst) = split_config_from(template_wasm_config)

    for i in range(len(k_steps)):
        step_name, curr_step = k_steps[i]
        if cmd_args.verbose:
            print('Executing step %s' % step_name)
        init_subst['K_CELL'] = KSequence(curr_step)

        init_config = Subst(init_subst)(symbolic_config)

        # Run: generate a new JSON as a temporary file, then read that as the new wasm state.
        if cmd_args.log_level != 'none':
            log_intermediate_state(krun, '%s_%d_%s.pre' % (test_name, i, step_name), init_config, output_dir)

        new_config = krun_config(krun, conf=init_config)
        final_config = new_config

        if cmd_args.log_level != 'none':
            log_intermediate_state(krun, '%s_%d_%s' % (test_name, i, step_name), final_config, output_dir)

        # Check if the k cell is empty
        symbolic_config, init_subst = split_config_from(new_config)
        k_cell = init_subst['K_CELL']

        assert isinstance(k_cell, KSequence)

        if k_cell.arity != 0:
            raise ValueError(f'k cell not empty, contains a sequence of {k_cell.arity} items.\nSee {output_dir}')

    return final_config


# ... Setup Elrond Wasm


def log_intermediate_state(krun: KRun, name: str, config: KInner, output_dir: str) -> None:
    with open('%s/%s' % (output_dir, name), 'w') as f:
        f.write(kast_to_json_str(config))
    with open('%s/%s.pretty.k' % (output_dir, name), 'w') as f:
        pretty = krun.pretty_print(config)
        f.write(pretty)


def run_tests() -> None:
    test_args = argparse.ArgumentParser(description='')
    test_args.add_argument('files', metavar='N', type=str, nargs='+', help='')
    test_args.add_argument('--log-level', choices=['none', 'per-file', 'per-step'], default='per-file')
    test_args.add_argument('--verbose', action='store_true', help='')
    test_args.add_argument(
        '--definition-dir',
        dest='definition_dir',
        type=dir_path,
        help='Path to Mandos LLVM definition to use.',
    )
    args = test_args.parse_args()

    definition_dir = args.definition_dir
    if definition_dir is None:
        definition_dir = kdist.get('mx-semantics.llvm-mandos')
    krun = KRun(definition_dir)

    tests = args.files

    template_wasm_config = read_mandos_runtime()

    for test in tests:
        if args.verbose:
            print('Running test %s' % test)
        tmpdir = tempfile.mkdtemp(prefix='mandos_')
        if args.verbose:
            print('Intermediate test outputs stored in:\n%s' % tmpdir)

        initial_name = '0000_initial_config'
        with open('%s/%s' % (tmpdir, initial_name), 'w') as f:
            f.write(kast_to_json_str(template_wasm_config))

        run_test_file(krun, template_wasm_config, test, tmpdir, args)

        if args.verbose:
            print('See %s' % tmpdir)
            print()
