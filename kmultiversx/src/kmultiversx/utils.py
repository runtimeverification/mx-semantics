from __future__ import annotations

import json
from typing import TYPE_CHECKING, TypeVar

from pyk.kast.inner import KSort
from pykwasm import wasm2kast

if TYPE_CHECKING:
    from pyk.kast.inner import KInner
    from pyk.kast.kast import KAst
    from pyk.ktool.krun import KRun

    T = TypeVar('T')


GENERATED_TOP_CELL = KSort('GeneratedTopCell')


def kast_to_json(config: KAst) -> dict:
    return {'format': 'KAST', 'version': config.version(), 'term': config.to_dict()}


def kast_to_json_str(config: KAst) -> str:
    return json.dumps(kast_to_json(config), sort_keys=True)


def flatten(l: list[list[T]]) -> list[T]:
    return [item for sublist in l for item in sublist]


def load_wasm(filename: str) -> KInner:
    with open(filename, 'rb') as f:
        return wasm2kast.wasm2kast(f, filename)


def krun_config(krun: KRun, conf: KInner, pipe_stderr: bool = False) -> KInner:
    conf_kore = krun.kast_to_kore(conf, sort=GENERATED_TOP_CELL)
    res_conf_kore = krun.run_pattern(conf_kore, pipe_stderr=pipe_stderr)
    return krun.kore_to_kast(res_conf_kore)


class KasmerRunError(Exception):  # noqa: B903
    def __init__(self, k_cell: KInner, vm_output: KInner, logging: KInner, final_conf: KInner, message: str):
        self.k_cell = k_cell
        self.vm_output = vm_output
        self.logging = logging
        self.final_conf = final_conf
        self.message = message
