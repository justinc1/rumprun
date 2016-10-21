include ../Makefile.inc

ALL=tls_test.bin ctor_test.bin pthread_test.bin misc_test.bin
ifeq (${RUMPKERNEL},linux)
ALL=tls_test.bin ctor_test.bin pthread_test.bin
endif

all: $(ALL)

clean:
	rm -f $(ALL)
