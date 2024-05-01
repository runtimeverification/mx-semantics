from __future__ import annotations

import sys
from argparse import ArgumentParser
from contextlib import contextmanager
from enum import Enum
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import TYPE_CHECKING

from pyk.cli.utils import file_path
from pyk.kdist import kdist
from pyk.ktool.kprint import KAstOutput, _kast
from pyk.ktool.krun import _krun
from pykwasm.scripts.preprocessor import preprocess

if TYPE_CHECKING:
    from collections.abc import Iterator
    from subprocess import CompletedProcess


class Backend(Enum):
    LLVM = 'llvm'
    HASKELL = 'haskell'


class MainFile(Enum):
    MANDOS = 'mandos'
    KASMER = 'kasmer'


def main() -> None:
    parser = _argument_parser()
    args, rest = parser.parse_known_args()

    if args.command == 'run':
        _exec_run(program=args.program, backend=args.backend, main_file=args.main_file)
    elif args.command == 'kast':
        _exec_kast(program=args.program, backend=args.backend, main_file=args.main_file, output=args.output)

    raise AssertionError()


def _exec_run(*, program: Path, backend: Backend, main_file: MainFile) -> None:
    definition_dir = kdist.get(f'mx-semantics.{backend.value}-{main_file.value}')

    with _preprocessed(program) as input_file:
        proc_res = _krun(definition_dir=definition_dir, input_file=input_file, check=False)

    _exit_with_output(proc_res)


def _exec_kast(*, program: Path, backend: Backend, main_file: MainFile, output: KAstOutput | None) -> None:
    definition_dir = kdist.get(f'mx-semantics.{backend.value}-{main_file.value}')

    with _preprocessed(program) as input_file:
        proc_res = _kast(input_file, definition_dir=definition_dir, output=output, check=False)

    _exit_with_output(proc_res)


@contextmanager
def _preprocessed(program: Path) -> Iterator[Path]:
    program_text = program.read_text()
    with NamedTemporaryFile() as f:
        tmp_file = Path(f.name)
        tmp_file.write_text(preprocess(program_text))
        yield tmp_file


def _exit_with_output(cp: CompletedProcess) -> None:
    status = cp.returncode
    out = cp.stdout if status else cp.stderr
    file = sys.stdout if status else sys.stderr
    print(out, end='', file=file, flush=True)
    sys.exit(status)


def _argument_parser() -> ArgumentParser:
    parser = ArgumentParser(prog='kelrond')
    command_parser = parser.add_subparsers(dest='command', required=True)

    run_parser = command_parser.add_parser('run', help='run a Mandos scenario')
    _add_common_arguments(run_parser)

    kast_parser = command_parser.add_parser('kast', help='parse a Mandos scenario and output it in a supported format')
    _add_common_arguments(kast_parser)
    kast_parser.add_argument('--output', metavar='FORMAT', type=KAstOutput, help='format to output the term in')

    return parser


def _add_common_arguments(parser: ArgumentParser) -> None:
    parser.add_argument('program', metavar='PROGRAM', type=file_path, help='path to Mandos scenario')
    parser.add_argument('--backend', metavar='BACKEND', type=Backend, default=Backend.LLVM, help='K backend to use')
    parser.add_argument(
        '--main-file',
        metavar='MAIN-FILE',
        type=MainFile,
        default=MainFile.MANDOS,
        help='the name of the file (without extension) containing the main module for parsing/running',
    )


if __name__ == '__main__':
    main()
