#!/bin/sh

##
## Currently only qemu test is implemented
##

set -e

[ -n "${RUMPRUN_SHCONF}" ] || { echo '>> need RUMPRUN_SHCONF'; exit 1; }
. "${RUMPRUN_SHCONF}"

export PATH="${PATH}:${RRDEST}/bin"

TESTS=$1

if [ ${TESTS} != qemu ]; then
    echo "`basename $0`: unrecognized option ${TESTS}"
    echo "`basename $0` qemu is only supported."
    exit 0
fi

cd $(dirname $0)
rumprun qemu -M 512 -g "-nographic -vga none" -i main.elf </dev/null &> log.txt &

sleep 5
kill %1 || echo "ignore errors"
cat log.txt

