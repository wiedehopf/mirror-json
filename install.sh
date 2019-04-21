#!/bin/bash

sudo cp mirror-json.service /lib/systemd/system
sudo cp mirror-json.sh /usr/local/bin/

cat 89-mirror-json.conf | ssh $1@$2 "sudo tee /etc/lighttpd/conf-available/89-mirror-json.conf >/dev/null; sudo lighty-enable-mod mirror-json; sudo systemctl restart lighttpd"

sudo sed -i "s/USER=.*/USER=$1/" /usr/local/bin/mirror-json.sh
sudo sed -i "s/TARGET=.*/TARGET=$2/" /usr/local/bin/mirror-json.sh


sudo systemctl enable mirror-json
sudo systemctl restart mirror-json
