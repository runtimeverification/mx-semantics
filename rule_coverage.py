from glob import glob
from os.path import abspath, relpath
from sys import argv

def starts_with_one_of(s, ps):
    for p in ps:
        if s.startswith(p):
            return True
    return False

def main(kompiled_dir: str, src_files: list[str]):
    src_files = [abspath(f) for f in src_files]

    all_rules_path = kompiled_dir + '/allRules.txt'

    # rule id -> source location
    all_rules = dict()
    
    with open(all_rules_path, 'r') as f:
        for line in f.readlines():
            parts = line.split()
            rule_id = parts[0].strip()
            rule_loc = parts[1].strip()
            
            if starts_with_one_of(rule_loc, src_files):
                all_rules[rule_id] = rule_loc

    covered = set()
    
    for filename in glob(kompiled_dir + "/*coverage.txt"):
        with open(filename) as f:
            for line in f:
                rule_id = line.strip()
                if rule_id in all_rules:
                    covered.add(all_rules[rule_id])

    not_covered = set(all_rules.values()).difference(covered) 
    for loc in sorted(not_covered):
        print(relpath(loc))

if len(argv) >= 3:
    main(argv[1], argv[2:])
else:
    print(f'usage: python3 {argv[0]} <kompiled-dir> <source-file>...')