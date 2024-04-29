from __future__ import annotations

import shutil
from distutils.dir_util import copy_tree
from pathlib import Path
from typing import TYPE_CHECKING

from pyk.kbuild.utils import k_version, sync_files
from pyk.kdist.api import Target
from pyk.ktool.kompile import KompileBackend, kompile
from pyk.utils import run_process

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
        sync_files(
            source_dir=self.PLUGIN_DIR / 'plugin-c',
            target_dir=output_dir / 'plugin-c',
            file_names=[
                'blake2.h',
                'crypto.cpp',
                'plugin_util.cpp',
                'plugin_util.h',
            ],
        )

        copy_tree(str(self.PLUGIN_DIR), '.')
        run_process(
            ['make', 'libcryptopp', 'libff', 'blake2', '-j8'],
            pipe_stdout=not verbose,
        )

        copy_tree('./build/libcryptopp', str(output_dir / 'libcryptopp'))
        copy_tree('./build/libff', str(output_dir / 'libff'))
        copy_tree('./build/blake2', str(output_dir / 'blake2'))

    def source(self) -> tuple[Path]:
        return (self.PLUGIN_DIR,)


class KompileTarget(Target):
    _kompile_args: Callable[[Path], Mapping[str, Any]]

    def __init__(self, kompile_args: Callable[[Path], Mapping[str, Any]]):
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
    return KompileTarget(
        lambda src_dir, plugin_dir: {
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
                str(plugin_dir / 'blake2/lib/blake2.a'),
                f"-I{plugin_dir / 'blake2/include'}",
                str(plugin_dir / 'libcryptopp/lib/libcryptopp.a'),
                f"-I{plugin_dir / 'libcryptopp/include'}",
                str(plugin_dir / 'libff/lib/libff.a'),
                f"-I{plugin_dir / 'libff/include'}",
                str(plugin_dir / 'plugin-c/crypto.cpp'),
                str(plugin_dir / 'plugin-c/plugin_util.cpp'),
            ],
        },
    )


def haskell_target(main_file_name: str, main_module: str, syntax_module: str) -> KompileTarget:
    return KompileTarget(
        lambda src_dir, plugin_dir: {
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
    'plugin': PluginTarget(),
    'llvm-mandos': llvm_target('mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'llvm-kasmer': llvm_target('kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
    'haskell-mandos': haskell_target('mandos.md', 'MANDOS', 'MANDOS-SYNTAX'),
    'haskell-kasmer': haskell_target('kasmer.md', 'KASMER', 'KASMER-SYNTAX'),
}
