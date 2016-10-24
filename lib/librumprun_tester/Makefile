LIB=		rumprun_tester
INCS=		tester.h
INCSDIR=	/usr/include/rumprun
.if ${RUMPKERNEL} == "linux"
BINOWN=		${USER}
BINGRP=		${USER}
CFLAGS+=	-nostdinc -Wno-parentheses -I${DESTDIR}/usr/include
.endif

SRCS=		rumprun_tester.c

.include <bsd.lib.mk>
