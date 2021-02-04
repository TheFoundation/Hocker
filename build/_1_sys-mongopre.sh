#!/bin/sh

which mongod &>/dev/null && {
    test -d /etc/mongodb || mkdir /etc/mongodb
    test -f /etc/mongodb/mongodb.conf || ( mv /etc/mongodb.conf /etc/mongodb/mongodb.conf ; ln -s /etc/mongodb/mongodb.conf /etc/mongodb.conf )
echo -n ; } ;
