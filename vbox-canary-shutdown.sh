#!/bin/bash

SCRIPT=`basename "$0"`
SCRIPT_DIR=`dirname "$0"`
HOST=`hostname`

SHUTDOWN=$SCRIPT_DIR/canary-shutdown.sh

WAIT=5

## commands to suspend/resume vbox VMs are:
## vboxmanage controlvm NAME savestate
## vboxheadless --startvm NAME >>/dev/null 2>&1 &

## ref https://unix.stackexchange.com/questions/412868/bash-reverse-an-array/412919#412919
## TODO: understand WTF is up with bash array syntax
reverse() {
	## first argument is the variable name of the array to reverse
	## second is the variable name of the output array
	declare -n arr="$1" rev="$2"
	#for i in "${arr[@]}"
	for i in $arr
	do
		rev=($i "${rev[@]}")
		#rev=("${i//[$'\t\r\n ']}" "${rev[@]}")
	done
}

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
	reverse HOST_VM_START_ORDER HOST_VM_SUSPEND_ORDER
fi

if [ $VBOX_USER == 'root']
then
	VBOX_USER_HOME='/root'
else 
	VBOX_USER_HOME="/home/$VBOX_USER"
fi

if [ $HOST_VM_SUSPEND_ORDER ]
then
	echo `date` $SCRIPT "  suspending configured VMs if running"
	for vm in "${HOST_VM_SUSPEND_ORDER[@]}"
	do
		IS_RUNNING=`HOME=$VBOX_USER_HOME sudo -u $VBOX_USER vboxmanage list runningvms | grep '$vm'`
		if [ $IS_RUNNING ]
		then
			PAUSE_VM="HOME=$VBOX_USER_HOME sudo -u $VBOX_USER controlvm '$vm' savestate"
			echo `date` $SCRIPT "  executing vbox suspend command: $PAUSE_VM"
			$PAUSE_VM
			echo `date` $SCRIPT "  waiting $WAIT seconds"
			sleep $WAIT
		else
			echo `date` $SCRIPT "  vm '$vm' is not running. skipping."
		fi
	done
fi

echo `date` $SCRIPT "  suspending remaining running VMs"
RUNNING=`HOME=$VBOX_USER_HOME sudo -u $VBOX_USER vboxmanage list runningvms | cut -d '"' -f 2`
if [ $running ]
then
	for vm in $RUNNING
	do
		PAUSE_VM="HOME=$VBOX_USER_HOME sudo -u $VBOX_USER controlvm '$vm' savestate"
		echo `date` $SCRIPT "  executing vbox suspend command: $PAUSE_VM"
		$PAUSE_VM
		echo `date` $SCRIPT "  waiting $WAIT seconds"
		sleep $WAIT
	done
fi


echo `date` $SCRIPT "  executing shutdown command $SHUTDOWN"
exec $SHUTDOWN

