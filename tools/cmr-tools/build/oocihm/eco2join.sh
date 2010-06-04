#!/bin/bash

root=/cihm/collections/src/oocihm/ecl

for dir in $root/*; do
    cihm=$(basename $dir)
    echo $cihm;
    cd $dir/data/source
    if [ -f eco2-$cihm.xml ]; then
        echo "eco2-$cihm.xml exists. Skipping"
    else
        pwd
        /cihm/collections/tools/eco2join $cihm.xml
    fi
done
