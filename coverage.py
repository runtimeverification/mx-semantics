import unittest
from pyk.kast.manip import split_config_from, bottom_up
from pyk.kast.inner import KApply, KLabel, KToken, KSort
import subprocess



#### SHOULD BE UPSTREAMED ####

def fromKString(ks):
    assert isinstance(ks, KToken) and ks.sort == KSort('String'), ks
    s = ks.token
    assert s[0] == s[-1] == '"'
    return s[1:-1]


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
        m2f = cov_data['idx2file']

        def lookup_filename(mod_idx):
            if (mod_idx in m2f) and (m2f[mod_idx] is not None):
                return m2f[mod_idx]
            else:
                return unnamed

        def aggregate_coverage(summarized_data, new_cov_data):
            for (mod_name, cov_idx) in new_cov_data:
                if mod_name not in summarized_data:
                    summarized_data[mod_name] = set()
                summarized_data[mod_name].add(cov_idx)

        new_func_cov = [ (lookup_filename(mod_idx), func_idx) for (mod_idx, func_idx) in cov_data['func_cov'] ]
        aggregate_coverage(self.func_covered, new_func_cov)

        new_block_cov = [ (lookup_filename(mod_idx), block_id) for (mod_idx, block_id) in cov_data['block_cov'] ]
        aggregate_coverage(self.block_covered, new_block_cov)

        self.module_files = self.module_files.union(set(filter(None, cov_data['idx2file'].values())))

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

def get_module_filename_map(wasm_config):
    def mod_to_idx_and_filename(mod):
        res = {}

        def callback(kast):
            if isinstance(kast, KApply):
                if kast.label == KLabel('<modIdx>'):
                    res['idx'] = fromKInt(kast.args[0])
                if kast.label == KLabel('<moduleFileName>'):
                    a = kast.args[0]
                    if isinstance(a, KApply):
                        res['name'] = None
                    else:
                        res['name'] = fromKString(a)
            return kast

        bottom_up(callback, mod)
        return (res['idx'], res['name'])

    mods = []

    def callback(kast):
        if isinstance(kast, KApply) and kast.label == KLabel('<moduleInst>'):
            mods.append(kast)
        return kast

    bottom_up(callback, wasm_config)
    return dict(map(mod_to_idx_and_filename, mods))

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
        coverage = { 'func_cov': func_cov, 'block_cov': block_cov, 'idx2file' : {0: 'foo', 1: 'bar'} }
        return coverage

    def test_coverage_empty(self):
        coverage = Coverage()
        cov1 = self.dummy_coverage([], [])
        coverage.add_coverage(cov1)
        self.assertEqual(coverage.func_covered, {})
        self.assertEqual(coverage.block_covered, {})
        self.assertEqual(coverage.module_files, {'foo', 'bar'})

    def test_coverage_aggregate(self):
        func_cov1 = [
            (0, 0), (0, 1), (0, 2),
            (1, 0), (1, 1)
        ]
        func_cov2 = [ (0, 0), (1, 2) ]
        block_cov1 = [ (0, 0), (0, 1), (1, 0) ]
        block_cov2 = [ (1, 1) ]
        coverage = Coverage()
        coverage.add_coverage(self.dummy_coverage(func_cov1, block_cov1))
        coverage.add_coverage(self.dummy_coverage(func_cov2, block_cov2))
        self.assertEqual(coverage.func_covered, { 'foo': {0, 1, 2}, 'bar': {0, 1, 2} })
        self.assertEqual(coverage.block_covered, { 'foo': {0, 1}, 'bar': {0, 1} })

if __name__ == '__main__':
    unittest.main()
