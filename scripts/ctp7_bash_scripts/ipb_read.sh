#!/bin/sh

addr=$((0x64000000 + ($1 << 2)))

printf 'mpeek 0x%x\n' $addr
mpeek $addr

