include ../../global.mk
include ${BUILDRUMP_TOOLFLAGS}

CFLAGS+=	${BUILDRUMP_TOOL_CFLAGS}

LDFLAGS:= -L$(abspath ../../rumprun/rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM})
LDFLAGS+= -L${RROBJ}/lib/libcompiler_rt

CPPFLAGS+= -I../../include -I../../rumprun/rumprun-${MACHINE_GNU_ARCH}/include
CPPFLAGS+= -I../../platform/${PLATFORM}/include

LDSCRIPT= ${RROBJ}/bmk.ldscript

LDFLAGS+= ${LDFLAGS.${MACHINE_GNU_ARCH}.${PLATFORM}}

SRCS= main.c main-net.c
OBJS= $(patsubst %.c,%.o, $(SRCS)) ${RROBJ}/rumprun.o
KERNELS= $(patsubst %.c,%.elf, $(SRCS))

LIB_RUMP_NET= -lrumpnet -lrumpnet_net -lrumpnet_netinet -lrumpnet_config
LIB_RUMP= -lrumpvfs -lrump $(LIB_RUMP_NET)

# Linux libos
LINUX?=no
ifeq (${LINUX},yes)
LDFLAGS+=-Wl,--unresolved-symbols=ignore-in-object-files
CFLAGS+= -g -O0 -DLINUX_RUMP
LIB_RUMP=-llkl
LIB_RUMP+=-lrumpdev_pci
endif

.PHONY: clean

all: ${KERNELS}

${KERNELS}: ${OBJS}

%.o : %.c
	${CC} ${CFLAGS} ${CPPFLAGS} -c $<

%.elf: %.o
	${CC} ${CFLAGS} ${LDFLAGS} -T${LDSCRIPT} 			\
	$< ${RROBJ}/rumprun.o						\
	-nostdlib							\
	-Wl,--whole-archive ${LIB_RUMP} -Wl,--no-whole-archive		\
	-lcompiler_rt 							\
	-o $@

clean:
	rm -rf main.o main.elf
