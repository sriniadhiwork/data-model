#!/bin/bash
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required to trick cygwin into dealing with windows vs. linux EOL characters

if [ $# -ne 2 ]; then
    psql -Upostgres -f drop-pulse.sql
    psql -Upostgres -f data-model.sql 
else
    host=$1
    user=$2

    psql -h $host -U $user -f drop-pulse.sql 
    psql -h $host -U $user -f data-model.sql
fi
