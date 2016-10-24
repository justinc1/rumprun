LIB=		rumprun_base

SRCS=		main.c rumprun.c
SRCS+=		parseargs.c config.c
SRCS+=		malloc.c
SRCS+=		__errno.c libc_stubs.c
SRCS+=		daemon.c

.if ${RUMPKERNEL} == "netbsd"
SRCS+=		netbsd_initfini.c signals.c
SRCS+=		_lwp.c
SRCS+=		syscall_mman.c syscall_misc.c
SRCS+=		sysproxy.c

# doesn't really belong here, but at the moment we don't have
# a rumpkernel-only "userspace" lib
SRCS+=		platefs.c

INCS=		platefs.h
INCSDIR=	/usr/include/rumprun
.else
CFLAGS+=	-DCONFIG_LKL -DMUSL_LIBC
.endif

WARNS=		5

CPPFLAGS+=	-I${.CURDIR}/../../include
CPPFLAGS+=	-D_KERNTYPES

.include <bsd.lib.mk>
