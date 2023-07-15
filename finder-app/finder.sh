#!/bin/bash

usage() {
    echo "Usage: ./finder.sh <existing_directory> <search_string>"
    exit 1
}

if [[ -n "$1" ]]; then
    if [[ -d "$1" ]]; then
        filesdir="$1"
    else
        echo "First argument is not an existing directory."
        usage
    fi
else
    echo "Missing arguments"
    usage
fi

if [[ -n "$2" ]]; then
    searchstr="$2"
else
    echo "Missing second argument"
    usage
fi

num_files=$(grep -rl ${searchstr} ${filesdir} | wc -l)
num_lines=$(grep -r ${searchstr} ${filesdir} | wc -l)

echo "The number of files are ${num_files} and the number of matching lines are ${num_lines}"
