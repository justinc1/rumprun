#include <stdio.h>
#include <bmk-core/core.h>
#include <bmk-core/sched.h>

void *rumprun_thread_gettcb(void);
void rumprun_thread_join(void *);
void *rumprun_thread_create_withtls(int (*)(void *), void *,
				    void *, int, void *);
void rumprun_thread_exit_withtls(void)  __attribute__((__noreturn__));

void *
rumprun_thread_gettcb(void)
{
	return bmk_sched_gettcb();
}

void
rumprun_thread_join(void *tid)
{
	return bmk_sched_join((struct bmk_thread *)tid);
}

void *
rumprun_thread_create_withtls(int (*func)(void *), void *arg,
			      void *stack, int stack_size, void *tls)
{
	int jointable = 1;

	return bmk_sched_create_withtls("__clone", NULL, jointable,
					(void (*)(void *))func, arg,
					stack, stack_size, tls);
}

void
rumprun_thread_exit_withtls(void)
{
	bmk_sched_exit_withtls();
}

