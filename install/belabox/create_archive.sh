#!/usr/bin/env bash

set -e -o pipefail

cross build --release --target aarch64-unknown-linux-gnu

WORKSPACE=workspace
rm -rf $WORKSPACE
mkdir $WORKSPACE

NAME=moblink-rust-belabox
MOBLINK_RUST_DIR=$WORKSPACE/$NAME
mkdir -p $MOBLINK_RUST_DIR/bin
cp ../../target/aarch64-unknown-linux-gnu/release/moblink-{streamer,relay,relay-service} $MOBLINK_RUST_DIR/bin
cp -r systemd $MOBLINK_RUST_DIR
tar czf $NAME.tar.gz -C $WORKSPACE $NAME

rm -rf $WORKSPACE
