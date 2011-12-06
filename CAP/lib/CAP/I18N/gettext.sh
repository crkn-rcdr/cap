#!/bin/sh
# Run this script from the lib/CAP/I18N directory to update the fr.po
# catalog.

#caproot=$1;

pofile=fr.po


if [ -d $caproot ]; then
    cp $pofile $pofile.bak
    if [ $? != 0 ]; then
        echo Failed to back up $pofile: $?
        exit $?
    fi

    (find ../Controller -name '*.pm'; find ../../../../../cap-root -name '*.tt') | \
    xargs xgettext.pl -o $pofile
else
    echo "Usage $0 PATH_TO_CAP_ROOT"
fi
