#!/bin/bash -eu
######################################################################
#
# Create atari-mint toolchain package for cywin64
#
# By Benjamin Gerard
#

me=$(basename "$0" .sh)
error() { echo "$me: $@" >&2; return 1; }
if [ ! -h "$me" ]; then
    error "not a symbolic link -- $0"
fi

patch=$(sed -ne 's:^PATCH=-mint-\([0-9]\{8\}\).*:\1:p' config.cfg)
gpg="gpg --yes -u 52D4145B"
target=m68k-atari-mint
tmp=`mktemp`
trap "rm -f -- $tmp" EXIT

host=${PWD##*/}
case $host in
    *-*-*) ;;
    *) error "invalid host -- $host" ;;
esac

prefix=/usr
suffix=${me##*-}
sysroot=$(realpath -e ../../sys-root)
sysrootusr=${sysroot}${prefix}
packaged=$(realpath -e $PWD/../../_packaged)
[ -d ${packaged}/${patch}/${suffix} ] ||
    mkdir -p -- ${packaged}/${patch}/${suffix}
packaged=${packaged}/${patch}

echo "patch:    ${patch}"
echo "suffix:   ${suffix}"
echo "sysroot:  ${sysroot}"
echo "packaged: ${packaged}"

######################################################################
# Draw a text in a box
# --------------------------------------------------------------------
# $* text
box()
{
    local txt="$*"
    echo
    echo "+-${txt//?/-}-+"
    echo "| ${txt} |"
    echo "+-${txt//?/-}-+"
    echo
}

#######################################################################
# Archive the package / create listing and signature
# ---------------------------------------------------------------------
# $1: working-dir
# $2: package filename base
package()
{
    local path="${packaged}"
    local wdir=_package file="$1"
    
    [ -d "$path" ] ||
	error "not a dir -- $path"

    ( cd "$wdir" && tar -T - -cJvf "$path/$file".tar.xz |
	      xargs -r -d'\n' -- md5sum -b -- >"$path/$file".md5 )
    
    $gpg -bao "$path/$file".md5.sig "$path/$file".md5 >/dev/null
    ( cd "$path" &&
	  printf -- '* %8s %s\n' $(du -h $file.tar.xz) &&
	  printf -- '* %8s %s\n' $(wc -l $file.md5) &&
	  gpg --verify $file.md5.sig $file.md5
    )
}

# $1: working-dir
fix_perm()
{
    local dir="$1"
    find "$dir" -type d -print0 | xargs -r0 chmod 755
    find "$dir" -type f -executable -print0 | xargs -r0 chmod 755
}

package_mintlib()
{
    local file path arc

    # ----------------------------------------
    box "Packaging mintlib-$patch"

    # Just verify some random files to ensure we are not trying to
    # package the wrong thing
    echo "> verify MiNT"
    for file in lib/libc.a lib/libm.a include/mint/trap14.h include/COPYMINT
    do
	path="$sysrootusr/$file"
	if [ ! -f "$path"  ]; then
	    error "mintlib-$patch: missing file -- \$sysrootusr/$file"
	fi
    done

    if [ -d _package ]; then
     	echo "> clean-up working dir"
	rm -rf -- _package
    fi

    arc=sysroot-mint-$patch
    mkdir -p -- "_package${prefix}/${target}"

    # ----------------------------------------
    echo "> copy MiNT (working dir)"
    cp -R -- "${sysroot}" "_package${prefix}/${target}"

    echo "> fix permissions"
    find _package${prefix} -type d -print0 | xargs -r0 chmod 755
    find _package${prefix} -type f -print0 | xargs -r0 chmod 644
    
    echo "> packaging"
    find "_package${prefix}/${target}/sys-root" ! -type d | cut -d/ -f2- |
	package $arc

    # ----------------------------------------
    echo "> clean-up working dir"
    rm -rf -- "_package"
    
    tarlist="$arc.tar.xz $tarlist"
}

package_common()
{
    local src arc cfg="$1" wdir package

    pkg=$(sed -ne 's/^PROJECT=\([^[:space:]]\+\).*/\1/p' $cfg)
    src=$pkg-mint-$patch-sys-sysroot-stage2
    arc=$suffix/$pkg-mint-$patch-$suffix
    wdir="$PWD/_package"
    
    # ----------------------------------------
    box "Packaging $pkg-$patch"

    # ----------------------------------------
    echo "> make all"
    make -C $src \
	 all \
	 >/dev/null

    if [ -d "$wdir" ]; then
	echo "> clean-up working dir"
    	rm -rf -- "$wdir"
    fi
    
    # ----------------------------------------
    echo "> make install (working dir)"
    make -C $src \
	 install-strip DESTDIR="$wdir" \
	 >/dev/null 2>/dev/null

    # ----------------------------------------
    echo "> fix permissions"
    fix_perm "$wdir"

    # ----------------------------------------
    # GB: List everything we want to keep.
    #     - Not directory
    #     - Under the path */m68k-atari-mint[-/]*
    #     - Not a libtool object
    echo "> packaging"
    ( cd "$wdir" &&
	  find .${prefix} ! -type d \
	       -path "*/${target}*" \
	       ! -name \*.la
    ) | cut -c3- | package $arc
    tarlist="$arc.tar.xz $tarlist"
    
    # ----------------------------------------
    echo "> clean-up working dir"
    rm -rf -- "$wdir"
}    

package_binutils()
{
    package_common 01-configure-binutils-stage1
}

package_gcc()
{
    package_common 02-configure-gcc-stage1
}

package_mintbin()
{
    local cfg=07-configure-mintbin-sys-sysroot
    local src arc wdir bdir package file

    pkg=$(sed -ne 's/^PROJECT=\([^[:space:]]\+\).*/\1/p' $cfg)
    src=$pkg-sys-sysroot
    arc=$suffix/$pkg-mint-$patch-$suffix
    wdir="$PWD/_package"
    
    # ----------------------------------------
    box "Packaging $pkg"

    # ----------------------------------------
    echo "> make all"
    make -C "$src" \
	 all \
	 >/dev/null

    if [ -d "$wdir" ]; then
	echo "> clean-up working dir"
    	rm -rf -- "$wdir"
    fi
    
    # ----------------------------------------
    echo "> make install (working dir)"
    make -C "$src" \
	 install-strip DESTDIR="$wdir" \
	 >/dev/null

    # ----------------------------------------
    echo "> fix permissions"
    fix_perm "$wdir"

    # ----------------------------------------
    # GB: mintbin use very old and very bugged autotools/install. It
    #     needs to be tweaked to match a normal file layout.
    echo "> tweak install"
    mkdir -p -- "${wdir}${prefix}"/bin
    mv -- "${wdir}/${target}"-* "${wdir}${prefix}/bin/"
    (
	cd "${wdir}${prefix}/${target}/bin"
	for file in ${target}-*; do
	    mv -- "$file" "${file#$target-}"
	done
    )
    
    # ----------------------------------------
    # GB: List everything we want to keep.
    #     - Not directory
    #     - Under the path */m68k-atari-mint[-/]*
    #     - Not a libtool object
    echo "> packaging"
    ( cd "$wdir" &&
	  find .${prefix} ! -type d \
	       -path "*/m68k-atari-mint*" \
	       ! -name \*.la
    ) | cut -c3- | package "$arc"

    tarlist="$arc.tar.xz $tarlist"

    # ----------------------------------------
    echo "> clean-up working dir"
    rm -rf -- "$wdir"
}

package_all() {
    local pkg wdir file arc

    pkg=$target-$patch
    wdir=_package
    arc=$suffix/$target-$patch-$suffix

    # ----------------------------------------
    box "Packaging $target"
    
    # ----------------------------------------
    if [ -d "$wdir" ]; then
	echo "> clean-up working dir"
    	rm -rf -- "$wdir"
    fi
    mkdir -p -- "$wdir"

    # ----------------------------------------
    for file in $tarlist; do
	echo "> extract $file (working dir)"
	tar -C "$wdir" -xpf "$packaged/$file"
    done

    # ----------------------------------------
    echo "> packaging"
    ( cd "$wdir" &&
	  find .${prefix} ! -type d 
    ) | cut -c3- | package $arc

    # ----------------------------------------
    echo "> clean-up working dir"
    rm -rf -- "$wdir"
}

#######################################################################
# Let's go 

tarlist=""
package_mintlib
package_binutils
package_gcc
package_mintbin
package_all
