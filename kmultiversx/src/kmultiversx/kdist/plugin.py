from __future__ import annotations

import shutil
from distutils.dir_util import copy_tree
from pathlib import Path
from typing import TYPE_CHECKING

from pyk.kbuild.utils import k_version
from pyk.kdist.api import Target
from pyk.ktool.kompile import PykBackend, kompile
from pyk.utils import run_process_2

if TYPE_CHECKING:
    from collections.abc import Callable, Mapping
    from typing import Any, Final


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


class PluginTarget(Target):
    PLUGIN_DIR: Final = Path(__file__).parent / 'plugin'

    def build(self, output_dir: Path, deps: dict[str, Any], args: dict[str, Any], verbose: bool) -> None:
        copy_tree(str(self.PLUGIN_DIR), '.')
        run_process_2(['make', '-j8'])
        shutil.copy('./build/krypto/lib/krypto.a', str(output_dir))

    def source(self) -> tuple[Path]:
        return (self.PLUGIN_DIR,)


class KompileTarget(Target):
    _kompile_args: Callable[[Path, Path], Mapping[str, Any]]

    def __init__(self, kompile_args: Callable[[Path, Path], Mapping[str, Any]]):
        self._kompile_args = kompile_args

    def build(self, output_dir: Path, deps: dict[str, Path], args: dict[str, Any], verbose: bool) -> None:
        # TODO Pass K_OPTS='-Xmx8G -Xss512m'
        kompile_args = self._kompile_args(deps['mx-semantics.source'], deps['mx-semantics.plugin'])
        kompile(output_dir=output_dir, verbose=verbose, **kompile_args)

    def context(self) -> dict[str, str]:
        return {'k-version': k_version().text}

    def deps(self) -> tuple[str, str]:
        return ('mx-semantics.source', 'mx-semantics.plugin')


def llvm_target(main_file_name: str, main_module: str, syntax_module: str) -> KompileTarget:
    def ccopts(plugin_dir: Path) -> list[str]:
        return [
                '-g',
                '-std=c++17',
                '-lcrypto',
                '-lsecp256k1',
                '-lssl',
                str(plugin_dir / 'krypto.a'),
            ]


    return KompileTarget(
        lambda src_dir, plugin_dir: {
            'backend': PykBackend.LLVM,
            'main_file': src_dir / 'mx-semantics' / main_file_name,
            'main_module': main_module,
            'syntax_module': syntax_module,
            'include_dirs': [src_dir],
            'md_selector': 'k',
            'hook_namespaces': ['KRYPTO'],
            'opt_level': 2,
            'ccopts': ccopts(plugin_dir)
        },
    )


def haskell_target(main_file_name: str, main_module: str, syntax_module: str) -> KompileTarget:
    return KompileTarget(
        lambda src_dir, plugin_dir: {
            'backend': PykBackend.HASKELL,
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
    'plugin': PluginTarget(),
    'llvm-mandos': llvm_target('mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'llvm-kasmer': llvm_target('kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
    'haskell-mandos': haskell_target('mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'haskell-kasmer': haskell_target('kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
}
