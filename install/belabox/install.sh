#!/usr/bin/env bash

set -e

WORKSPACE=moblink-rust-install

rm -rf $WORKSPACE
mkdir $WORKSPACE
cd $WORKSPACE

systemctl stop moblink-streamer || true
systemctl stop moblink-relay-service || true

NAME=moblink-rust-belabox
wget https://mys-lang.org/moblink-rust/belabox/$NAME.tar.gz
tar xf $NAME.tar.gz
mv $NAME/bin/* /usr/local/bin
mv $NAME/systemd/* /etc/systemd/system

systemctl enable moblink-streamer
systemctl start moblink-streamer

systemctl enable moblink-relay-service
systemctl start moblink-relay-service

rm -rf $WORKSPACE
