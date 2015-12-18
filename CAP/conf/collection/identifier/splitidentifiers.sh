#!/bin/bash

depositors=(ams omcn oocihm ooe oop)

for depositor in "${depositors[@]}"
do
   echo "Processing $depositor"
   grep -E "^${depositor}\."  identifiers-aip-20151218.csv | sed -e 's/^[^\.]*\.\(.*\)$/\1/' >identifiers-aip-${depositor}.csv
done
