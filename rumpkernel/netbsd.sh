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

buildpci ()
{

	if eval ${PLATFORM_PCI_P}; then
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} obj
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} dependall
		${RUMPMAKE} -f ${PLATFORMDIR}/pci/Makefile.pci ${STDJ} install
	fi
}
