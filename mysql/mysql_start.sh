#!/bin/bash

if [ ! -f /var/lib/mysql/ibdata1 ]; then
    mysql_install_db > /dev/null
fi

pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld --user=root
