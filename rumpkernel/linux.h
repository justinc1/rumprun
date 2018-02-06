#ifdef __linux__

#ifndef __dead
#define __dead
#endif

#ifndef __printflike
#define __printflike(x, y)
#endif

#ifndef __unused
//#define __unused __attribute__((__unused__))
#endif

#define        INFTIM          -1
#define        _DIAGASSERT(x)  assert(x)

#ifndef __arraycount
#define __arraycount(_ar_) (sizeof(_ar_)/sizeof(_ar_[0]))
#endif

#define __UNCONST(x) ((void *)(unsigned long)(x))
#define __predict_false(x) (x)
#define __predict_true(x) (x)

#ifndef _STRING
#define        _STRING(x)      x
#endif

#ifndef __strong_alias
#define        __strong_alias(alias,sym)		       \
	__asm(".global " _STRING(#alias) "\n"		       \
	      _STRING(#alias) " = " _STRING(#sym));
#endif

#ifndef __weak_alias
#define        __weak_alias(alias,sym)		       \
	__asm(".weak " _STRING(#alias) "\n"	       \
	      _STRING(#alias) " = " _STRING(#sym));
#endif

#ifndef __BEGIN_DECLS
#define __BEGIN_DECLS
#endif
#ifndef __END_DECLS
#define __END_DECLS
#endif

#ifndef roundup2
#define        roundup2(x,m)   ((((x) - 1) | ((m) - 1)) + 1)
#endif

#endif	/* __linux__ */
