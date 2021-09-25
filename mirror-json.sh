#!/bin/bash

opts="-T 90 -d"
retry=15


trap "kill 0" SIGINT
trap "kill -2 0" SIGTERM

sshopts="-o ControlPath=~/.ssh/cm-%r@%h:%p -o ControlMaster=auto -o ControlPersist=10m -o ConnectTimeout=5 -o ServerAliveInterval=3"

ssh="timeout -s9 8 ssh $sshopts $USER@$TARGET"

bzip2='timeout -s9 8 bzip2'
while true
do
	$ssh "sudo mkdir -p $DEST; sudo chown $USER $DEST"
	timeout -s9 8 cat $SRC/receiver.json \
        | sed -E "s/refresh\" ?: ?[0-9]*/refresh\" : ${INTERVAL}000/" \
        | sed -E "s/history\" ?: ?[0-9]*/history\" : $HISTORY/" \
        | sed -E "s/aircraft_binCraft\" ?: ?true/aircraft_binCraft\" : false/" \
        | bzip2 | $ssh "bunzip2 > $DEST/receiver.json"

	i=0
	while
		sleep $INTERVAL &
		$bzip2 -c $SRC/aircraft.json | $ssh "bunzip2 | tee $DEST/history_$((i%$HISTORY)).json > $DEST/tmp.json && [ -f $DEST/receiver.json ] && mv $DEST/tmp.json $DEST/aircraft.json"
	do
		wait
		i=$((i+1))
	done
done &

while sleep 3
do
	sleep 57 &
	if ! ($bzip2 -c $SRC/stats.json | $ssh "bunzip2 > $DEST/stats-tmp.json && mv $DEST/stats-tmp.json $DEST/stats.json")
	then
		($bzip2 -c $SRC/stats.json | $ssh "bunzip2 > $DEST/stats-tmp.json && mv $DEST/stats-tmp.json $DEST/stats.json")
    fi
    if [[ -f /run/airspy_adsb/stats.json ]]; then
        $ssh "sudo mkdir -p /run/airspy_adsb; sudo chown $USER /run/airspy_adsb"
        if ! ($bzip2 -c /run/airspy_adsb/stats.json | $ssh "bunzip2 > /run/airspy_adsb/stats-tmp.json && mv /run/airspy_adsb/stats-tmp.json /run/airspy_adsb/stats.json")
        then
            ($bzip2 -c /run/airspy_adsb/stats.json | $ssh "bunzip2 > /run/airspy_adsb/stats-tmp.json && mv /run/airspy_adsb/stats-tmp.json /run/airspy_adsb/stats.json")
        fi
    fi
	wait
done &

while true
do
	sleep 1024
done &

wait
exit 0

