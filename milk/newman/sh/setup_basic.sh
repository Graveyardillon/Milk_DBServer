#!/bin/bash

ts-node ../src/user.ts

if [ "$1" == '--team' ]; then
    ts-node ../src/users.ts --count 50
    ts-node ../src/basic/basic.ts --is_team true --team_size 5
else
    ts-node ../src/users.ts --count 10
    ts-node ../src/basic/basic.ts
fi

if [ "$1" == '--master_as_entrant' ]; then
    ts-node ../src/basic/fill.ts --master_as_entrant
elif [ "$1" == '--team' ]; then
    ts-node ../src/basic/fill_team.ts
else
    ts-node ../src/basic/fill.ts
fi