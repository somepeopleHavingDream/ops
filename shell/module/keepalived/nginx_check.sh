#!/bin/bash
result=`pidof nginx`
if [ ! -z "${result}" ];
then
    exit 0
else
    exit 1
fi