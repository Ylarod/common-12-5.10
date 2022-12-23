/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _LINUX_VERMAGIC_H
#define _LINUX_VERMAGIC_H

#ifndef INCLUDE_VERMAGIC
#error "This header can be included from kernel/module.c or *.mod.c only"
#endif

#include <generated/utsrelease.h>
#include <asm/vermagic.h>

/* Simply sanity version stamp for modules. */
#ifdef CONFIG_SMP
#define MODULE_VERMAGIC_SMP "SMP "
#else
#define MODULE_VERMAGIC_SMP ""
#endif
#ifdef CONFIG_PREEMPT
#define MODULE_VERMAGIC_PREEMPT "preempt "
#elif defined(CONFIG_PREEMPT_RT)
#define MODULE_VERMAGIC_PREEMPT "preempt_rt "
#else
#define MODULE_VERMAGIC_PREEMPT ""
#endif
#ifdef CONFIG_MODULE_UNLOAD
#define MODULE_VERMAGIC_MODULE_UNLOAD "mod_unload "
#else
#define MODULE_VERMAGIC_MODULE_UNLOAD ""
#endif
#ifdef CONFIG_MODVERSIONS
#define MODULE_VERMAGIC_MODVERSIONS "modversions "
#else
#define MODULE_VERMAGIC_MODVERSIONS ""
#endif
#ifdef RANDSTRUCT_PLUGIN
#include <generated/randomize_layout_hash.h>
#define MODULE_RANDSTRUCT_PLUGIN "RANDSTRUCT_PLUGIN_" RANDSTRUCT_HASHED_SEED
#else
#define MODULE_RANDSTRUCT_PLUGIN
#endif

#define VERMAGIC_STRING 						\
	UTS_RELEASE " "							\
	MODULE_VERMAGIC_SMP MODULE_VERMAGIC_PREEMPT 			\
	MODULE_VERMAGIC_MODULE_UNLOAD MODULE_VERMAGIC_MODVERSIONS	\
	MODULE_ARCH_VERMAGIC						\
	MODULE_RANDSTRUCT_PLUGIN

#undef VERMAGIC_STRING
#define VERMAGIC_STRING "5.10.101-android12-9-00001-gf4c0e37dbcde-ab8596533 SMP preempt mod_unload modversions aarch64"

#undef VERMAGIC_STRING
#define VERMAGIC_STRING "5.10.43-android12-9-gb8e472053352-ab8059253 SMP preempt mod_unload modversions aarch64"
#endif /* _LINUX_VERMAGIC_H */
