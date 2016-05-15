#
# Create tools and wrappers.  This step needs to be run at least once.
# The routine is run if the "tools" argument is specified.
#
# You might want to skip it because:
# 1) iteration speed on a slow-ish host
# 2) making manual modifications to the tools for testing and avoiding
#    the script nuking them on the next iteration
#
# external toolchain links are created in the format that
# build.sh expects.
#
maketools ()
{

	checkcheckout

	probeld
	probenm
	probear
	${HAVECXX} && probecxx

	cd ${OBJDIR}

	# Create mk.conf.  Create it under a temp name first so as to
	# not affect the tool build with its contents
	MKCONF="${BRTOOLDIR}/mk.conf.building"
	> "${MKCONF}"
	mkconf_final="${BRTOOLDIR}/mk.conf"
	> ${mkconf_final}

	${KERNONLY} || probe_rumpuserbits

	checkcompiler

	#
	# Create external toolchain wrappers.
	mkdir -p ${BRTOOLDIR}/bin || die "cannot create ${BRTOOLDIR}/bin"
	for x in CC AR NM OBJCOPY; do
		maketoolwrapper true $x
	done
	for x in AS CXX LD OBJDUMP RANLIB READELF SIZE STRINGS STRIP; do
		maketoolwrapper false $x
	done

	# create a cpp wrapper, but run it via cc -E
	if [ "${CC_FLAVOR}" = 'clang' ]; then
		cppname=clang-cpp
	else
		cppname=cpp
	fi
	tname=${BRTOOLDIR}/bin/${MACHINE_GNU_ARCH}--${RUMPKERNEL}${TOOLABI}-${cppname}
	printf '#!/bin/sh\n\nexec %s -E -x c "${@}"\n' ${CC} > ${tname}
	chmod 755 ${tname}

	for x in 1 2 3; do
		! ${HOST_CC} -o ${BRTOOLDIR}/bin/brprintmetainfo \
		    -DSTATHACK${x} ${BRDIR}/brlib/utils/printmetainfo.c \
		    >/dev/null 2>&1 || break
	done
	[ -x ${BRTOOLDIR}/bin/brprintmetainfo ] \
	    || die failed to build brprintmetainfo

	${HOST_CC} -o ${BRTOOLDIR}/bin/brrealpath \
	    ${BRDIR}/brlib/utils/realpath.c || die failed to build brrealpath

	cat >> "${MKCONF}" << EOF
BUILDRUMP_IMACROS=${BRIMACROS}
.if \${BUILDRUMP_SYSROOT:Uno} == "yes"
BUILDRUMP_CPPFLAGS=--sysroot=\${BUILDRUMP_STAGE}
.else
BUILDRUMP_CPPFLAGS=-I\${BUILDRUMP_STAGE}/usr/include
.endif
BUILDRUMP_CPPFLAGS+=${EXTRA_CPPFLAGS}
LIBDO.pthread=_external
INSTPRIV=-U
AFLAGS+=-Wa,--noexecstack
MKPROFILE=no
MKARZERO=no
USE_SSP=no
MKHTML=no
MKCATPAGES=yes
MKNLS=no
RUMP_NPF_TESTING?=no
RUMPRUN=yes
EOF

	if ! ${KERNONLY}; then
		# queue.h is not available on all systems, but we need it for
		# the hypervisor build.  So, we make it available in tooldir.
		mkdir -p ${BRTOOLDIR}/compat/include/sys \
		    || die create ${BRTOOLDIR}/compat/include/sys
		cp -p ${SRCDIR}/sys/sys/queue.h ${BRTOOLDIR}/compat/include/sys
		echo "CPPFLAGS+=-I${BRTOOLDIR}/compat/include" >> "${MKCONF}"
	fi

	printoneconfig 'Cmd' "SRCDIR" "${SRCDIR}"
	printoneconfig 'Cmd' "DESTDIR" "${DESTDIR}"
	printoneconfig 'Cmd' "OBJDIR" "${OBJDIR}"
	printoneconfig 'Cmd' "BRTOOLDIR" "${BRTOOLDIR}"

	appendmkconf 'Cmd' "${RUMP_DIAGNOSTIC:-}" "RUMP_DIAGNOSTIC"
	appendmkconf 'Cmd' "${RUMP_DEBUG:-}" "RUMP_DEBUG"
	appendmkconf 'Cmd' "${RUMP_LOCKDEBUG:-}" "RUMP_LOCKDEBUG"
	appendmkconf 'Cmd' "${DBG:-}" "DBG"
	printoneconfig 'Cmd' "make -j[num]" "-j ${JNUM}"

	if ${KERNONLY}; then
		appendmkconf Cmd yes RUMPKERN_ONLY
	fi

	if ${KERNONLY} && ! cppdefines __NetBSD__; then
		appendmkconf 'Cmd' '-D__NetBSD__' 'CPPFLAGS' +
		appendmkconf 'Probe' "${RUMPKERN_UNDEF}" 'CPPFLAGS' +
	else
		appendmkconf 'Probe' "${RUMPKERN_UNDEF}" "RUMPKERN_UNDEF"
	fi
	appendmkconf 'Probe' "${RUMP_CURLWP:-}" 'RUMP_CURLWP' ?
	appendmkconf 'Probe' "${CTASSERT:-}" "CPPFLAGS" +
	appendmkconf 'Probe' "${RUMP_VIRTIF:-}" "RUMP_VIRTIF"
	appendmkconf 'Probe' "${EXTRA_CWARNFLAGS}" "CWARNFLAGS" +
	appendmkconf 'Probe' "${EXTRA_LDFLAGS}" "LDFLAGS" +
	appendmkconf 'Probe' "${EXTRA_CPPFLAGS}" "CPPFLAGS" +
	appendmkconf 'Probe' "${EXTRA_CFLAGS}" "BUILDRUMP_CFLAGS"
	appendmkconf 'Probe' "${EXTRA_AFLAGS}" "BUILDRUMP_AFLAGS"
	_tmpvar=
	for x in ${EXTRA_RUMPUSER} ${EXTRA_RUMPCOMMON}; do
		appendvar _tmpvar "${x#-l}"
	done
	appendmkconf 'Probe' "${_tmpvar}" "RUMPUSER_EXTERNAL_DPLIBS" +
	_tmpvar=
	for x in ${EXTRA_RUMPCLIENT} ${EXTRA_RUMPCOMMON}; do
		appendvar _tmpvar "${x#-l}"
	done
	appendmkconf 'Probe' "${_tmpvar}" "RUMPCLIENT_EXTERNAL_DPLIBS" +
	appendmkconf 'Probe' "${LDSCRIPT:-}" "RUMP_LDSCRIPT"
	appendmkconf 'Probe' "${SHLIB_MKMAP:-}" 'SHLIB_MKMAP'
	appendmkconf 'Probe' "${SHLIB_WARNTEXTREL:-}" "SHLIB_WARNTEXTREL"
	appendmkconf 'Probe' "${MKSTATICLIB:-}"  "MKSTATICLIB"
	appendmkconf 'Probe' "${MKPIC:-}"  "MKPIC"
	appendmkconf 'Probe' "${MKSOFTFLOAT:-}"  "MKSOFTFLOAT"
	appendmkconf 'Probe' $(${HAVECXX} && echo yes || echo no) _BUILDRUMP_CXX

	printoneconfig 'Mode' "${TARBALLMODE}" 'yes'

	rm -f ${BRTOOLDIR}/toolchain-conf.mk
	exec 3>&1 1>${BRTOOLDIR}/toolchain-conf.mk
	printf 'BUILDRUMP_TOOL_CFLAGS=%s\n' "${EXTRA_CFLAGS}"
	printf 'BUILDRUMP_TOOL_CXXFLAGS=%s\n' "${EXTRA_CFLAGS}"
	printf 'BUILDRUMP_TOOL_CPPFLAGS=-D__NetBSD__ %s %s\n' \
	    "${EXTRA_CPPFLAGS}" "${RUMPKERN_UNDEF}"
	exec 1>&3 3>&-

	chkcrt begins
	chkcrt ends
	chkcrt i
	chkcrt n

	# add vars from env last (so that they can be used for overriding)
	cat >> "${MKCONF}" << EOF
CPPFLAGS+=\${BUILDRUMP_CPPFLAGS}
CFLAGS+=\${BUILDRUMP_CFLAGS}
AFLAGS+=\${BUILDRUMP_AFLAGS}
LDFLAGS+=\${BUILDRUMP_LDFLAGS}
EOF

	if ! ${KERNONLY}; then
		echo >> "${MKCONF}"
		cat >> "${MKCONF}" << EOF
# Support for NetBSD Makefiles which use <bsd.prog.mk>
# It's mostly a question of erasing dependencies that we don't
# expect to see
.ifdef PROG
LIBCRT0=
LIBCRTBEGIN=
LIBCRTEND=
LIBCRTI=
LIBC=

LDFLAGS+= -L\${BUILDRUMP_STAGE}/usr/lib -Wl,-R${DESTDIR}/lib
LDADD+= ${EXTRA_RUMPCOMMON} ${EXTRA_RUMPUSER} ${EXTRA_RUMPCLIENT}
EOF
		appendmkconf 'Probe' "${LD_AS_NEEDED}" LDFLAGS +
		echo '.endif # PROG' >> "${MKCONF}"
	fi

	# skip the zlib tests run by "make tools", since we don't need zlib
	# and it's only required by one tools autoconf script.  Of course,
	# the fun bit is that autoconf wants to use -lz internally,
	# so we provide some foo which macquerades as libz.a.
	export ac_cv_header_zlib_h=yes
	echo 'int gzdopen(int); int gzdopen(int v) { return 0; }' > fakezlib.c
	${HOST_CC} -o libz.a -c fakezlib.c
	rm -f fakezlib.c

	# Run build.sh.  Use some defaults.
	# The html pages would be nice, but result in too many broken
	# links, since they assume the whole NetBSD man page set to be present.
	cd ${SRCDIR}

	# create user-usable wrapper script
	makemake ${BRTOOLDIR}/rumpmake ${BRTOOLDIR}/dest makewrapper

	# create wrapper script to be used during buildrump.sh, plus tools
	makemake ${RUMPMAKE} ${OBJDIR}/dest.stage tools

	# Just set no MSI in imacros universally now.
	# Need to:
	#   a) migrate more defines there
	#   b) set no MSI only when necessary
	printf '#define NO_PCI_MSI_MSIX\n' > ${BRIMACROS}.building

	unset ac_cv_header_zlib_h

	# tool build done.  flip mk.conf name so that it gets picked up
	omkconf="${MKCONF}"
	MKCONF="${mkconf_final}"
	mv "${omkconf}" "${MKCONF}"
	unset omkconf mkconf_final

	# set new BRIMACROS only if the contents change (avoids
	# full rebuild, since every file in the rump kernel depends on the
	# contents of BRIMACROS
	if ! diff "${BRIMACROS}" "${BRIMACROS}.building" > /dev/null 2>&1; then
		mv "${BRIMACROS}.building" "${BRIMACROS}"
	fi
}

builduserspace ()
{

	usermtree ${STAGING}

	LIBS="$(stdlibs ${RUMPSRC})"
	! ${HAVECXX} || LIBS="${LIBS} $(stdlibsxx ${RUMPSRC})"

	userincludes ${RUMPSRC} ${LIBS} $(pwd)/lib/librumprun_tester
	for lib in ${LIBS}; do
		makeuserlib ${lib}
	done
}

buildrump ()
{

	checktools
	checkprevbuilds

	extracflags=
	[ "${MACHINE_GNU_ARCH}" = "x86_64" ] \
	    && extracflags='-F CFLAGS=-mno-red-zone'

	# build tools
	${BUILDRUMP}/buildrump.sh ${BUILD_QUIET} ${STDJ} -k		\
	    -s ${RUMPSRC} -T ${RUMPTOOLS} -o ${BROBJ} -d ${STAGING}	\
	    -V MKPIC=no -V RUMP_CURLWP=__thread				\
	    -V RUMP_KERNEL_IS_LIBC=1 -V BUILDRUMP_SYSROOT=yes		\
	    ${extracflags} "$@" tools

	echo '>>'
	echo '>> Now that we have the appropriate tools, performing'
	echo '>> further setup for rumprun build'
	echo '>>'

	RUMPMAKE=$(pwd)/${RUMPTOOLS}/rumpmake

	TOOLTUPLE=$(${RUMPMAKE} -f bsd.own.mk \
	    -V '${MACHINE_GNU_PLATFORM:S/--netbsd/-rumprun-netbsd/}')

	[ $(${RUMPMAKE} -f bsd.own.mk -V '${_BUILDRUMP_CXX}') != 'yes' ] \
	    || HAVECXX=true

	makeconfig ${RROBJ}/config.mk ''
	makeconfig ${RROBJ}/config.sh \"
	# XXX: gcc is hardcoded
	cat > ${RROBJ}/config << EOF
export RUMPRUN_MKCONF="${RROBJ}/config.mk"
export RUMPRUN_SHCONF="${RROBJ}/config.sh"
export RUMPRUN_BAKE="${RRDEST}/bin/rumprun-bake"
export RUMPRUN_CC="${RRDEST}/bin/${TOOLTUPLE}-gcc"
export RUMPRUN_CXX="${RRDEST}/bin/${TOOLTUPLE}-g++"
export RUMPRUN="${RRDEST}/bin/rumprun"
export RUMPSTOP="${RRDEST}/bin/rumpstop"
EOF
	cat > "${RROBJ}/config-PATH.sh" << EOF
export PATH="${RRDEST}/bin:\${PATH}"
EOF
	export RUMPRUN_MKCONF="${RROBJ}/config.mk"

	probeprereqs

	cat >> ${RUMPTOOLS}/mk.conf << EOF
.if defined(LIB) && \${LIB} == "pthread"
.PATH:  $(pwd)/lib/librumprun_base/pthread
PTHREAD_MAKELWP=pthread_makelwp_rumprun.c
CPPFLAGS.pthread_makelwp_rumprun.c= -I$(pwd)/include
.endif  # LIB == pthread
EOF
	[ -z "${PLATFORM_MKCONF}" ] \
	    || echo "${PLATFORM_MKCONF}" >> ${RUMPTOOLS}/mk.conf

	echo "RUMPRUN_TUPLE=${TOOLTUPLE}" >> ${RUMPTOOLS}/mk.conf

	# build rump kernel
	${BUILDRUMP}/buildrump.sh ${BUILD_QUIET} ${STDJ} -k		\
	    -s ${RUMPSRC} -T ${RUMPTOOLS} -o ${BROBJ} -d ${STAGING}	\
	    "$@" build kernelheaders install

	echo '>>'
	echo '>> Rump kernel components built.  Proceeding to build'
	echo '>> rumprun bits'
	echo '>>'
}

buildpci ()
{

	if eval ${PLATFORM_PCI_P}; then
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} obj
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} dependall
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} install
	fi
}
