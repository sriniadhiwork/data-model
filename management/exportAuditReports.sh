#!/bin/bash
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required to trick cygwin into dealing with windows vs. linux EOL characters

#four arguments
#arg 1 = db hostname
#arg 2 = db username
#arg 3 = start date yyyy-mm-dd
#arg 4 = end date yyyy-mm-dd

usage () { 
	echo "This script may be called with four optional arguments: --host, --user, --start, --end."
	echo "Default values are: host=localhost, user=pulse, start=1970-01-01, and end=Now."
	echo "Dates must be formatted as YYYY-mm-dd."
	echo "USAGE: "
	echo "./exportAuditReport.sh --host=localhost --user=pulse_test --start=2017-05-01 --end=2017-05-31"
}

#variable defaults
host=localhost
user=pulse
startDate='1970-01-01'
endDate=`date +"%Y-%m-%d"`

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --user)
            user=$VALUE
            ;;
        --host)
            host=$VALUE
            ;;
		--start)
            startDate=$VALUE
            ;;
		--end)
            endDate=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done
  
echo $host
echo $user
echo $startDate
echo $endDate

psql -h $host -U $user -v startDate="$startDate" -v endDate="$endDate" -f patientDiscoveryExport.sql pulse
psql -h $host -U $user -v startDate="$startDate" -v endDate="$endDate" -f documentQueryExport.sql pulse
psql -h $host -U $user -v startDate="$startDate" -v endDate="$endDate" -f documentRetrieveExport.sql pulse
psql -h $host -U $user -v startDate="$startDate" -v endDate="$endDate" -f patientStageExport.sql pulse
psql -h $host -U $user -v startDate="$startDate" -v endDate="$endDate" -f documentViewExport.sql pulse
psql -h $host -U $user -v startDate="$startDate" -v endDate="$endDate" -f patientDischargeExport.sql pulse