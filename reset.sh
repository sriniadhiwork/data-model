#!/bin/bash
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required to trick cygwin into dealing with windows vs. linux EOL characters

if [ $# -ne 2 ]; then
    psql -Upostgres -f drop-pulse.sql pulse
	psql -Upostgres -f drop-pulse.sql pulse_test
    psql -Upostgres -f data-model.sql pulse
	psql -Upostgres -f data-model.sql pulse_test
else
    host=$1
    user=$2

    psql -h $host -U $user -f drop-pulse.sql pulse
	psql -h $host -U $user -f drop-pulse.sql pulse_test
    psql -h $host -U $user -f data-model.sql pulse
	psql -h $host -U $user -f data-model.sql pulse_test
fi
