from __future__ import annotations

import shutil
from pathlib import Path
from typing import TYPE_CHECKING

from pyk.kbuild.utils import k_version
from pyk.kdist.api import Target
from pyk.ktool.kompile import KompileBackend, kompile

if TYPE_CHECKING:
    from collections.abc import Callable, Mapping
    from typing import Any, Final


CURRENT_DIR: Final = Path(__file__).parent
PLUGIN_DIR: Final = CURRENT_DIR / 'plugin'


class SourceTarget(Target):
    SRC_DIR: Final = Path(__file__).parent

    def build(self, output_dir: Path, deps: dict[str, Path], args: dict[str, Any], verbose: bool) -> None:
        shutil.copytree(deps['wasm-semantics.source'] / 'wasm-semantics', output_dir / 'wasm-semantics')
        shutil.copytree(self.SRC_DIR / 'plugin/plugin', output_dir / 'plugin')
        shutil.copytree(self.SRC_DIR / 'mx-semantics', output_dir / 'mx-semantics')

    def source(self) -> tuple[Path, ...]:
        return (self.SRC_DIR,)

    def deps(self) -> tuple[str]:
        return ('wasm-semantics.source',)


class KompileTarget(Target):
    _kompile_args: Callable[[Path], Mapping[str, Any]]

    def __init__(self, kompile_args: Callable[[Path], Mapping[str, Any]]):
        self._kompile_args = kompile_args

    def build(self, output_dir: Path, deps: dict[str, Path], args: dict[str, Any], verbose: bool) -> None:
        # TODO Pass K_OPTS='-Xmx8G -Xss512m'
        kompile_args = self._kompile_args(deps['mx-semantics.source'])
        kompile(output_dir=output_dir, verbose=verbose, **kompile_args)

    def context(self) -> dict[str, str]:
        return {'k-version': k_version().text}

    def deps(self) -> tuple[str]:
        return ('mx-semantics.source',)


def llvm_target(main_file_name: str, main_module: str, syntax_module: str) -> KompileTarget:
    return KompileTarget(
        lambda src_dir: {
            'backend': KompileBackend.LLVM,
            'main_file': src_dir / 'mx-semantics' / main_file_name,
            'main_module': main_module,
            'syntax_module': syntax_module,
            'include_dirs': [src_dir],
            'md_selector': 'k',
            'hook_namespaces': ['KRYPTO'],
            'opt_level': 2,
            'ccopts': [
                '-g',
                '-std=c++17',
                '-lcrypto',
                '-lprocps',
                '-lsecp256k1',
                '-lssl',
                f"{PLUGIN_DIR / 'build/blake2/lib/blake2.a'}",
                f"-I{PLUGIN_DIR / 'build/blake2/include'}",
                f"{PLUGIN_DIR / 'build/libcryptopp/lib/libcryptopp.a'}",
                f"-I{PLUGIN_DIR / 'build/libcryptopp/include'}",
                f"{PLUGIN_DIR / 'build/libff/lib/libff.a'}",
                f"-I{PLUGIN_DIR / 'build/libff/include'}",
                f"{PLUGIN_DIR / 'plugin-c/crypto.cpp'}",
                f"{PLUGIN_DIR / 'plugin-c/plugin_util.cpp'}",
            ],
        },
    )


def haskell_target(main_file_name: str, main_module: str, syntax_module: str) -> KompileTarget:
    return KompileTarget(
        lambda src_dir: {
            'backend': KompileBackend.HASKELL,
            'main_file': src_dir / 'mx-semantics' / main_file_name,
            'main_module': main_module,
            'syntax_module': syntax_module,
            'include_dirs': [src_dir],
            'md_selector': 'k',
            'hook_namespaces': ['KRYPTO'],
            'warnings_to_errors': True,
        },
    )


__TARGETS__: Final = {
    'source': SourceTarget(),
    'llvm-mandos': llvm_target('mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'llvm-kasmer': llvm_target('kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
    'haskell-mandos': haskell_target('mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'haskell-kasmer': haskell_target('kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
}
