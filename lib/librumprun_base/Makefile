LIB=		rumprun_base

SRCS=		main.c rumprun.c
SRCS+=		parseargs.c config.c
SRCS+=		malloc.c
SRCS+=		__errno.c libc_stubs.c
SRCS+=		daemon.c syscall_misc.c
SRCS+=		sysproxy.c

.if ${RUMPKERNEL} == "netbsd"
SRCS+=		netbsd_initfini.c signals.c
SRCS+=		_lwp.c
SRCS+=		syscall_mman.c

# doesn't really belong here, but at the moment we don't have
# a rumpkernel-only "userspace" lib
SRCS+=		platefs.c

INCS=		platefs.h
INCSDIR=	/usr/include/rumprun
.else
SRCS+=		linux_initfini.c
.include "${.CURDIR}/pthread/Makefile.inc"
CFLAGS+=	-DCONFIG_LKL -DMUSL_LIBC -include ${.CURDIR}/../../rumpkernel/linux.h
.endif

WARNS=		5

CPPFLAGS+=	-I${.CURDIR}/../../include
CPPFLAGS+=	-D_KERNTYPES

.include <bsd.lib.mk>
