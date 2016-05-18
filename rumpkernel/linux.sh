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


buildpci ()
{
	echo '>>'
	echo '>> Build PCI stuff'
	echo '>>'

	# XXX:, FIXME: LKL still needs librumpuser from src-netbsd
	ln -s -f ${RUMPSRC}/../src-netbsd/sys/rump/include/rump/ ${STAGING}/../include/
	cp -rpf ${RUMPSRC}/../src-netbsd/sys/rump/include/rump/ ${STAGING}/include/


	CFLAGS="-I ./include -I ${PLATFORMDIR}/include/ -I ${RUMPTOOLS}/../include/ -I${LKLSRC}/arch/lkl/drivers"
	abspath BROBJ
	abspath STAGING

	HYPERCALLS=
	if [ ${PLATFORM} = "hw" ] ; then
		${CC} ${CFLAGS} ${PLATFORMDIR}/pci/rumppci.c -c -o ${BROBJ}/rumppci.o
		${CC} ${CFLAGS} ${PLATFORMDIR}/pci/rumpdma.c -c -o ${BROBJ}/rumpdma.o
		HYPERCALLS="${BROBJ}/rumppci.o ${BROBJ}/rumpdma.o"
	else
		${CC} ${CFLAGS} ${PLATFORMDIR}/pci/rumphyper_pci.c -c -o ${BROBJ}/rumphyper_pci.o
		${CC} ${CFLAGS} ${PLATFORMDIR}/pci/rumphyper_dma.c -c -o ${BROBJ}/rumphyper_dma.o
		HYPERCALLS="${BROBJ}/rumphyper_pci.o ${BROBJ}/rumphyper_dma.o"
	fi
	make RUMP_BMK_PCI_HYPERCALLS="${HYPERCALLS}" -C ${LKLSRC}/arch/lkl/drivers/
	make RUMP_BMK_PCI_HYPERCALLS="${HYPERCALLS}" -C ${LKLSRC}/arch/lkl/drivers/ \
	     DESTDIR=${STAGING}/usr install

}
