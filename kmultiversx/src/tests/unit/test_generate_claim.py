from __future__ import annotations

from typing import TYPE_CHECKING

from pyk.kast.manip import split_config_from

from kmultiversx.kasmer import generate_claim
from kmultiversx.utils import GENERATED_TOP_CELL

if TYPE_CHECKING:
    from pyk.ktool.krun import KRun


def test_generate_cterms_init_config(kasmer_llvm_krun: KRun) -> None:
    # Given
    conf = kasmer_llvm_krun.definition.init_config(GENERATED_TOP_CELL)

    # Check that the definition can be parsed
    assert kasmer_llvm_krun.kompiled_kore.definition

    sym_conf, subst = split_config_from(conf)

    # When
    _, lhs, rhs = generate_claim('foo', ('BigUint', 'u32'), sym_conf, subst)

    # Then
    kasmer_llvm_krun.kast_to_kore(lhs.kast, GENERATED_TOP_CELL)
    kasmer_llvm_krun.kast_to_kore(rhs.kast, GENERATED_TOP_CELL)
