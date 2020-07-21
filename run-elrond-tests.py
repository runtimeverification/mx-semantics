#!/usr/bin/env python3

import argparse
import json
import pyk
import resource
import sys
import tempfile

from pyk.kast import KSequence, KConstant

WASM_definition_llvm_no_coverage_dir = '.build/defn/llvm'

sys.setrecursionlimit(1500000000)
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

testArgs = argparse.ArgumentParser(description='')
testArgs.add_argument('files', metavar='N', type=str, nargs='+', help='')
args = testArgs.parse_args()

tests = args.files

# ... Setup Elrond Wasm
wasm_state = {}

def step_dict_to_k(step):
    """TODO"""
    # A single `foo` instruction:
    # `___MANDOS_Steps_Step_Steps`(`foo_MANDOS_Step`(.KList),`.List{"___MANDOS_Steps_Step_Steps"}_Steps`(.KList))
    return KConstant("foo_MANDOS_Step")

def run_test_file(wasm_state, filename):
    with open(filename, 'r') as f:
        mandos_test = json.loads(f.read())
    if 'name' in mandos_test:
        print('Executing "%s"' % mandos_test['name'])
    if 'comment' in mandos_test:
        print('Comment:\n"%s"' % mandos_test['comment'])

    (symbolic_config, init_subst) = pyk.splitConfigFrom(wasm_state)
    invoking_steps = [ step_dict_to_k(step) for step in mandos_test['steps'] ]
    init_subst['K_CELL'] = KSequence(invoking_steps)

    init_config = pyk.substitute(symbolic_config, init_subst)

    input_json = { 'format' : 'KAST', 'version': 1, 'term': init_config }
    krun_args = [ '--term']

    # Run: generate a new JSON as a temporary file, then read that as the new wasm state.
    (rc, json_result, _) = pyk.krunJSON(WASM_definition_llvm_no_coverage_dir, input_json, krunArgs = krun_args)

    with open('my_output.tmp', 'w') as f:
        f.write(json.dumps(json_result))

    return json_result

wasm_state = pyk.readKastTerm('src/elrond-runtime.loaded.json')

for test in tests:
    wasm_state = run_test_file(wasm_state, test)
