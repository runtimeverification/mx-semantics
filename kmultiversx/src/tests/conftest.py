from __future__ import annotations

from typing import TYPE_CHECKING

import pytest
from pyk.cli.utils import dir_path
from pyk.kdist import kdist
from pyk.ktool.krun import KRun

if TYPE_CHECKING:
    from pathlib import Path


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        '--kasmer-llvm-dir',
        dest='kasmer_llvm_dir',
        type=dir_path,
        help='Existing Kasmer LLVM kompiled directory.',
    )


@pytest.fixture(scope='session')
def kasmer_llvm_dir(pytestconfig: pytest.Config) -> Path | None:
    return pytestconfig.getoption('kasmer_llvm_dir')


@pytest.fixture(scope='session')
def kasmer_llvm_krun(kasmer_llvm_dir: Path | None) -> KRun:
    if kasmer_llvm_dir is not None:
        return KRun(kasmer_llvm_dir)

    kasmer_llvm_dir = kdist.which('mx-semantics.llvm-kasmer')
    if not kasmer_llvm_dir.is_dir():
        raise ValueError(
            'Kasmer LLVM definition not found. Run make from the repository root, or pass --kasmer-llvm-dir'
        )

    return KRun(kasmer_llvm_dir)
