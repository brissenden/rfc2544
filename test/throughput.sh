#!/bin/bash

SERVER=85.14.98.130
PORT=8000

DIR=$(dirname $0)
NOW=$(date +'%Y%m%d%H%M%S')

if [ ! -d "log/throughput" ];then
	mkdir log/throughput
fi

if [ ! -d "bin" ];then
	mkdir bin
fi

make

mkdir log/throughput/$NOW

for BYTES in `echo "1518 1280 1024 512 256 128 64"`
do
	echo "bin/throughput $SERVER $PORT $BYTES"
	bin/throughput $SERVER $PORT $BYTES | tee -a log/throughput/$NOW/$BYTES-$NOW.log
done
