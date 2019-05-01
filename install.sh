#!/bin/bash

sudo cp mirror-json.service /lib/systemd/system
sudo cp mirror-json.sh /usr/local/bin/
sudo cp -n default /etc/default/mirror-json

cat 88-mirror-json.conf | ssh $1@$2 "sudo tee /etc/lighttpd/conf-available/88-mirror-json.conf >/dev/null; sudo lighty-enable-mod mirror-json; sudo systemctl restart lighttpd"

sudo sed -i "s/USER=.*/USER=$1/" /etc/default/mirror-json
sudo sed -i "s/TARGET=.*/TARGET=$2/" /etc/default/mirror-json

sudo systemctl daemon-reload
sudo systemctl enable mirror-json
sudo systemctl restart mirror-json
