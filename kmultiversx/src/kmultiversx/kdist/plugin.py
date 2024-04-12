from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

from pyk.kbuild.utils import k_version
from pyk.kdist.api import Target
from pyk.ktool.kompile import KompileBackend, kompile
from pykwasm.kdist.plugin import SOURCE_DIR as WASM_DIR

if TYPE_CHECKING:
    from collections.abc import Mapping
    from typing import Any, Final


CURRENT_DIR: Final = Path(__file__).parent
SOURCE_DIR: Final = CURRENT_DIR / 'mx-semantics'
PLUGIN_DIR: Final = CURRENT_DIR.parents[3] / 'deps/plugin'  # TODO Distribute plugin files with Python


class KompileTarget(Target):
    _kompile_args: dict[str, Any]

    def __init__(self, kompile_args: Mapping[str, Any]):
        self._kompile_args = dict(kompile_args)

    def build(self, output_dir: Path, deps: dict[str, Path], args: dict[str, Any], verbose: bool) -> None:
        # TODO Pass K_OPTS='-Xmx8G -Xss512m'
        kompile(
            output_dir=output_dir,
            verbose=verbose,
            **self._kompile_args,
        )

    def source(self) -> tuple[Path, ...]:
        return (SOURCE_DIR,)

    def context(self) -> dict[str, str]:
        return {'k-version': k_version().text}


def llvm_target(main_file: Path, main_module: str, syntax_module: str) -> KompileTarget:
    return KompileTarget(
        {
            'backend': KompileBackend.LLVM,
            'main_file': main_file,
            'main_module': main_module,
            'syntax_module': syntax_module,
            'include_dirs': [WASM_DIR, PLUGIN_DIR],
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


def haskell_target(main_file: Path, main_module: str, syntax_module: str) -> KompileTarget:
    return KompileTarget(
        {
            'backend': KompileBackend.HASKELL,
            'main_file': main_file,
            'main_module': main_module,
            'syntax_module': syntax_module,
            'include_dirs': [WASM_DIR, PLUGIN_DIR],
            'md_selector': 'k',
            'hook_namespaces': ['KRYPTO'],
            'warning_to_error': True,
        },
    )


__TARGETS__: Final = {
    'llvm-mandos': llvm_target(SOURCE_DIR / 'mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'llvm-kasmer': llvm_target(SOURCE_DIR / 'kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
    'haskell-mandos': haskell_target(SOURCE_DIR / 'mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'haskell-kasmer': haskell_target(SOURCE_DIR / 'kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
}
