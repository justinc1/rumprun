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
		(
			cd ${PLATFORMDIR}/pci
			${RUMPMAKE} ${STDJ} obj
			${RUMPMAKE} ${STDJ} dependall
			${RUMPMAKE} ${STDJ} install
		)
	fi
}
