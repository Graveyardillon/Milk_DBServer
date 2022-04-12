#!/bin/sh

ts-node ../src/user.ts
ts-node ../src/users.ts --count 50
ts-node ../src/flipban_roundrobin/flipban_roundrobin.ts

if [ "$1" == '--master_as_entrant' ]; then
    ts-node ../src/flipban_roundrobin/fill.ts --master_as_entrant
else
    ts-node ../src/flipban_roundrobin/fill.ts
fi