#!/bin/bash

export PIGY_PORT=5188
export PIGY_MYSQL_HOST='10.101.83.238'
export PIGY_MYSQL_PORT=3306
export PIGY_MYSQL_USER='drogo'
export PIGY_MYSQL_DB='pigy'
export PIGY_MYSQL_PWD='drogo'

./skynet/skynet ./etc/config.login
