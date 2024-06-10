from __future__ import annotations

import json
from io import BytesIO
from pathlib import Path
from subprocess import CalledProcessError
from typing import TYPE_CHECKING, TypeVar

from pyk.kast.inner import KInner, KSort
from pyk.utils import run_process
from pykwasm import wasm2kast

if TYPE_CHECKING:
    from pyk.kast.kast import KAst
    from pyk.ktool.krun import KRun

    T = TypeVar('T')


GENERATED_TOP_CELL = KSort('GeneratedTopCell')

RUNTIME_MANDOS_JSON_PATH = Path(__file__).parent / 'kdist' / 'runtime' / 'llvm-mandos.json'
RUNTIME_KASMER_JSON_PATH = Path(__file__).parent / 'kdist' / 'runtime' / 'llvm-kasmer.json'


def read_mandos_runtime() -> KInner:
    return read_kinner_json(RUNTIME_MANDOS_JSON_PATH)


def read_kasmer_runtime() -> KInner:
    return read_kinner_json(RUNTIME_KASMER_JSON_PATH)


def read_kinner_json(path: Path) -> KInner:
    with open(str(path), 'r') as f:
        config_json = json.load(f)
        return KInner.from_dict(config_json['term'])


def kast_to_json(config: KAst) -> dict:
    return {'format': 'KAST', 'version': config.version(), 'term': config.to_dict()}


def kast_to_json_str(config: KAst) -> str:
    return json.dumps(kast_to_json(config), sort_keys=True)


def flatten(l: list[list[T]]) -> list[T]:
    return [item for sublist in l for item in sublist]


def load_wasm(filename: str) -> KInner:
    with open(filename, 'rb') as f:
        return wasm2kast.wasm2kast(f, filename)


def load_wasm_from_mxsc(filename: str) -> KInner:
    with open(filename, 'r') as f:
        contract_json = json.load(f)
        code_hex = contract_json['code']
        code_bytes = bytes.fromhex(code_hex)
        return wasm2kast.wasm2kast(BytesIO(code_bytes), filename)


def krun_config(krun: KRun, conf: KInner, pipe_stderr: bool = False) -> KInner:
    conf_kore = krun.kast_to_kore(conf, sort=GENERATED_TOP_CELL)
    res_conf_kore = krun.run_pattern(conf_kore, pipe_stderr=pipe_stderr)
    return krun.kore_to_kast(res_conf_kore)


def llvm_interpret_raw(definition_dir: Path, kore_input: str, pipe_stderr: bool = False) -> str:
    interpreter = definition_dir / 'interpreter'
    args = [str(interpreter), '/dev/stdin', str(-1), '/dev/stdout']

    try:
        res = run_process(args, input=kore_input, pipe_stderr=pipe_stderr)
    except CalledProcessError as err:
        raise RuntimeError(f'Interpreter failed with status {err.returncode}: {err.stderr}') from err

    return res.stdout


class KasmerRunError(Exception):  # noqa: B903
    def __init__(self, k_cell: KInner, vm_output: KInner, logging: KInner, final_conf: KInner, message: str):
        self.k_cell = k_cell
        self.vm_output = vm_output
        self.logging = logging
        self.final_conf = final_conf
        self.message = message
