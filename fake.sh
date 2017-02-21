#!/bin/bash
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required to trick cygwin into dealing with windows vs. linux EOL characters

if [ $# -ne 2 ]; then
    host=localhost
    user=pulse
else
    host=$1
    user=$2
fi
psql -h $host -U $user -f fake-init.sql pulse

for (( i=1 ; ((i-1451)) ; i=(($i+1)) ))
#for (( i=1 ; ((i-25)) ; i=(($i+1)) ))
do
  psql -v v1=$i -h $host -U $user -f fake-load.sql pulse
done;

psql -h $host -U $user -f fake-clear.sql pulse
