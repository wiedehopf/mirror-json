#!/bin/bash

opts="-T 90 -d"
retry=15


trap "kill 0" SIGINT
trap "kill -2 0" SIGTERM

SRC=/run/dump1090-fa
DEST=/run/mirror-json

INTERVAL=10

USER=pi
TARGET=localhost
sshopts="-o ControlPath=~/.ssh/cm-%r@%h:%p -o ControlMaster=auto -o ControlPersist=10m"

ssh="ssh $sshopts $USER@$TARGET"

while true
do
	$ssh "sudo mkdir -p $DEST; sudo chown $USER $DEST"
	cat $SRC/receiver.json | sed 's/refresh" : [0-9]*/refresh" : 10000/' | sed 's/history" : [0-9]*/history" : 120/' | bzip2 | $ssh "bunzip2 > $DEST/receiver.json"

	i=0

	while (bzip2 -c $SRC/aircraft.json | $ssh "bunzip2 | tee $DEST/history_$((i%120)).json > $DEST/aircraft.json && [ -f $DEST/receiver.json ]")
	do
		if ! ((i%6))
		then
			bzip2 -c $SRC/stats.json | $ssh "bunzip2 > $DEST/stats.json"
		fi
		
		sleep $INTERVAL
		i=$((i+1))
	done
	sleep 10
done &

while true
do
	sleep 1024
done &

wait
exit 0

