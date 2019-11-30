#!/bin/bash

MAX_SICK=3

SCRIPT=`basename "$0"`
SCRIPT_DIR=`dirname "$0"`
HOST=`hostname`


if [ "$1" == '-h' ] || [ "$1" == '--help' ]
then
	echo "$SCRIPT is part of a system for monitoring the status of a UPS's"
	echo "power input. The status check works by attempting to ping a non-"
	echo "UPS-powered host (the Canary) and assumes there's a power outage"
	echo "if that fails. See README.md for more info."
	echo ""
	echo "Usage:"
	echo "  $SCRIPT -h|--help"
	echo "    Outputs this help info"
	echo ""
	echo "  $SCRIPT"
	echo "    (Run periodically as monitoring service, e.g., */5 min cron)"
	echo "    Does a health-check and:"
	echo "    - If successful, just exits"
	echo "    - If failed and too many recent failures, initiates shutdown"
	echo "    - If failed and not too many recent failures, records failure"
	echo ""
	echo "  $SCRIPT --CANARY_SICK"
	echo "    (Recursive invocation by the preceding mode to record failure)"
	echo "    Sleeps for a time and exits. Existence of the process is how"
	echo "    the system records erecent failures."
	exit;
fi


if [ "$1" == "--CANARY_SICK" ]
then
	echo `date` $SCRIPT "  sick canary pid $BASHPID sleeping"
	sleep 1800
	exit
fi


## command to run to shut down
#CANARY_SHUTDOWN=echo `date` $SCRIPT "  TEST: SHUTDOWN COMMAND INVOKED"
#CANARY_SHUTDOWN=shutdown -h now
if [ ! $CANARY_SHUTDOWN ]
then
	CANARY_SHUTDOWN=$SCRIPT_DIR/$HOST-canary-shutdown.sh
	if [ ! -f "$CANARY_SHUTDOWN" ]
	then
		CANARY_SHUTDOWN=$SCRIPT_DIR/canary-shutdown.sh
	fi
fi

# For now my network has one test canary named 'canary-1' running on wall power.
# Intent is for each canaried server 'HOST' to have its own canary 'HOST-canary'
# running on a surge-protection-only outlet of the same UPS.
# Or, each canary connected directly to a spare NIC on the server, in which case
# configuration will be needed to connect by IP.
CANARY=canary-1
#CANARY=$HOST-canary


if ping -4 -c 2 $CANARY > /dev/null 2>&1 ;
then

	echo `date` $SCRIPT "  on $HOST successfully pinged canary $CANARY"
	exit

else

	echo `date` $SCRIPT "  on $HOST FAILED TO PING CANARY $CANARY"

	## Count processes with command containing CANARY_SICK, excluding the grep.
	## (This is the number of recent failures.)
	NUM_SICK=`ps augxww | grep CANARY_SICK | grep -v grep | wc -l`
	echo `date` $SCRIPT "  on $HOST detected $NUM_SICK sick canaries"

	if (( "$NUM_SICK" < "$MAX_SICK" ))
	then
	
		echo `date` $SCRIPT "  on $HOST starting a sick canary"
		$0 '--CANARY_SICK' &
		exit

	else

		echo `date` $SCRIPT "  on $HOST DETECTED $NUM_SICK SICK CANARIES. INVOKING SHUTDOWN"
		exec $CANARY_SHUTDOWN

	fi

fi


