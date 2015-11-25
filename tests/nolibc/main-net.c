#include <bmk-core/errno.h>
#include <bmk-core/mainthread.h>
#include <bmk-core/printf.h>
#include <bmk-core/string.h>

#include "nolibc.h"

#include <rump/rump.h>
#ifdef LINUX_RUMP
#include <linux/reboot.h>
#include <linux/time.h>
#define AF_INET6 10

#include <linux/rump_syscalls.h>

int lkl_if_up(int ifindex);
int lkl_if_set_ipv4(int ifindex, unsigned int addr, unsigned int netmask_len);
int lkl_sys_socket(int, int, int);

#else
#include <rump/rump_syscalls.h>
#include <rump/netconfig.h>
#undef  __RENAME
#include <sys/timespec.h>
#endif


struct sockaddr {
#ifndef LINUX_RUMP
	__uint8_t	sa_len;
#endif
	__uint8_t	sa_family;
	__uint16_t	sa_port;
	char		sa_data[16 - sizeof(__uint8_t) - sizeof(__uint16_t)];
};

static ssize_t
writestr(int fd, const char *str)
{
	return rump_sys_write(fd, str, bmk_strlen(str));
}

#define SEND_COUNT       10
static void
send_packet(void)
{
	int sock, ret;
	char buf[16] = "0123456789012345";
	struct sockaddr sin;
	int i = 0;

#ifdef LINUX_RUMP
	lkl_if_up(1);		/* lo */
	lkl_if_up(2);		/* eth0 */
	lkl_if_set_ipv4(2, 0x0100000a, 24);/* 10.0.0.1 */
#else
	int rv;
	/* Virtio ether */
	char *ifname = "vioif0";

	if ((rv = rump_pub_netconfig_dhcp_ipv4_oneshot(ifname)) != 0)
		bmk_printf("configuring dhcp for %s failed: %d\n",
			   ifname, rv);

	if ((rv =rump_pub_netconfig_ipv6_ifaddr(ifname,
						"2001::1", 64)) != 0)
		bmk_printf("configuring v6addr for %s failed: %d\n",
			   ifname, rv);
#endif

	sock = rump_sys_socket(RUMP_AF_INET, RUMP_SOCK_DGRAM, RUMP_IPPROTO_UDP);
	if (sock < 0) {
		bmk_printf("socket error %d\n", *bmk_sched_geterrno());
		return;
	}

	long dest = 0x0200000a; /* 10.0.0.2 */

	bmk_memset(&sin, 0, sizeof(sin));
#ifndef LINUX_RUMP
	sin.sa_len = sizeof(sin);	/* FIXME */
#endif
	sin.sa_family = RUMP_AF_INET;
	sin.sa_port = 3939;
	bmk_memcpy(sin.sa_data, &dest, sizeof(dest));

	while (i < SEND_COUNT) {
		struct timespec ts = {0, 1000*1000*10};

		if ((ret = rump_sys_sendto(sock, buf, sizeof(buf), 0,
					   (struct sockaddr *)&sin,
					   sizeof(sin))) <= 0) {
			bmk_printf("socket write error %d\n", *bmk_sched_geterrno());
		}
		else
			bmk_printf("socket write success !! written %d\n", ret);
		i++;

		rump_sys_nanosleep(&ts, 0);
	}

	return;
}

extern char *boot_cmdline;
void
bmk_mainthread(void *cmdline)
{
	int rv, fd;

#ifdef LINUX_RUMP
	boot_cmdline = "loglevel=7";
#endif
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

	send_packet();
	bmk_printf("sleeping 1 secs\n");
	struct timespec ts = {1, 0};
	rump_sys_nanosleep(&ts, 0);

#ifdef LINUX_RUMP
	rump_sys_reboot(LINUX_REBOOT_MAGIC1,
			LINUX_REBOOT_MAGIC2,
			LINUX_REBOOT_CMD_RESTART,
			(void *)"reboot");
#else
	rump_sys_reboot(0,0);
#endif
}
