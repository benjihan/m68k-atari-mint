#!/bin/sh

while read exe
do
    ldd $exe
done  |
    sort -u |
    sed -ne 's#^.* => \(/usr.*\.dll\).*#\1#p' |
    while read dll
    do
	echo -n "| $dll | "
	cygcheck -f "$dll"
    done
