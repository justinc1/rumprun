/*
 * XXX:
 *
 * Stub function definitions which LKL _accidentally_ uses
 * and should not be used
 */

#include <stdarg.h>

/* setjmp */
	__asm__(
".global __setjmp\n"
".global _setjmp\n"
".global setjmp\n"
".type __setjmp,@function\n"
".type _setjmp,@function\n"
".type setjmp,@function\n"
"__setjmp:\n"
"_setjmp:\n"
"setjmp:\n"
	"mov %rbx,(%rdi);"         /* rdi is jmp_buf, move registers onto it */
	"mov %rbp,8(%rdi)\n"
	"mov %r12,16(%rdi)\n"
	"mov %r13,24(%rdi)\n"
	"mov %r14,32(%rdi)\n"
	"mov %r15,40(%rdi)\n"
	"lea 8(%rsp),%rdx\n"        /* this is our rsp WITHOUT current ret addr */
	"mov %rdx,48(%rdi)\n"
	"mov (%rsp),%rdx\n"         /* save return addr ptr for new rip */
	"mov %rdx,56(%rdi)\n"
	"xor %rax,%rax\n"           /* always return 0 */
	"ret\n"
			);

/* longjmp */
__asm__(
".global _longjmp\n"
".global longjmp\n"
".type _longjmp,@function\n"
".type longjmp,@function\n"
"_longjmp:\n"
"longjmp:\n"
	"mov %rsi,%rax\n"           /* val will be longjmp return */
	"test %rax,%rax\n"
	"jnz 1f\n"
	"inc %rax\n"                /* if val==0, val=1 per longjmp semantics */
"1:\n"
	"mov (%rdi),%rbx\n"         /* rdi is the jmp_buf, restore regs from it */
	"mov 8(%rdi),%rbp\n"
	"mov 16(%rdi),%r12\n"
	"mov 24(%rdi),%r13\n"
	"mov 32(%rdi),%r14\n"
	"mov 40(%rdi),%r15\n"
	"mov 48(%rdi),%rdx\n"       /* this ends up being the stack pointer */
	"mov %rdx,%rsp\n"
	"mov 56(%rdi),%rdx\n"       /* this is the instruction pointer */
	"jmp *%rdx\n"               /* goto saved address without altering rsp */
			);

int rumpns_vsscanf(const char *buf, const char *fmt, va_list args);
int __isoc99_sscanf(const char *buf, const char *fmt, ...);
int __isoc99_sscanf(const char *buf, const char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	i = rumpns_vsscanf(buf, fmt, args);
	va_end(args);

	return i;
}

int rumpns_snprintf(char *buf, size_t size, const char *fmt, ...);
int snprintf(char *buf, size_t size, const char *fmt, ...);
int snprintf(char *buf, size_t size, const char *fmt, ...)
{
	return rumpns_snprintf(buf, size, fmt);
}

int rumpns_vsnprintf(char *buf, size_t size, const char *fmt, __builtin_va_list args);
int vsnprintf(char *buf, size_t size, const char *fmt, __builtin_va_list args);
int vsnprintf(char *buf, size_t size, const char *fmt, __builtin_va_list args)
{
	return rumpns_vsnprintf(buf, size, fmt, args);
}

void *rumpns_memcpy(void *dest, const void *src, size_t count);
void *memcpy(void *dest, const void *src, size_t count);
void *memcpy(void *dest, const void *src, size_t count)
{
	return rumpns_memcpy(dest, src, count);
}

int rumpns_memcmp(const void *cs, const void *ct, size_t count);
int memcmp(const void *cs, const void *ct, size_t count);
int memcmp(const void *cs, const void *ct, size_t count)
{
	return rumpns_memcmp(cs, ct, count);
}

void *rumpns_memset(void *s, int c, size_t count);
void *memset(void *s, int c, size_t count);
void *memset(void *s, int c, size_t count)
{
	return rumpns_memset(s, c, count);
}

char *rumpns_strncat(char *dest, const char *src, size_t count);
char *strncat(char *dest, const char *src, size_t count);
char *strncat(char *dest, const char *src, size_t count)
{
	return rumpns_strncat(dest, src, count);
}

size_t rumpns_strlen(const char *s);
size_t strlen(const char *s);
size_t strlen(const char *s)
{
	return rumpns_strlen(s);
}

char *rumpns_strcpy(char *dest, const char *src);
char *strcpy(char *dest, const char *src);
char *strcpy(char *dest, const char *src)
{
	return rumpns_strcpy(dest, src);
}

char *rumpns_strncpy(char *dest, const char *src, size_t count);
char *strncpy(char *dest, const char *src, size_t count);
char *strncpy(char *dest, const char *src, size_t count)
{
	return rumpns_strncpy(dest, src, count);
}

int rumpns_strncmp(const char *cs, const char *ct, size_t count);
int strncmp(const char *cs, const char *ct, size_t count);
int strncmp(const char *cs, const char *ct, size_t count)
{
	return rumpns_strncmp(cs, ct, count);
}

char *rumpns_strchr(const char *s, int c);
char *strchr(const char *s, int c);
char *strchr(const char *s, int c)
{
	return rumpns_strchr(s, c);
}


size_t rumpns_strspn(const char *s, const char *accept);
size_t strspn(const char *s, const char *accept);
size_t strspn(const char *s, const char *accept)
{
	return rumpns_strspn(s, accept);
}

size_t rumpns_strcspn(const char *s, const char *reject);
size_t strcspn(const char *s, const char *reject);
size_t strcspn(const char *s, const char *reject)
{
	return rumpns_strcspn(s, reject);
}

char *strtok(char *restrict s, const char *restrict sep);
char *strtok(char *restrict s, const char *restrict sep)
{
	static char *p;
	if (!s && !(s = p)) return NULL;
	s += strspn(s, sep);
	if (!*s) return p = 0;
	p = s + strcspn(s, sep);
	if (*p) *p++ = 0;
	else p = 0;
	return s;
}

char *getenv(const char *name);
char *getenv(const char *name)
{
	/* not supported */
	return NULL;
}

unsigned long rumpns_simple_strtoul(const char *, char **, unsigned int);
unsigned long strtoul(const char *restrict s, char **restrict p, int base);
unsigned long strtoul(const char *restrict s, char **restrict p, int base)
{
	return rumpns_simple_strtoul(s, p, base);
}

int	rumpuser_sp_init(const char *a,
			 const char *b, const char *c, const char *d)
	 __attribute__((weak));
int	rumpuser_sp_init(const char *a,
			 const char *b, const char *c, const char *d)
{
	return 0;
}

int	rumpuser_sp_copyin(void *a, const void *b, void *c, size_t d)
	 __attribute__((weak));
int	rumpuser_sp_copyin(void *a, const void *b, void *c, size_t d)
{
	return 0;
}

int	rumpuser_sp_copyout(void *a, const void *b, void *c, size_t d)
	 __attribute__((weak));
int	rumpuser_sp_copyout(void *a, const void *b, void *c, size_t d)
{
	return 0;
}

void	rumpuser_sp_fini(void *a)
	 __attribute__((weak));
void	rumpuser_sp_fini(void *a)
{
}
