#!/bin/bash

opts="-T 90 -d"
retry=15


trap "kill 0" SIGINT
trap "kill -2 0" SIGTERM

sshopts="-o ControlPath=~/.ssh/cm-%r@%h:%p -o ControlMaster=auto -o ControlPersist=10m -o ConnectTimeout=5 -o ServerAliveInterval=3"

ssh="ssh $sshopts $USER@$TARGET"

while true
do
	$ssh "sudo mkdir -p $DEST; sudo chown $USER $DEST"
	cat $SRC/receiver.json | sed "s/refresh\" : [0-9]*/refresh\" : ${INTERVAL}000/" | sed "s/history\" : [0-9]*/history\" : $HISTORY/" | bzip2 | $ssh "bunzip2 > $DEST/receiver.json"

	i=0
	while
		sleep $INTERVAL &
		pid=$!
		bzip2 -c $SRC/aircraft.json | $ssh "bunzip2 | tee $DEST/history_$((i%$HISTORY)).json > $DEST/tmp.json && [ -f $DEST/receiver.json ] && mv $DEST/tmp.json $DEST/aircraft.json"
	do
		if ps $pid | grep "sleep $INTERVAL" -c >/dev/null
		then
			wait $pid
		fi
		i=$((i+1))
	done
done &

while sleep 3
do
	sleep 57 &
	pid=$!
	if ! (bzip2 -c $SRC/stats.json | $ssh "bunzip2 > $DEST/stats-tmp.json && mv $DEST/stats-tmp.json $DEST/stats.json")
	then
		(bzip2 -c $SRC/stats.json | $ssh "bunzip2 > $DEST/stats-tmp.json && mv $DEST/stats-tmp.json $DEST/stats.json")
	fi
	if ps $pid | grep "sleep 57" -c >/dev/null
	then
		wait $pid
	fi
done &

while true
do
	sleep 1024
done &

wait
exit 0

