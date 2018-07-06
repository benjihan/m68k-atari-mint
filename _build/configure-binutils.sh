#!/bin/bash -e
######################################################################
#
# binutils
#
######################################################################

PROJECT=binutils-2.30

. ./config.cfg

######################################################################

install=install-strip
case ${stage-0} in
    # stage 1
    1)
    	CONFIG+=(
    	    --without-sysroot
    	    --disable-lto
    	    --disable-multilib
    	    --disable-plugins
    	)
    	unset SYSROOT SYSROOTUSR
    	;;

    # stage 2
    2)
	if [ "${SYSROOT+set}" ]; then
	    CONFIG+=( --with-sysroot )
	    mkdir -pv "$SYSROOTUSR"/{include,lib}
	else
	    CONFIG+=( --without-sysroot )
	fi
	
	CONFIG+=(
	    --enable-multilib
	    --enable-compressed-debug-sections=all
	    --disable-gold
	    --disable-plugins
	)

	# GB: Do not install stage2 automatically
	install=
	;;
    *)
	echo "me: invalid stage #$stage for - ${PACKAGE} ${VERSION}" >&2
	exit 1
	;;
esac

######################################################################

set -- "$CONFIGURE" "${CONFIG[@]}" "$@"

######################################################################

run="$1"; shift
echo "> $run"
for arg in "$@"; do echo "\\ $arg"; done
echo -n 3 ..; sleep 1; echo -n 2 ..; sleep 1; echo -n 1 ..; sleep 1
echo GO !!!

"$run" "$@"
make configure-host configure-target
make all -j3
if [ "$install" ]; then
    make $install
fi

######################################################################

cat <<EOF
________________________________________

$PACKAGE $VERSION ${stage+(stage #$stage)} ${install:-compil}ed


EOF

######################################################################
