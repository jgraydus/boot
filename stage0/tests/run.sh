#!/bin/bash

# get the directory where the script is located
DIR=$(dirname $(readlink -f $0))

declare -A out
declare -A res

# run each of the .0 files in the test directory
for file in $DIR/*.0
do
    name=$(basename $file)
    # run in a subshell so we can capture error messages (e.g. seg faults)
    out[$name]=$(sh -c $DIR/../main < $file 2>&1)  # capture the stdout and stderr
    res[$name]=$?                                  # capture the exit code
    # display pass or fail based on exit code
    if [[ res[$name] -eq 0 ]] 
    # tput is a standard utility to create terminal control codes
    # i'm using it here to add colored text
    then echo "$(tput setaf 2)PASS$(tput sgr0)    $name"
    else echo "$(tput setaf 1)FAIL$(tput sgr0)    $name"
    fi
done

# print the output of each failing test
for key in "${!out[@]}"; do
    if [[ res[$key] -ne 0 ]]; then
        echo "" ""
        echo "output of $key:"
        echo "${out[$key]}"
    fi
done

exit $RESULT

