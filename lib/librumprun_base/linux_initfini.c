#include <stdio.h>
#include <string.h>
#include <elf.h>
#include <bmk-core/core.h>
#include <bmk-core/sched.h>

#include "rumprun-private.h"

#if ULONG_MAX == 0xffffffff
typedef Elf32_Phdr Phdr;
#else
typedef Elf64_Phdr Phdr;
#endif

void _init(void);
void __init_libc(char **envp, char *pn);

typedef void (*initfini_fn)(void);
extern const initfini_fn __init_array_start;
extern const initfini_fn __init_array_end;

static void libc_start_init_priv(void)
{
	_init();
	const initfini_fn *a = &__init_array_start;
	for (; a < &__init_array_end; a++)
		(*a)();
}

struct initinfo {
	char *argv_dummy;
	char *env_dummy;
	size_t auxv[8];
} __attribute__((__packed__));

static char *initial_env[] = {
	NULL,
};

extern const char _tdata_start[], _tdata_end[];
extern const char _tbss_start[], _tbss_end[];


void _linux_userlevel_init(void)
{
	static struct initinfo ii;
	Phdr phdr;
	int idx = 0;

	ii.argv_dummy = strdup("rumprun-lkl");
	ii.env_dummy = initial_env[0];

	/* Handling TLS: minimal setup for TLS data access */
	phdr.p_type = PT_TLS;
	phdr.p_vaddr = (uintptr_t)_tdata_start;
	phdr.p_memsz = _tbss_end - _tdata_start;
	phdr.p_filesz = _tdata_end - _tdata_start;
	phdr.p_align = sizeof(uintptr_t);

	ii.auxv[idx++] = AT_PHDR;
	ii.auxv[idx++] = (uintptr_t)&phdr;
	ii.auxv[idx++] = AT_PHNUM;
	ii.auxv[idx++] = 1;
	ii.auxv[idx++] = AT_NULL;
	ii.auxv[idx++] = 0;

	__init_libc(&ii.env_dummy, ii.argv_dummy);
	libc_start_init_priv();
}
