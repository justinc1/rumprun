include ../Makefile.inc

ALL=tls_test.bin ctor_test.bin pthread_test.bin
ifeq (${RUMPKERNEL},netbsd)
ALL+=misc_test.bin
endif

all: $(ALL)

clean:
	rm -f $(ALL)
