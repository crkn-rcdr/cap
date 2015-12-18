#!/bin/bash

depositors=(ams omcn oocihm ooe oop)

for depositor in "${depositors[@]}"
do
   echo "Processing $depositor"
   grep -E "^${depositor}\."  portals-aip-20151218.csv | sed -e 's/^[^\.]*\.\(.*\)$/\1/' >portals-aip-${depositor}.csv
done

