#!/bin/bash

ts-node ../src/user.ts
ts-node ../src/users.ts --count 10
ts-node ../src/basic/basic.ts

if [ $1 == '--master_as_entrant' ]; then
    ts-node ../src/basic/fill.ts --master_as_entrant
else
    ts-node ../src/basic/fill.ts
fi