builduserspace ()
{
# build musl libc for Linux
(
	set -x
	set -e
	echo "=== building musl ==="
	abspath STAGING
	cd musl
	LKL_HEADER="${RROBJ}/dest.stage"
	CIRCLE_TEST_REPORTS="${CIRCLE_TEST_REPORTS-./}"
	./configure --with-lkl=${LKL_HEADER} --disable-shared --enable-debug \
		    --disable-optimize --prefix=${STAGING}/ CFLAGS="-DRUMPRUN"
	# XXX: bug of musl Makefile ?
	make obj/src/internal/version.h
	make install
)
}


buildpci ()
{
	echo '>>'
	echo '>> Build PCI stuff'
	echo '>>'

	# XXX:, FIXME: LKL still needs librumpuser from src-netbsd
	mkdir -p ${STAGING}/../include/
	ln -s -f ${RUMPSRC}/sys/rump/include/rump/ ${STAGING}/../include/
	cp -rpf ${RUMPSRC}/sys/rump/include/rump/ ${STAGING}/include/

	# XXX:
	mkdir -p ${RROBJ}/rumptools/dest/usr/include/sys/
	cp include/bmk-core/queue.h ${RROBJ}/rumptools/dest/usr/include/sys/

	CFLAGS="-I ./include -I ${PLATFORMDIR}/include/ -I ${PLATFORMDIR}/xen/include/ -I ${RUMPTOOLS}/../include/ -I${LKLSRC}/arch/lkl/drivers"
	abspath BROBJ
	abspath STAGING

	HYPERCALLS=
	if [ ${PLATFORM} = "hw" ] ; then
		${CC:-cc} ${CFLAGS} ${PLATFORMDIR}/pci/rumppci.c -c -o ${BROBJ}/rumppci.o
		${CC:-cc} ${CFLAGS} ${PLATFORMDIR}/pci/rumpdma.c -c -o ${BROBJ}/rumpdma.o
		HYPERCALLS="${BROBJ}/rumppci.o ${BROBJ}/rumpdma.o"
	else
		${CC:-cc} ${CFLAGS} ${PLATFORMDIR}/pci/rumphyper_pci.c -c -o ${BROBJ}/rumphyper_pci.o
		${CC:-cc} ${CFLAGS} ${PLATFORMDIR}/pci/rumphyper_dma.c -c -o ${BROBJ}/rumphyper_dma.o
		HYPERCALLS="${BROBJ}/rumphyper_pci.o ${BROBJ}/rumphyper_dma.o"
	fi
	make RUMP_BMK_PCI_HYPERCALLS="${HYPERCALLS}" -C ${LKLSRC}/arch/lkl/drivers/
	make RUMP_BMK_PCI_HYPERCALLS="${HYPERCALLS}" -C ${LKLSRC}/arch/lkl/drivers/ \
	     DESTDIR=${RROBJ}/rumptools/dest/usr install

}
