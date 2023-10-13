from pathlib import Path

import pytest
from pyk.cli.utils import dir_path
from pyk.ktool.krun import KRun


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        '--kasmer-llvm-dir',
        dest='kasmer_llvm_dir',
        type=dir_path,
        help='Existing Kasmer LLVM kompiled directory.',
    )


@pytest.fixture(scope='session')
def kasmer_llvm_dir(pytestconfig: pytest.Config) -> Path:
    ldir = pytestconfig.getoption('kasmer_llvm_dir')
    assert isinstance(ldir, Path)
    return ldir


@pytest.fixture(scope='session')
def kasmer_llvm_krun(kasmer_llvm_dir: Path) -> KRun:
    return KRun(kasmer_llvm_dir)
