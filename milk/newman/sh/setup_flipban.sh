#!/bin/sh

ts-node ../src/user.ts
ts-node ../src/users.ts --count 100
ts-node ../src/flipban/flipban.ts
ts-node ../src/flipban/fill.ts