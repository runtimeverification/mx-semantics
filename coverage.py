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
