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


def krun_config(krun: KRun, conf: KInner) -> KInner:
    conf_kore = krun.kast_to_kore(conf, sort=GENERATED_TOP_CELL)
    res_conf_kore = krun.run_kore_term(conf_kore, pipe_stderr=False)
    return krun.kore_to_kast(res_conf_kore)
