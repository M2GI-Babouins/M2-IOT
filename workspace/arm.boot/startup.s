.global _entry
_entry:
 ldr sp, =stack_top

	/*--------------------------------------------------------------
	 * we're loaded at _load and we need to relocate
	 * the code to _start, but only if _load and _start are different.
	 *
	 * This is not used in our case because we load and link at the same
	 * address. But sometimes, the code is loaded at a place that is just
	 * not cool to keep. It could be in ROM/EPROM/FLASH to start with,
	 * which is read only. This would obviously require to relocate
	 * the code, not so much because it is read-only but because
	 * ROM/EPROM/FLASH is really slow memory.
	 *
	 * Sometimes, it is just that the loader uses a fixed address that
	 * is not convenient. For instance, the load address of 0x10000
	 * might be too low in memory and we may want to relocate the code
	 * and data towards the end of memory, towards high addresses.
	 *-------------------------------------------*/
.relocate:
	ldr     r3,=_load 
	ldr	r4, =_start
	cmp     r3,r4
	beq     .clear
	ldr	r9, =_bss_start 
1:
	ldmia	r3!, {r5-r8} // load multiple from r3
	stmia	r4!, {r5-r8} // store multiple at r4

	cmp	r4, r9 // are we done yet?
	blo	1b

	/*-------------------------------------------
	 * Clear out the bss section, located from _bss_start to _bss_end.
	 * This is a C convention, the GNU GCC compiler will group all global variables
	 * that need to be zeroed on startup in the bss section of the ELF.
	 *-------------------------------------------*/
.clear:
	ldr	r4, =_bss_start
	ldr	r9, =_bss_end
	mov	r5, #0
1:
	stmia	r4!, {r5} 
	cmp	r4, r9
	blo	1b

 	/*
 	 * Now upcall the C entry function, c_entry(void)
 	 */
    bl c_entry
_halt:
	b	_halt

