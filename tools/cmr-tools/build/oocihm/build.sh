#!/bin/bash

while read  file; do
    cihm=$(basename $file .xml)
    cihm=${cihm:5}
    echo $cihm
    output="/cihm/collections/cmr/oocihm/ecl/$cihm.xml"
    if [ -f $output ]; then
        echo "$output exists; skipping"
    else
        ./mkcmr cmr.xsd config/eco2.conf $file /cihm/collections/cmr/oocihm/ecl/$cihm.xml
    fi
done < "$1"


