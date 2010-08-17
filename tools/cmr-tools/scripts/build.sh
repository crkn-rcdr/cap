#!/bin/bash

BIN="/cihm/collections/cmr-tools"

while [ $1 ]; do
    src="$1/data/src"
    #out="$1/data"
    if [ ! -d $src ]; then
        echo "$src directory does not exist"
        exit 1
    fi

    for infile in $src/*.xml; do
        outfile="$src/cmr-$infile"
        echo "$infile => $outfile"
        $BIN/cmr -dump utoronto $infile $outfile
        if [ $? != 0 ]; then
            echo "Quitting due to errors. Exit code: $?"
            echo $infile: `date` >> fail.log
            exit
        fi
    done

    shift
done
