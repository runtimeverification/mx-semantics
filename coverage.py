import unittest


def summarize_coverage(covered, not_covered):
    """Takes the list of covered functions over several runs, and those not
    covered for each run. Returns coverage data for the test suite: all
    functions that were covered at least once, and all that were never
    covered."""
    def merge(list_of_lists):
        return [(int(mod), int(idx), id) for l in list_of_lists for (mod, idx, id) in l]
    all_covered = set(merge(covered))
    all_sometime_not_covered = set(merge(not_covered))
    all_not_coverd = all_sometime_not_covered.difference(all_covered)
    return (all_covered, all_not_coverd)


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
