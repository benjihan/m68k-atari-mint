#!/bin/bash -e
######################################################################
#
# mintbin
#
######################################################################

# PROJECT=mintbin-git
# SOURCES=../../_git/mintbin

PROJECT=mintbin-CVS-20110527

. ./config.cfg

######################################################################

set -- "$CONFIGURE" "${CONFIG[@]}" "$@"

######################################################################

run="$1"; shift
echo "> $run"
for arg in "$@"; do echo "\\ $arg"; done
echo -n 3 ..; sleep 1; echo -n 2 ..; sleep 1; echo -n 1 ..; sleep 1
echo GO !!!

"$run" "$@"

# make configure-host configure-target
make CC=gcc all -j3
if [ "${install-}" ]; then
    make $install
fi

######################################################################

cat <<EOF
________________________________________

$PACKAGE $VERSION ${stage+(stage #$stage)} ${install-compil}ed


EOF

######################################################################
