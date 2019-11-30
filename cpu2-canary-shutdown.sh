#!/bin/bash

SCRIPT=`basename "$0"`
SCRIPT_DIR=`dirname "$0"`
HOST=`hostname`

SHUTDOWN=$SCRIPT_DIR/vbox-canary-shutdown.sh

echo `date` $SCRIPT "  executing shutdown command $SHUTDOWN"
exec $SHUTDOWN
