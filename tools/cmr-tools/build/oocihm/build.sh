#!/bin/bash

base="/cihm/collections/cmr/oocihm/hfc"

while read  file; do
    cihm=$(basename $file .xml)
    cihm=${cihm:5}
    echo $cihm
    output="$base/$cihm.xml"
    echo $output
    if [ -f $output ]; then
        echo "$output exists; skipping"
    else
        ./mkcmr cmr.xsd config/eco2.conf $file $output
    fi
done < "$1"


