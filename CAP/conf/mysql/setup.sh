#!/bin/bash
# Run this script after installing or updating CAP

SCRIPT_PATH=$(dirname $0)
DBUSER="$1"
DBPASSWORD="$2"
MYSQL="$3"

# If $MYSQL is not specified, use the default path
if [ ! -e "$MYSQL" ]; then
    MYSQL=$(which mysql)
    if [ ! -e "$MYSQL" ]; then
        echo "Can't find path to mysql"
        exit 1
    fi
fi

if [ ! $DBUSER ]; then
    echo "No database userid specified; defaulting to 'root'"
    DBUSER="root"
fi

echo "Creating databases and granting permissions"
$MYSQL -u $DBUSER -p$DBPASSWORD < $SCRIPT_PATH/create_databases.sql

echo "Setting cap_core values"
$MYSQL -u $DBUSER -p$DBPASSWORD cap_core < $SCRIPT_PATH/cap_core.sql
