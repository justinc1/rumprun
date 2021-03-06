include ../../global.mk
include ${BUILDRUMP_TOOLFLAGS}

CFLAGS+=	${BUILDRUMP_TOOL_CFLAGS}

LDFLAGS:= -L${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}
LDFLAGS+= -L${RROBJ}/lib/libcompiler_rt

CPPFLAGS+= -I../../include -I${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/include
CPPFLAGS+= -I../../include -I${RRDEST}/usr/include
CPPFLAGS+= -I../../platform/${PLATFORM}/include

LDSCRIPT= ${RROBJ}/bmk.ldscript

LDFLAGS+= ${LDFLAGS.${MACHINE_GNU_ARCH}.${PLATFORM}}

SRCS= main.c main-net.c
OBJS= $(patsubst %.c,%.o, $(SRCS)) ${RROBJ}/rumprun.o
KERNELS= $(patsubst %.c,%.elf, $(SRCS))

ifeq (${RUMPKERNEL},netbsd)
LIB_RUMP_NET= -lrumpnet -lrumpnet_net -lrumpnet_netinet -lrumpnet_config
LIB_RUMP_PCI= -lrumpdev_pci_virtio -lrumpdev_virtio_if_vioif -lrumpdev_pci -lrumpdev
LIB_RUMP= -lrumpvfs -lrump $(LIB_RUMP_NET) $(LIB_RUMP_PCI)
LIB_EXTRA=-lcompiler_rt
# Linux LKL
else
CFLAGS+= -g -O0 -DLINUX_RUMP -Wno-error=strict-prototypes
LDFLAGS+= -L${RRDEST}/usr/lib
LIB_RUMP=-llkl
LIB_RUMP+=-lrumpdev_linux_pci
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
	${LIB_EXTRA}							\
	-o $@

clean:
	rm -f *.o *.elf
