#!/bin/sh

ts-node ../src/user.ts
ts-node ../src/users.ts --count 80

if [ "$1" = '--enable_point_multiplier' ] && [ "$2" = '--team' ]; then
    ts-node ../src/freeforall/freeforall_team.ts --enable_point_multiplier
elif [ "$1" = '--enable_point_multiplier' ]; then
    ts-node ../src/freeforall/freeforall.ts --enable_point_multiplier
else
    ts-node ../src/freeforall/freeforall.ts
fi

if [ "$1" = '--master_as_entrant' ]; then
    ts-node ../src/freeforall/fill.ts --master_as_entrant
elif [ "$2" = '--team' ]; then
    ts-node ../src/freeforall/fill_team.ts
else
    ts-node ../src/freeforall/fill.ts
fi