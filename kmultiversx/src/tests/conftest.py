from pathlib import Path

import pytest
from pyk.cli.utils import dir_path
from pyk.ktool.krun import KRun


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        '--foundry-llvm-dir',
        dest='foundry_llvm_dir',
        type=dir_path,
        help='Existing Foundry LLVM kompiled directory.',
    )


@pytest.fixture(scope='session')
def foundry_llvm_dir(pytestconfig: pytest.Config) -> Path:
    ldir = pytestconfig.getoption('foundry_llvm_dir')
    assert isinstance(ldir, Path)
    return ldir


@pytest.fixture(scope='session')
def foundry_llvm_krun(foundry_llvm_dir: Path) -> KRun:
    return KRun(foundry_llvm_dir)
