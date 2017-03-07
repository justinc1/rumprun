#include <stdio.h>

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


void _linux_userlevel_init(void);
void _linux_userlevel_init(void)
{
	static char dummy_argv[16] = "rumprun-lkl";
	static char *initial_env[] = {
		NULL,
	};

	__init_libc(initial_env, dummy_argv);
	libc_start_init_priv();
}
