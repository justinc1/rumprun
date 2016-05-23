LIB=		rumprun_tester
INCS=		tester.h
INCSDIR=	/usr/include/rumprun
BINOWN=		${USER}
BINGRP=		${USER}
CFLAGS+=	-nostdinc -Wno-parentheses -I${DESTDIR}/usr/include

SRCS=		rumprun_tester.c

.include <bsd.lib.mk>
