#!/bin/bash
username="redsocks"
group="redsocks"

if id -u $username >/dev/null 2>&1; then
        echo "user exists"
else
        groupadd $group
        useradd -g $group $username
fi

git clone https://github.com/darkk/redsocks
cd redsocks
apt-get install -y libevent-dev
make
mv redsocks /usr/bin/redsocks
cp ../redsocks.conf /etc/redsocks.conf
