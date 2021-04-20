import unittest
import pyk
import subprocess

from pyk.kast import isKApply, isKConstant, isKToken
from pyk.kastManip import traverseBottomUp


#### SHOULD BE UPSTREAMED ####

def fromKString(ks):
    assert isKToken(ks) and ks['sort'] == 'String', ks
    s = ks['token']
    assert s[0] == s[-1] == '"'
    return s[1:-1]


def fromKInt(ki):
    assert isKToken(ki) and ki['sort'] == 'Int', ki
    i = ki['token']
    return int(i)


# Coverage

POSITIVE_COVERAGE_CELL = "COVEREDFUNCS_CELL"
NEGATIVE_COVERAGE_CELL = "NOTCOVEREDFUNCS_CELL"
BLOCK_COVERAGE_CELL    = "COVEREDBLOCK_CELL"


def summarize_coverage(coverage_data, unnamed=None):
    """Takes the list of covered functions over several runs, and those not
    covered for each run. Returns coverage data for the test suite: all
    functions that were covered at least once, and all that were never
    covered.
    """
    all_covered = set()
    all_sometime_not_covered = set()
    all_block_covered = set()
    all_module_files = set()
    for test in coverage_data:
        m2f = test['idx2file']
        def lookup_filename(midx):
            return m2f[midx] if m2f[midx] is not None else unnamed

        covered  =    [ (lookup_filename(midx), fidx) for (midx, fidx) in test['cov'] ]
        not_covered = [ (lookup_filename(midx), fidx) for (midx, fidx) in test['not_cov'] ]
        block_covered = [ (lookup_filename(midx), blockid) for (midx, blockid) in test['block_cov'] ]
        all_covered = all_covered.union(set(covered))
        all_sometime_not_covered = all_sometime_not_covered.union(set(not_covered))
        all_block_covered = all_block_covered.union(set(block_covered))
        all_module_files = all_module_files.union(set(filter(None, test['idx2file'].values())))

    all_not_covered = all_sometime_not_covered.difference(all_covered)

    def set2dict(s):
        res = {}
        for (k, v) in s:
            if k not in res:
                res[k] = []
            res[k].append(v)
        for (k, v) in res.items():
            v.sort()
        return res

    return (set2dict(all_covered), set2dict(all_not_covered), set2dict(all_block_covered), all_module_files)


def get_module_filename_map(wasm_config):
    def mod_to_idx_and_filename(mod):
        res = {}

        def callback(kast):
            if isKApply(kast) and kast['label'] == '<modIdx>':
                res['idx'] = fromKInt(kast['args'][0])
            if isKApply(kast) and kast['label'] == '<moduleFileName>':
                a = kast['args'][0]
                if isKApply(a):
                    res['name'] = None
                else:
                    res['name'] = fromKString(a)
            return kast

        traverseBottomUp(mod, callback)
        return (res['idx'], res['name'])

    mods = []

    def callback(kast):
        if isKApply(kast) and kast['label'] == '<moduleInst>':
            mods.append(kast)
        return kast

    traverseBottomUp(wasm_config, callback)
    return dict(map(mod_to_idx_and_filename, mods))

# TODO: Use traverseBottomUp.
def filter_term(filter_func, term):
    res = []
    if filter_func(term):
        res.append(term)
    if 'args' in term:
        for arg in term['args']:
            for child in filter_term(filter_func, arg):
                res.append(child)
    return res

def get_function_coverage(term):
    cells = pyk.splitConfigFrom(term)[1]
    pos = cells[POSITIVE_COVERAGE_CELL]
    neg = cells[NEGATIVE_COVERAGE_CELL]
    filter_func = lambda term: 'label' in term and term['label'] == 'fcd'
    pos_fcds = filter_term(filter_func, pos)
    neg_fcds = filter_term(filter_func, neg)
    def fcd_data(fcd):
        mod  = int(fcd['args'][0]['token'])
        addr = int(fcd['args'][1]['token'])
        return (mod, addr)
    pos_ids = [ fcd_data(fcd) for fcd in pos_fcds ]
    neg_ids = [ fcd_data(fcd) for fcd in neg_fcds ]
    return (pos_ids, neg_ids)

def get_block_coverage(term):
    cells = pyk.splitConfigFrom(term)[1]
    block_cov_cell = cells[BLOCK_COVERAGE_CELL]
    filter_func = lambda term: 'label' in term and term['label'] == 'blockUid'
    coverage_info = filter_term(filter_func, block_cov_cell)
    block_uids = [ (int(block_cov['args'][0]['token']), int(block_cov['args'][1]['token'])) for block_cov in coverage_info ]
    return block_uids

def insert_coverage_on_text_module(uncovered_func, covered_block, all_module_files, imports_mod_name=None):
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

    res = []
    uncovered_imps = uncovered_func[imports_mod_name] if imports_mod_name in uncovered_func else []
    for name in all_module_files:
        try:
            wat = subprocess.check_output("wasm2wat %s" % (name), shell=True)
            lines = wat.splitlines()
            if name in uncovered_func:
                uncovered_func_indices = uncovered_func[name]
                line_idcs = imports(lines) + funcs(lines)
                for idx in uncovered_func_indices + uncovered_imps:
                    uncovered_func_line_idx = line_idcs[idx]
                    lines[uncovered_func_line_idx] = b'!' + lines[uncovered_func_line_idx][1:]

            block_idcs = blocks(lines)
            if name in covered_block:
                covered_block_indices = covered_block[name]
                for block_id in range(len(block_idcs)):
                    if block_id not in covered_block_indices:
                        uncovered_block_line_idx = block_idcs[block_id]
                        lines[uncovered_block_line_idx] = b'!' + lines[uncovered_block_line_idx][1:]
            else:
                for block_id in range(len(block_idcs)):
                    uncovered_block_line_idx = block_idcs[block_id]
                    lines[uncovered_block_line_idx] = b'!' + lines[uncovered_block_line_idx][1:]

            res.append(b'\n'.join(lines))

        except subprocess.CalledProcessError as e:
            print(e)
            pass
        return res


class TestCoverage(unittest.TestCase):

    def dummy_coverage(_self, covered, not_covered, block_covered):
        coverage = { 'cov' : covered , 'not_cov': not_covered, 'block_cov': block_covered, 'idx2file' : {0: 'foo', 1: 'bar'} }
        return coverage

    def test_cover_empty(self):
        cov1 = self.dummy_coverage([], [], [])
        (c, nc, bc, all_files) = summarize_coverage([cov1])
        self.assertEqual(c, {})
        self.assertEqual(nc, {})
        self.assertEqual(bc, {})
        self.assertEqual(all_files, {'foo', 'bar'})

    def test_cover_all(self):
        """All functions were covered in different tests."""
        covs = []
        cov1  = [
            (0, 0), (0, 1), (0, 2),
            (1, 0), (1, 1), (1, 2)
        ]
        ncov1  = covs.copy()
        ncov1.reverse()
        block_cov1 = [ (0, 0), (0, 1), (1, 0) ]
        block_cov2 = [ (1, 1) ]
        covs.append(self.dummy_coverage(cov1, ncov1, block_cov1))
        covs.append(self.dummy_coverage(cov1, ncov1, block_cov2))
        (c, nc, bc, _) = summarize_coverage(covs)
        self.assertEqual(nc, {})
        self.assertEqual(bc, { 'foo': [0, 1], 'bar': [0, 1] })

    def test_cover_some(self):
        covs  = [
            (0, 0), (0, 1), (0, 2),
            (1, 0), (1, 1), (1, 2)
        ]
        ncovs  = covs.copy()
        ncovs.reverse()
        extra_mod_idx = 0
        extra_fun_idx = 3
        extra = (extra_mod_idx, extra_fun_idx)
        ncovs.append(extra)
        cov = self.dummy_coverage(covs, ncovs, [])
        extra_mod_file = cov['idx2file'][extra_mod_idx]
        (c, nc, _, _) = summarize_coverage([cov])
        self.assertEqual(nc[extra_mod_file], [extra_fun_idx])


if __name__ == '__main__':
    unittest.main()
