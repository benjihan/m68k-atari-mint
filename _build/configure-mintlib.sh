#!/bin/sh -e
######################################################################
#
# mintlib
#
######################################################################

PROJECT=mintlib-Git-20170304
. ./config.cfg

######################################################################

cd ..
echo "$me: Copying source to $PROJECT ..."
cp -R -- $SOURCES/* $PROJECT/
echo "$me: Chmod source in $PROJECT ..."
chmod -R u+w $PROJECT

# if [ -n "$MINTPREFIX" ]; then
#     mkdir -vp $MINTPREFIX
# fi

######################################################################
#
# Patching configvars

LOCALTIME=${LOCALTIME-GMT}
POSIXRULES=${POSIXRULES-$LOCALTIME}

SPC='[[:space:]]*'

CC=$TARGET-gcc
CFLAGS="-O2 -fomit-frame-pointer"
LDFLAGS=''
DEFS=''

case ${stage-0} in
    0)
	toolprefix="$STAGE1/bin/$TARGET-"
	# SYSROOTUSR is in fact just the install path which can be the
	# actual SYSROOTUSR if building --with-sysroot or PREFIX
	# otherwise.
	SYSROOTUSR="${PREFIX}"
	;;
    *)
	echo "$me: invalid stage #${stage-0} for $PACKAGE" >&2
	exit 1
esac

# Patch the config file
sed -i "$PROJECT"/configvars -e \
    "
s:^${SPC}#${SPC}CROSS${SPC}=.*$:CROSS=yes:g
s:\(^${SPC}AM_DEFAULT_VERBOSITY${SPC}=\).*:\1 0:g

s:\(^${SPC}CFLAGS${SPC}=${SPC}\).*:\1$CFLAGS:g
s:\(^${SPC}LDFLAGS${SPC}=${SPC}\).*:\1$LDFLAGS:g
s:\(^${SPC}DEFS${SPC}=${SPC}\).*:\1$DEFS:g

s:\(^${SPC}prefix${SPC}=${SPC}\).*:\1$SYSROOTUSR:g
s:\(^${SPC}toolprefix${SPC}=${SPC}\).*:\1$toolprefix:g
s:\(^${SPC}LOCALTIME${SPC}=${SPC}\).*:\1$LOCALTIME:g
s:\(^${SPC}POSIXRULES${SPC}=${SPC}\).*:\1$POSIXRULES:g
"
# Display intereting part of config
grep -m1 "^${SPC}VERSION${SPC}=" "$PROJECT"/configvars
grep -m1 "^${SPC}toolprefix${SPC}=" "$PROJECT"/configvars
grep -m1 "^${SPC}prefix${SPC}=" "$PROJECT"/configvars
grep -m1 "^${SPC}CC${SPC}=" "$PROJECT"/configvars
grep -m1 "^${SPC}CFLAGS${SPC}=" "$PROJECT"/configvars
grep -m1 "^${SPC}LDFLAGS${SPC}=" "$PROJECT"/configvars
grep -m1 "^${SPC}DEFS${SPC}=" "$PROJECT"/configvars

echo
echo "> make -C $PROJECT all install"


######################################################################
