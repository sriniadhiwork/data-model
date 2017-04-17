#!/bin/bash
if [ $# -ne 2 ]; then
    host=localhost
    user=pulse
else
    host=$1
    user=$2
fi
psql -h $host -U $user -f clear-phi.sql pulse