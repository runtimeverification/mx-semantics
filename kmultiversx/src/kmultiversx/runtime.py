from __future__ import annotations

import argparse
from typing import TYPE_CHECKING

from pyk.cli.utils import ensure_dir_path, file_path
from pyk.kast.inner import KApply, Subst
from pyk.kast.manip import split_config_from
from pyk.kdist import kdist
from pyk.ktool.krun import KRun
from pyk.prelude.utils import token

from kmultiversx import scenario
from kmultiversx.kasmer import run_config_and_check_empty
from kmultiversx.scenario import KMap
from kmultiversx.utils import (
    GENERATED_TOP_CELL,
    RUNTIME_KASMER_JSON_PATH,
    RUNTIME_MANDOS_JSON_PATH,
    kast_to_json_str,
    load_wasm,
)

if TYPE_CHECKING:
    from pyk.kast.inner import KInner

ESDT_ADDRESS = '0x000000000000000000010000000000000000000000000000000000000002ffff'


def main() -> None:
    test_args = argparse.ArgumentParser(description='')
    test_args.add_argument(
        'esdt_wasm_path',
        type=file_path,
        help='Path to ESDT system SC.',
    )
    args = test_args.parse_args()

    definition_dir = kdist.get('mx-semantics.llvm-mandos')
    definition_dir = kdist.get('mx-semantics.llvm-kasmer')

    targets = (
        (kdist.get('mx-semantics.llvm-mandos'), RUNTIME_MANDOS_JSON_PATH),
        (kdist.get('mx-semantics.llvm-kasmer'), RUNTIME_KASMER_JSON_PATH),
    )

    for definition_dir, output_path in targets:
        esdt_wasm = load_wasm(args.esdt_wasm_path)

        krun = KRun(definition_dir)
        config = load_runtime(krun, esdt_wasm)

        ensure_dir_path(output_path.parent)
        output_path.write_text(kast_to_json_str(config))


def load_runtime(krun: KRun, esdt_wasm: KInner) -> KInner:

    conf, subst = split_config_from(krun.definition.init_config(GENERATED_TOP_CELL))
    subst['K_CELL'] = KApply(
        'setAccount',
        [
            token(scenario.mandos_string_to_bytes(ESDT_ADDRESS)),
            token(0),
            token(0),
            esdt_wasm,
            token(b''),
            KMap([]),
        ],
    )
    conf_with_steps = Subst(subst)(conf)

    final_conf, _, _ = run_config_and_check_empty(krun, conf_with_steps)

    return final_conf
