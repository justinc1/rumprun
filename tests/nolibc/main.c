#include <bmk-core/errno.h>
#include <bmk-core/mainthread.h>
#include <bmk-core/printf.h>
#include <bmk-core/string.h>

#include "nolibc.h"

#include <rump/rump.h>
#ifdef LINUX_RUMP
#include <linux/reboot.h>
#include <lkl.h>
#define rump_sys_write lkl_sys_write
#define rump_sys_open lkl_sys_open
#define rump_sys_reboot lkl_sys_reboot
#include "stub.c"
#else
#include <rump/rump_syscalls.h>
#endif

static ssize_t
writestr(int fd, const char *str)
{
	return rump_sys_write(fd, str, bmk_strlen(str));
}

void
bmk_mainthread(void *cmdline)
{
	int rv, fd;

	rv = rump_init();
	bmk_printf("rump kernel init complete, rv %d\n", rv);

	writestr(1, "Hello, stdout!\n");

	bmk_printf("open(/notexisting): ");
	fd = rump_sys_open("/notexisting", 0, 0);
	if (fd == -1) {
		int errno = *bmk_sched_geterrno();
		if (errno == RUMP_ENOENT) {
			bmk_printf("No such file or directory. All is well.\n");
		} else {
			bmk_printf("Something went wrong. errno = %d\n", errno);
		}
	} else {
		bmk_printf("Success?! fd=%d\n", fd);
	}

#ifdef LINUX_RUMP
	rump_sys_reboot(LINUX_REBOOT_MAGIC1,
			LINUX_REBOOT_MAGIC2,
			LINUX_REBOOT_CMD_RESTART,
			(void *)"reboot");
#else
	rump_sys_reboot(0,0);
#endif
}
