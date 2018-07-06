#!/bin/bash -e
######################################################################
#
# gcc
#
######################################################################
#
# --without-sysroot
# --with-sysroot
# --with-sysroot=<path>
#
# Since a working C library is not yet available, this
# ensures that the inhibit_libc constant is defined when
# building libgcc. This prevents the compiling of any code
# that requires libc support.
# --with-newlib
#
# When creating a complete cross-compiler, GCC requires
# standa
# --without-headers
#
# The local prefix is the location in the system that GCC
# will search for locally installed include files. The
# default is /usr/local. Setting this to /tools helps keep
# the host location of /usr/local out of this GCC's search
# path.
# --with-local-prefix=$PREFIX
#
# By default GCC searches /usr/include for system
# headers. In conjunction with the sysroot switch, this
# would translate normally to $LFS/usr/include. However
# the headers that will be installed in the next two
# sections will go to $LFS/tools/include. This switch
# ensures that gcc will find them correctly. In the second
# pass of GCC, this same switch will ensure that no
# headers from the host system are found.
#
# --with-native-system-header-dir=$USR/include
#
# This switch forces GCC to link its internal libraries
# statically. We do this to avoid possible issues with the
# host system.
# --disable-shared
#
# dsable plugin support
# --disable-plugin
# --disable-lto
#
# Unneeded and prone to fail
# --disable-multilib
# --disable-decimal-float
# --disable-threads
# --disable-libatomic
# --disable-libgomp
# --disable-libmpx
# --disable-libquadmath
# --disable-libssp
# --disable-libvtv
# --disable-libstdcxx
# --disable-libstdcxx-pch
#
# Only need c
# --enable-languages=c
#
######################################################################
#
# configure-target-libstdc++-v3 
# configure-target-libmudflap 
# configure-target-libssp 
# configure-target-newlib 
# configure-target-libgcc 
# configure-target-libquadmath 
# configure-target-libgfortran 
# configure-target-libobjc 
# configure-target-libgo 
# configure-target-libtermcap 
# configure-target-winsup 
# configure-target-libgloss 
# configure-target-gperf 
# configure-target-examples 
# configure-target-libffi 
# configure-target-libjava 
# configure-target-zlib 
# configure-target-boehm-gc 
# configure-target-qthreads 
# configure-target-rda 
# configure-target-libada 
# configure-target-libgomp

TOP_BUILDDIR="$PWD"
PROJECT=gcc-4.6.4
. ./config.cfg

######################################################################

CONFIG+=(
    CFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer"
    CXXFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer"
    
    # For configure ignore documentation building and use a copy of the
    # source's.
    MAKEINFO=false
)

case ${stage-0} in
    0)
	CONFIG+=(
	    # --with-headers="$STAGE2/include"
	    # --with-libs="$STAGE2/lib"
	    --with-sysroot
	    --disable-lto
	    --enable-multilib
	    
	    # --disable-libstdcxx
	    --disable-libstdcxx-pch # !!! crash cygwin gcc !!!

	    # Only need c
	    --enable-languages=c,c++
	)
	;;
	
    
    # stage 1
    1)
	CONFIG+=(
	    # Cross compile shenanigans
	    --without-sysroot
	    --with-newlib	# not sure it's needed
	    --without-headers	# 
	    --with-local-prefix=$PREFIX

	    #
	    --disable-shared
	    --disable-plugin
	    --disable-lto

	    # Unneeded and prone to fail
	    --disable-multilib
	    --disable-decimal-float
	    --disable-threads
	    --disable-libatomic
	    --disable-libgomp
	    --disable-libmpx
	    --disable-libquadmath
	    --disable-libssp
	    --disable-libvtv
	    --disable-libstdcxx
	    --disable-libstdcxx-pch

	    # Only need c
	    --enable-languages=c
	)
	unset SYSROOT
	;;
    # stage 2
    2)
	if [ "${SYSROOT+set}" ]; then
	    CONFIG+=(
		--with-sysroot
		--with-native-system-header-dir=$USR/include
	    )

	    # Check MiNT presence in sysroot
	    cat $SYSROOTUSR/include/COPYMINT >/dev/null

	    # Because we are using a unic sysroot for all builds we
	    # kept it in a separate directory/path. However we want a
	    # real target sysroot located at its defualt location. We
	    # are using symbolic link to do that.

	    if [ ! -r $PREFIX/$TARGET/sys-root$USR/include/COPYMINT ]; then
		if [ -h $PREFIX/$TARGET/sys-root ]; then
		    rm -- $PREFIX/$TARGET/sys-root
		fi
		if [ -e $PREFIX/$TARGET/sys-root ]; then
		    cat <<EOF

Not a valid mint install ?
> $PREFIX/$TARGET/sys-root

EOF
		    exit 1
		fi
		mkdir -pv -- "$PREFIX/$TARGET"
		if [[ $PREFIX/ = /usr* ]]; then
		    cp -Rv -- $SYSROOT $PREFIX/$TARGET/
		else
		    ln -vrs -- $SYSROOT $PREFIX/$TARGET/sys-root
		fi
	    fi
	else
	    CONFIG+=(
	    	--with-headers="$TOP_BUILDDIR/_$TARGET/include"
		--with-libs="$TOP_BUILDDIR/_$TARGET/lib"
	    )
	    test -f "$TOP_BUILDDIR/_$TARGET"/include/COPYMINT
	    test -f  "$TOP_BUILDDIR/_$TARGET"/lib/libc.a
	fi

	CONFIG+=(
	    --disable-lto
	    --enable-multilib

	    # GB: Tested without success to remove
	    #     {prefix}/lib/libiberty.a from the install
	    #
	    # --disable-install-libiberty
	    
	    # --enable-fixed-point # (does not work with m68k)
	    # --enable-decimal-float
	    # --disable-threads
	    # --disable-libatomic
	    # --disable-libgomp
	    # --disable-libmpx
	    # --disable-libquadmath
	    # --disable-libssp
	    # --disable-libvtv
	    # --disable-libstdcxx
	    --disable-libstdcxx-pch
	)

	if [ "${SYSROOT+set}" ]; then
	    # $$$ TEMP don't need c++ while testing sysroot build
	    CONFIG+=( --enable-languages=c,c++ )
	else
	    CONFIG+=(
		--with-local-prefix=$PREFIX
		--enable-languages=c,c++
	    )
	fi
	
	# add_target_tool_prefix=$STAGE1/bin/$TARGET-
	;;
    *)
	echo "$me: invalid $PACKAGE stage #${stage-0}" >&2; exit 1;;
esac

if [ "${add_target_tool_prefix+set}" ]; then
    for tool in ${target_tools[@]-}; do
	exe="${add_target_tool_prefix}$(tr [A-Z] [a-z]<<<$tool)"
	CONFIG+=( ${tool}_FOR_TARGET="${exe}" )
    done
fi

######################################################################

set -- "$CONFIGURE" "${CONFIG[@]}" "$@"

######################################################################

run="$1"; shift
echo "> $run"
for arg in "$@"; do echo "\\ $arg"; done
echo -n 3 ..; sleep 1; echo -n 2 ..; sleep 1; echo -n 1 ..; sleep 1
echo GO !!!
"$run" "$@"

gre='^\(NATIVE_SYSTEM_HEADER_DIR\|CROSS_SYSTEM_HEADER_DIR\|TARGET_SYSTEM_ROOT\)'

case ${stage-0} in
    0)
	# !!! THIS DOES NOT WORK !!!
	#
	# Because to build libgcc we need the headers from mint to be
	# installed. For this reason we will need to build a minimal
	# gcc (stage1).
	#
	echo "$me: gcc must be staged" >&2
	exit 1

	make configure-gcc configure-target-libgcc
	make -j3 all-gcc all-target-libgcc
	
	grep "$gre" ./gcc/Makefile
	echo
	echo "Bare gcc has been installed in"
	echo "\$ $PREFIX"
	echo
	echo "Build mint and pml and come back here with "
	echo "> make -C $PROJECT all"
	exit 0
	;;
    
    1)
	make configure-gcc configure-target-libgcc
	make -j3 all-gcc all-target-libgcc
	make install-gcc install-target-libgcc

	grep "$gre" ./gcc/Makefile
	cat <<EOF
________________________________________

Minimal gcc has been installed in
\$ $PREFIX

$PACKAGE $VERSION (stage #$stage) installed

EOF
	exit 0
	
	;;
    2)
	make configure-gcc configure-target-libgcc
	grep "$gre" ./gcc/Makefile
	make -j3 all-gcc all-target-libgcc
	make configure-target
	make -j3 all

	grep "$gre" ./gcc/Makefile
	cat <<EOF
________________________________________

$PACKAGE $VERSION (stage #$stage) is ready too install
\$ make -C "$PROJECT" install-strip (DESTDIR=<path>)

EOF
	exit 0

	;;
    *)
	echo "me: invalid stage #$stage for - ${PACKAGE} ${VERSION}" >&2
	exit 1
	;;
esac	

######################################################################
