from __future__ import annotations

from typing import TYPE_CHECKING

from pyk.kast.manip import split_config_from

from kmultiversx.foundry import generate_claim
from kmultiversx.utils import GENERATED_TOP_CELL

if TYPE_CHECKING:
    from pyk.ktool.krun import KRun


def test_generate_cterms_init_config(foundry_llvm_krun: KRun) -> None:
    # Given
    conf = foundry_llvm_krun.definition.init_config(GENERATED_TOP_CELL)
    sym_conf, subst = split_config_from(conf)

    # When
    _, lhs, rhs = generate_claim('foo', ('BigUint', 'u32'), sym_conf, subst)

    # Then
    foundry_llvm_krun.kast_to_kore(lhs.kast, GENERATED_TOP_CELL)
    foundry_llvm_krun.kast_to_kore(rhs.kast, GENERATED_TOP_CELL)
