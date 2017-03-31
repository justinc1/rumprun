#!/bin/sh

##
## This is a file for matrix build configuration on Circle CI.
## Since circle.yml is hard to write down multi-line case statement,
## we use this external file for this
##

case $CIRCLE_NODE_INDEX in
    0)
	echo "hw-linux"
	echo "export PLATFORM=hw; export MACHINE=x86_64; export TESTS=qemu;\
 export KERNONLY=; export EXTRAFLAGS=; export RUMPKERN='-r linux'" >> $HOME/.bashrc
	# FIXME: some tests are still failing with linux
	echo "export TEST_LESS=1" >> $HOME/.bashrc
	;;
    1)
	echo "hw-netbsd"
	echo "export PLATFORM=hw; export MACHINE=x86_64; export TESTS=qemu;\
 export KERNONLY=; export EXTRAFLAGS=; export RUMPKERN='-r netbsd'" >> $HOME/.bashrc
	;;
    2)
	echo "hw kernonly-linux"
	echo "export PLATFORM=hw; export MACHINE=x86_64; export TESTS=none;\
export KERNONLY=-k; export EXTRAFLAGS=; export RUMPKERN='-r linux'" >> $HOME/.bashrc
	;;
    3)
	echo "hw kernonly-netbsd"
	echo "export PLATFORM=hw; export MACHINE=x86_64; export TESTS=none;\
 export KERNONLY=-k; export EXTRAFLAGS=; export RUMPKERN='-r netbsd'" >> $HOME/.bashrc
	;;
    # The followings are not yet supported for Linux kernel build
    4)
	echo "xen"
	echo "export PLATFORM=xen; export MACHINE=x86_64; export TESTS=none;\
 export KERNONLY=; export EXTRAFLAGS=; export RUMPKERN='-r linux'" >> $HOME/.bashrc
	;;
    5)
	echo "xen i486"
	echo "export PLATFORM=xen; export MACHINE=i486; export ELF=elf; export TESTS=none;\
 export KERNONLY=; export EXTRAFLAGS='-- -F ACLFLAGS=-m32'; export RUMPKERN='-r linux'" >> $HOME/.bashrc
	;;
    6)
	echo "hw i486"
	echo "export PLATFORM=hw; export MACHINE=i486; export ELF=elf; export TESTS=qemu;\
 export KERNONLY=; export EXTRAFLAGS='-- -F ACLFLAGS=-m32 -F ACLFLAGS=-march=i686'; export RUMPKERN='-r linux'" >> $HOME/.bashrc
	;;
esac

echo "export CC=gcc-4.8" >> $HOME/.bashrc
echo "export CXX=g++-4.8" >> $HOME/.bashrc

