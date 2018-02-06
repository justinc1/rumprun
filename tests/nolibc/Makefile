include ../../global.mk
include ${BUILDRUMP_TOOLFLAGS}

CFLAGS+=	${BUILDRUMP_TOOL_CFLAGS}

LDFLAGS:= -L${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}
LDFLAGS+= -L${RROBJ}/lib/libcompiler_rt

CPPFLAGS+= -I../../include -I${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/include
CPPFLAGS+= -I../../platform/${PLATFORM}/include

LDSCRIPT= ${RROBJ}/bmk.ldscript

LDFLAGS+= ${LDFLAGS.${MACHINE_GNU_ARCH}.${PLATFORM}}

OBJS= main.o ${RROBJ}/rumprun.o

ifeq (${RUMPKERNEL},netbsd)
LIB_RUMP= -lrumpvfs -lrump
LIB_EXTRA=-lcompiler_rt
else ifeq (${RUMPKERNEL},linux)
CFLAGS+= -DLINUX_RUMP -Wno-error=strict-prototypes
LIB_RUMP=-llkl
endif

.PHONY: clean

main.elf: ${OBJS}
	${CC} ${CFLAGS} ${LDFLAGS} -T${LDSCRIPT} 			\
	${OBJS} 							\
	-nostdlib							\
	-Wl,--whole-archive ${LIB_RUMP} -Wl,--no-whole-archive		\
	${LIB_EXTRA}							\
	-o $@

clean:
	rm -rf main.o main.elf
