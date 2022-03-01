#!/bin/sh

ts-node ../src/user.ts
ts-node ../src/users.ts --count 50

if [ "$1" == '--enable_point_multiplier' ]; then
    ts-node ../src/freeforall/freeforall.ts --enable_point_multiplier
else
    ts-node ../src/freeforall/freeforall.ts
fi

if [ "$1" == '--master_as_entrant' ]; then
    ts-node ../src/freeforall/fill.ts --master_as_entrant
else
    ts-node ../src/freeforall/fill.ts
fi