import unittest
from pyk.kast.manip import split_config_from
from pyk.kast.inner import KApply, KToken, KSort
from pyk.prelude.string import stringToken, pretty_string
import subprocess



#### SHOULD BE UPSTREAMED ####
def fromKInt(ki):
    assert isinstance(ki, KToken) and ki.sort == KSort('Int'), ki
    i = ki.token
    return int(i)


class Coverage:

    def __init__(self):
        self.func_covered = {}
        self.block_covered = {}
        self.module_files = set()

    def get_module_files(self):
        return sorted(list(self.module_files))

    def add_coverage(self, cov_data, unnamed=None):
        
        mod_paths = set()

        def lookup_filename(mod_path):
            if not mod_path or mod_path == KApply('.String', []):
                return unnamed
            else:
                pretty_path = pretty_string(mod_path)
                mod_paths.add(pretty_path)
                return pretty_path

        def aggregate_coverage(summarized_data, new_cov_data):
            for (mod_path, cov_idx) in new_cov_data:
                if mod_path not in summarized_data:
                    summarized_data[mod_path] = set()
                summarized_data[mod_path].add(cov_idx)

        new_func_cov = [ (lookup_filename(mod_path), func_idx) for (mod_path, func_idx) in cov_data['func_cov'] ]
        aggregate_coverage(self.func_covered, new_func_cov)

        new_block_cov = [ (lookup_filename(mod_path), block_id) for (mod_path, block_id) in cov_data['block_cov'] ]
        aggregate_coverage(self.block_covered, new_block_cov)

        self.module_files = self.module_files.union(mod_paths)

    def is_func_covered(self, mod_name, func_idx):
        if mod_name in self.func_covered:
            return func_idx in self.func_covered[mod_name]
        else:
            return False

    def is_block_covered(self, mod_name, block_idx):
        if mod_name in self.block_covered:
            return block_idx in self.block_covered[mod_name]
        else:
            return False

def get_coverage_data(term, cell_name, filter_func, collect_data_func):

    # TODO: Use traverseBottomUp.
    def filter_term(filter_func, term):
        res = []
        if filter_func(term):
            res.append(term)
        if isinstance(term, KApply):
            for arg in term.args:
                res.extend(filter_term(filter_func, arg))
        return res

    cells = split_config_from(term)[1]
    cov_cell = cells[cell_name]
    cov_data = filter_term(filter_func, cov_cell)
    result = [ collect_data_func(entry) for entry in cov_data ]
    return result

def insert_coverage_on_text_module(coverage, imports_mod_name=None):
    def check_line_startswith(prefix):
        def check_startswith(line):
            stripped_line = line.lstrip()
            if isinstance(prefix, bytes):
                return stripped_line.startswith(prefix)
            if isinstance(prefix, list):
                for pre in prefix:
                    if stripped_line.startswith(pre):
                        return True
                return False
        return check_startswith

    def get_line_indices(lines, criteria_func):
        return [i for i in range(len(lines)) if criteria_func(lines[i])]

    def imports(lines):
        return get_line_indices(lines, check_line_startswith(b'(import "env"'))

    def funcs(lines):
        return get_line_indices(lines, check_line_startswith(b'(func'))

    def blocks(lines):
        return get_line_indices(lines, check_line_startswith([b'block', b'if', b'loop']))

    def mark_uncovered_line(lines, uncovered_line_num):
        lines[uncovered_line_num] = b'!' + lines[uncovered_line_num][1:]

    res = []
    for name in coverage.get_module_files():
        try:
            wat = subprocess.check_output("wasm2wat %s" % (name), shell=True)
            lines = wat.splitlines()

            # mark imports
            import_lines = imports(lines)
            import_size = len(import_lines)
            for import_idx in range(import_size):
                if not coverage.is_func_covered(imports_mod_name, import_idx):
                    uncovered_line_num = import_lines[import_idx]
                    mark_uncovered_line(lines, uncovered_line_num)

            # mark funcs
            func_lines = funcs(lines)
            func_size = len(func_lines)
            for idx in range(func_size):
                if not coverage.is_func_covered(name, import_size + idx):
                    uncovered_line_num = func_lines[idx]
                    mark_uncovered_line(lines, uncovered_line_num)

            # mark blocks
            block_lines = blocks(lines)
            block_size = len(block_lines)
            for block_idx in range(block_size):
                if not coverage.is_block_covered(name, block_idx):
                    uncovered_line_num = block_lines[block_idx]
                    mark_uncovered_line(lines, uncovered_line_num)

            res.append(b'\n'.join(lines))

        except subprocess.CalledProcessError as e:
            print(e)
            pass
        return res


class TestCoverage(unittest.TestCase):

    def dummy_coverage(_self, func_cov, block_cov):
        coverage = { 'func_cov': func_cov, 'block_cov': block_cov }
        return coverage

    def test_coverage_empty(self):
        coverage = Coverage()
        cov1 = self.dummy_coverage([], [])
        coverage.add_coverage(cov1)
        self.assertEqual(coverage.func_covered, {})
        self.assertEqual(coverage.block_covered, {})
        self.assertEqual(coverage.module_files, set())

    def test_coverage_aggregate(self):
        mod1 = stringToken("file1.wasm")
        mod2 = stringToken("file2.wasm")
        func_cov1 = [
            (mod1, 0), (mod1, 1), (mod1, 2),
            (mod2, 0), (mod2, 1)
        ]
        func_cov2 = [ (mod1, 0), (mod2, 2) ]
        block_cov1 = [ (mod1, 0), (mod1, 1), (mod2, 0) ]
        block_cov2 = [ (mod2, 1) ]
        coverage = Coverage()
        coverage.add_coverage(self.dummy_coverage(func_cov1, block_cov1))
        coverage.add_coverage(self.dummy_coverage(func_cov2, block_cov2))
        self.assertEqual(coverage.func_covered, { 'file1.wasm': {0, 1, 2}, 'file2.wasm': {0, 1, 2} })
        self.assertEqual(coverage.block_covered, { 'file1.wasm': {0, 1}, 'file2.wasm': {0, 1} })

if __name__ == '__main__':
    unittest.main()
