set -euo pipefail
shopt -s extglob

notif() { echo "== $@" >&2 ; }
fatal() { echo "[FATAL] $@" ; exit 1 ; }

kdist_dir="$(kdist which)"
defn_dir="${KELROND_DEFN_DIR:-$kdist_dir}/mx-semantics"

export K_OPTS="${K_OPTS:--Xmx16G -Xss512m}"

# Utilities
# ---------

preprocess() {
    local this_script_dir tmp_dir tmp_input
    this_script_dir="$(dirname $0)"
    tmp_dir="$(mktemp -d)"
    tmp_input="$tmp_dir/$(basename $run_file))"
    touch "$tmp_input"
    kwasm-preprocess "$run_file" > "$tmp_input"
    run_file="$tmp_input"
}

# Runners
# -------

run_krun() {
    preprocess
    krun --definition "$kompiled_dir" "$run_file" "$@"
}

run_kast() {
    local output_mode

    preprocess
    output_mode="${1:-kast}" ; shift
    kast --definition "$kompiled_dir" "$run_file" --output "$output_mode" "$@"
}

# Main
# ----

usage() {
    echo "
    usage: $0 run    [--backend (llvm|haskell)] [--main-file <main_file>]   <pgm>  <K args>*
           $0 kast   [--backend (llvm|haskell)] [--main-file <main_file>]   <pgm>  <output format> <K args>*
           
           $0 [help|--help|version|--version]

       $0 run        : Run a single Mandos scenario
       $0 kast       : Parse a single Mandos scenario and output it in supported format

       Note: <pgm> is a path to a file containing a WebAssembly program.
             <K args> are any arguments you want to pass to K when executing/proving.
             <output format> is the format for Kast to output the term in.
             <main_file> is the name of the file (without extension) containing the main module for parsing/running.
"
}

usage_fatal() {
    usage
    fatal "$@"
}

[[ ! -z ${1:-} ]] || usage_fatal "Must supply a command to run."

run_command="$1"; shift

[[ ! -z ${1:-} ]] || usage_fatal "Must supply a file to work on."

backend="llvm"     # default backend is llvm
main_file="mandos" # default main file is mandos.md

# read the arguments

args=()
while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --backend)    backend="$2"    ; shift 2 ;;
        --main-file)  main_file="$2"  ; shift 2 ;;
        *)            args+=("$1")    ; shift   ;;
    esac
done
set -- "${args[@]}"

kompiled_dir="$defn_dir/$backend-$main_file"

# get the run file
[[ ! -z ${1:-} ]] || usage_fatal "Must supply a file to run on."
run_file="$1" ; shift

# if run_file == '-', read from stdin and write to a temp file
if [[ "$run_file" == '-' ]]; then
    tmp_input="$(mktemp)"
    trap "rm -rf $tmp_input" INT TERM EXIT
    cat - > "$tmp_input"
    run_file="$tmp_input"
fi

[[ -f "$run_file" ]] || fatal "File does not exist: $run_file"

# run the command
case "$run_command-$backend" in
    run-@(llvm|haskell)        ) run_krun        "$@" ;;
    kast-@(llvm|haskell)       ) run_kast        "$@" ;;
    *) usage_fatal "Unknown command on '$backend' backend: $run_command" ;;
esac
