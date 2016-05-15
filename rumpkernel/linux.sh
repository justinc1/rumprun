BUILDLINUX=true


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

	CC=${BRTOOLDIR}/bin/${MACHINE_GNU_ARCH}--${RUMPKERNEL}${TOOLABI}-gcc

}

builduserspace ()
{
# build musl libc for Linux
(
	set -x
	set -e
	echo "=== building musl ==="
	abspath STAGING
	cd musl
	LKL_HEADER="${STAGING}/"
	CIRCLE_TEST_REPORTS="${CIRCLE_TEST_REPORTS-./}"
	./configure --with-lkl=${LKL_HEADER} --disable-shared --enable-debug \
		    --disable-optimize --prefix=${STAGING}/
	# XXX: bug of musl Makefile ?
	make obj/src/internal/version.h
	make install
	# install libraries
# 	${INSTALL-install} -d ${STAGING}/usr/lib
# 	${INSTALL-install} ${BROBJ}/musl/lib/libpthread.a \
# 			   ${BROBJ}/musl/lib/libcrypt.a \
# 			   ${BROBJ}/musl/lib/librt.a \
# 			   ${BROBJ}/musl/lib/libm.a \
# 			   ${BROBJ}/musl/lib/libdl.a \
# 			   ${BROBJ}/musl/lib/libutil.a \
# 			   ${BROBJ}/musl/lib/libresolv.a \
# 			   ${STAGING}/usr/lib
)

}

buildrump()
{
# required by app-tools build (XXX: should be removed if it's not needed)
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
	    -V '${MACHINE_GNU_PLATFORM:S/--linux/-rumprun-linux/}')

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

# end of FIXME

	set -e
	${BUILDRUMP}/buildrump.sh ${BUILD_QUIET} ${STDJ} -k \
		-s ${RUMPSRC} -o ${BROBJ} -d ${STAGING} \
		-V RUMP_CURLWP=hypercall -V RUMP_LOCKS_UP=yes \
		-V MKPIC=no -V RUMP_KERNEL_IS_LIBC=1 \
		-F CFLAGS=-fno-stack-protector \
		-l ${LKLSRC} linuxbuild install



# XXX:, FIXME
	mkdir -p ${STAGING}/bin
	mkdir -p ${STAGING}/include
	mkdir -p ${RUMPTOOLS}/dest/usr/lib
	mkdir -p ${RUMPTOOLS}/dest/usr/include/rumprun
	ln -s -f ${RUMPSRC}/sys/rump/include/rump/ ${STAGING}/include/

}

buildpci ()
{
	echo '>>'
	echo '>> Build PCI stuff'
	echo '>>'

	if eval ${PLATFORM_PCI_P}; then
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} obj
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} dependall
	fi

	abspath BROBJ
	abspath STAGING

	HYPERCALLS=
	if [ ${PLATFORM} = "hw" ] ; then
	    HYPERCALLS="${BROBJ}/sys/rump/dev/lib/libpci/rumppci.o ${BROBJ}/sys/rump/dev/lib/libpci/rumpdma.o"
	else
	    HYPERCALLS="${BROBJ}/sys/rump/dev/lib/libpci/rumphyper_pci.o ${BROBJ}/sys/rump/dev/lib/libpci/rumphyper_dma.o"
	fi
	make RUMP_BMK_PCI_HYPERCALLS="${HYPERCALLS}" -C ${LKLSRC}/arch/lkl/drivers/
	make RUMP_BMK_PCI_HYPERCALLS="${HYPERCALLS}" -C ${LKLSRC}/arch/lkl/drivers/ \
	     DESTDIR=${STAGING} install

}
