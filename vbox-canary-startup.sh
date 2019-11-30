#!/bin/bash

SCRIPT=`basename "$0"`
SCRIPT_DIR=`dirname "$0"`
HOST=`hostname`

WAIT=60


## commands to suspend/resume vbox VMs are:
## vboxmanage controlvm NAME savestate
## vboxheadless --startvm NAME >>/dev/null 2>&1 &

## defaults
VBOX_USER=`whoami`

VBOX_CANARY_CONFIG=$SCRIPT_DIR/$HOST-vbox-canary.cfg
## config format is lines like "key:value"
## cmd to get key value is "KEYVAL=`grep key $VBOX_CANARY_CONFIG | cut -d ':' -f 2`
## keys must be completely unique in the file, or multiple "key:value" lines for array values

if [ -f "$VBOX_CANARY_CONFIG" ]
then
	VBOX_USER=`grep vbox_user $VBOX_CANARY_CONFIG | cut -d ':' -f 2`
	[ ! $VBOX_USER ] || VBOX_USER=`whoami`

	HOST_VM_START_ORDER=`grep vm_name $VBOX_CANARY_CONFIG | cut -d ':' -f 2`

	#echo $HOST configured VM start order:
	#for vm in $HOST_VM_START_ORDER
	#do
	#	echo \'$vm\'
	#done
fi

if [ $VBOX_USER == 'root']
then
	VBOX_USER_HOME='/root'
else 
	VBOX_USER_HOME="/home/$VBOX_USER"
fi


echo `date` $SCRIPT "  starting configured VMs if not running"
for vm in $HOST_VM_START_ORDER
do
	IS_RUNNING=`HOME=$VBOX_USER_HOME sudo -u $VBOX_USER vboxmanage list runningvms | grep '$vm'`
	if [ ! $IS_RUNNING ]
	then
		START_VM="echo vboxheadless --startvm '$vm'"
		echo `date` $SCRIPT "  executing vbox start command: $START_VM"
		$START_VM >>/dev/null 2>&1 &
		echo `date` $SCRIPT "  waiting $WAIT seconds"
		sleep $WAIT
	fi
done

echo `date` $SCRIPT "  completed startup sequence"

