#!/bin/bash

SCRIPT=`basename "$0"`
SCRIPT_DIR=`dirname "$0"`
HOST=`hostname`

## command to run to shut down
SHUTDOWN=echo `date` $SCRIPT "  TEST: SHUTDOWN COMMAND INVOKED"
#SHUTDOWN="shutdown -h now"

echo `date` $SCRIPT "  executing shutdown command $SHUTDOWN"
exec $SHUTDOWN

