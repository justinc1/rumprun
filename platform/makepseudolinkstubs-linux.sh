#!/bin/sh

TMP=$1

cat << EOF > ${TMP}
int *__errno(void) __attribute__((weak));
int *__errno(void)
{
	return 0;
}


int rumpuser_thread_create(void *(*f)(void *), void *arg, const char *thrname,
	int joinable, int pri, int cpuidx, void **tptr) __attribute__((weak));
int rumpuser_thread_create(void *(*f)(void *), void *arg, const char *thrname,
	int joinable, int pri, int cpuidx, void **tptr)
{
	return 0;
}

void rumpuser_thread_set_cookie(void *thread, void *cookie) __attribute__((weak));
void rumpuser_thread_set_cookie(void *thread, void *cookie)
{
}

void *rumpuser_thread_get_cookie(void) __attribute__((weak));
void *rumpuser_thread_get_cookie(void)
{
	return 0;
}

void *realloc(void *p, int n) __attribute__((weak));
void *realloc(void *p, int n)
{
	return 0;
}

void *calloc(int m, int n) __attribute__((weak));
void *calloc(int m, int n)
{
	return 0;
}

void free(void *cp) __attribute__((weak));
void free(void *cp)
{
}

long lkl_syscall(long no, long *params) __attribute__((weak));
long lkl_syscall(long no, long *params)
{
	return 0;
}

void _start(void);
void _start(void)
{
}

void __dead _exit(int);
void __dead _exit(int)
{
}

EOF
