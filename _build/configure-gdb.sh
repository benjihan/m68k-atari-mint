#!/bin/sh -e
######################################################################
#
# binutils
#
######################################################################

PROJECT=gdb-5.1
. ./config.cfg


######################################################################

set -- \
    ../$CONFIGURE \
    \
    --host=$ARCH \
    --build=$ARCH \
    --target=$TARGET \
    --prefix=$PREFIX \
    --with-sysroot=${SYSROOT} \
    \
    --disable-nls \
    --disable-sim \
    --enable-tui \
    --enable-gdbmi \
    --enable-gdbcli \
    --disable-gdbtk \
    --with-cpu=68000 \
    \
    "${CONFIG[@]}" \
    \
    --with-gnu-as \
    --with-gnu-ld \
    \
    "$@"

if [ ! -e "$PREFIX"/sys-root ]; then
    ln -s . "$PREFIX"/sys-root
fi

if [ ! -e "$PREFIX"/sys-root/usr ]; then
    ln -s . "$PREFIX"/sys-root/usr
fi

for dir in lib bin include; do
    if [ ! -e "$PREFIX"/sys-root/usr/$dir ]; then
	mkdir -- "$PREFIX"/sys-root/usr/$dir
    fi
done

######################################################################

help=no
for arg in "$@"; do
    echo ">> $arg"
    if [[ "$arg" = --help* ]]; then
	help=yes
    fi
done

if [ "$help" != yes ]; then
    echo 3 ..
    sleep 1
    echo 2 ..
    sleep 1
    echo 1 ..
    sleep 1
fi
"$@"
