#!/bin/bash

# arg 1 full path
usage() {
    echo "Usage: ./writer.sh <file_path> <text_to_write>"
    exit 1
}

if [[ -n "$1" && -n "$2" ]]; then
    writefile="$1"
    writestr="$2"
else
    echo "Missing argument"
    usage
fi

dir=$(dirname $writefile)
fln=$(basename $writefile)

mkdir -p $dir
echo $writestr > ${dir}/${fln}

if [[ $? -ne 0 ]]; then
    echo "Unable to create file"
    exit 1
fi
