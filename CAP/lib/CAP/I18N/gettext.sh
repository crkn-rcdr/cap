#!/bin/sh
# Run this script from the lib/CAP/I18N directory to update the fr.po
# catalog.

pofile=fr.po

cp $pofile $pofile.bak
if [ $? != 0 ]; then
    echo Failed to back up $pofile: $?
    exit $?
fi

find ../../../root -name '*.tt' | xargs xgettext.pl -o $pofile
