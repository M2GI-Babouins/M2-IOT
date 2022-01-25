/*
 * Define the entry point in the code, see startup.s
 */
ENTRY(_entry)
/*
 * Define the different sections included in the ELF file.
 */
SECTIONS
{
  /*
   * Since we are loaded by Qemu, as a kernel, we are loaded at 0x10000.
   * For simplicity, we consider that we will be linked at the same address,
   * in order to avoid a relocation of the code at each boot.
   */ 
  . = 0x10000; 
  _load = .;
  . = 0x10000; 
  _start = .;
  /*
   * Make sure here that we have the code defined in startup.s 
   * at the beginning of the binary, when this ELF is translated
   * to pure binary by the objcopy tool. 
   * See the makefile for how objcopy is used to translate an ELF into a binary,
   * that can be loaded by QEMU.
   */
 .startup . : { startup.o(.text) }
 /*
  * Now include the other sections of code.
  */
 .text : { *(.text) }
 /*
  * Include the initialized data sections
  */
 .data : { *(.data) }
  /*
  * Include the data sections that must be zeroed upon starting up.
  * Align the section on a 4byte boundary, it is cleaner and more
  * efficient for an ARM processor. Especially that we do not enable
  * unaligned accesses in memory by the ARM processor.
  * Look at the startup code to see how memory is reset to zero
  * between _bss_start and _bss_end
  * NOTA BENE: 
  *   we zero 16 bytes at a time (look at the code in startup.s
  *   so we align this section on 16-byte boundaries, both the start
  *   and end.
  */ 
 .bss : {
   . = ALIGN(16); 
   _bss_start = .;
   bss = .;
   *(.bss COMMON)
   . = ALIGN(16); 
   _bss_end = .;
 } 
 /* 
  * Finally, reserve some memory for the C stack
  * Remember that stacks are growing downward, 
  * so the top of the stack is at the end of 
  * the reserved memory region. 
  * NOTA BENE: 
  *    there are no runtime checks to check that 
  *    your stack does not overflow at runtime when
  *    nesting too many C function calls. 
  */
 . = ALIGN(8);
 . = . + 0x1000; /* 4kB of stack memory */
 stack_top = .;
}
