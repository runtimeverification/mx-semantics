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


def summarize_coverage(coverage_data, unnamed=None):
    """Takes the list of covered functions over several runs, and those not
    covered for each run. Returns coverage data for the test suite: all
    functions that were covered at least once, and all that were never
    covered.
    """
    all_covered = set()
    all_sometime_not_covered = set()
    for test in coverage_data:
        m2f = test['idx2file']
        def lookup_filename(midx):
            return m2f[midx] if m2f[midx] is not None else unnamed

        covered  =    [ (lookup_filename(midx), fidx) for (midx, fidx) in test['cov']]
        not_covered = [ (lookup_filename(midx), fidx) for (midx, fidx) in test['not_cov']]
        all_covered = all_covered.union(set(covered))
        all_sometime_not_covered = all_sometime_not_covered.union(set(not_covered))

    all_not_coverd = all_sometime_not_covered.difference(all_covered)

    def set2dict(s):
        res = {}
        for (k, v) in s:
            if k not in res:
                res[k] = []
            res[k].append(v)
        for (k, v) in res.items():
            v.sort()
        return res

    return (set2dict(all_covered), set2dict(all_not_coverd))


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


def get_coverage(term):
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


def insert_coverage_on_text_module(cover, imports_mod_name=None):
    def get_line_indices(lines, start):
        return [i for i in range(len(lines)) if lines[i].startswith(start)]
    def imports(lines):
        return get_line_indices(lines, b'  (import "env"')
    def funcs(lines):
        return get_line_indices(lines, b'  (func')

    res = []
    imps = cover[imports_mod_name] if imports_mod_name in cover else []
    print(imps, imports_mod_name, cover)
    for (name, indices) in cover.items():
        try:
            wat = subprocess.check_output("wasm2wat %s" % (name), shell=True)
            lines = wat.splitlines()
            line_idcs = imports(lines) + funcs(lines)
            for idx in indices + imps:
                lidx = line_idcs[idx]
                lines[lidx] = bytes('✗', 'utf8') + lines[lidx][1:]
            res.append(b'\n'.join(lines))

        except subprocess.CalledProcessError as e:
            print(e)
            pass
        return res


class TestCoverage(unittest.TestCase):

    def test_cover_empty(self):
        [c, nc] = summarize_coverage([], [])
        self.assertEqual(c, nc)
        self.assertEqual(c, set())

    def test_cover_all(self):
        """All functions were covered in different tests."""
        covs  = [
            [(0, 0, ""), (0, 1, ""), (0, 2, "")],
            [(1, 0, ""), (1, 1, ""), (1, 2, "bar")]
        ]
        ncovs  = covs.copy()
        ncovs.reverse()
        [c, nc] = summarize_coverage(covs, ncovs)
        self.assertEqual(nc, set())

    def test_cover_some(self):
        covs  = [
            [(0, 0, ""), (0, 1, ""), (0, 2, "")],
            [(1, 0, ""), (1, 1, ""), (1, 2, "bar")]
        ]
        ncovs  = covs.copy()
        ncovs.reverse()
        extra = [(0, 3, "")]
        ncovs.append(extra)
        [c, nc] = summarize_coverage(covs, ncovs)
        self.assertEqual(nc, set(extra))


if __name__ == '__main__':
    unittest.main()
