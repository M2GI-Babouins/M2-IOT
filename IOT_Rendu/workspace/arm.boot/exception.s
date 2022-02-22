/*
 * exception.s
 *
 *  Created on: Jan 24, 2021
 *      Author: ogruber
 */

 LDR PC, reset_handler_addr
 LDR PC, undef_handler_addr
 LDR PC, swi_handler_addr
 LDR PC, prefetch_abort_handler_addr
 LDR PC, data_abort_handler_addr
 B .
 LDR PC, irq_handler_addr
 LDR PC, fiq_handler_addr

reset_handler_addr: .word _entry
undef_handler_addr: .word _undef_handler
swi_handler_addr: .word _swi_handler
prefetch_abort_handler_addr: .word _prefetch_abort_handler
data_abort_handler_addr: .word _data_abort_handler
irq_handler_addr: .word _isr
fiq_handler_addr: .word _fisr

/*
 * ARM11 MPCore Processor Technical Reference Manual
 * Page 159, Control Coprocessor CP15, Wait for interrupt
 *
 * (1) Puts the ARM into a low power state and stops it executing further until 
 *  an interrupt, or a debug request, occurs. Interrupt and debug events
 *  always cause the ARM processor to restart, irrespective of whether 
 *  the interrupt is masked. 
 *  (2) When an interrupt does occur, the MCR instruction completes and either
 *  the next instruction executes (if an interrupt event and the interrupt is
 *  masked), or the IRQ or FIQ handler is entered as normal. The return link
 *  in R14_irq or R14_fiq contains the address of the MCR instruction plus
 *  8, so that the normal instruction used for interrupt return is LR-4
 *  returns to the instruction following the MCR.
 */
.global _wfi
	.func _wfi
_wfi:
	MCR p15,0,r0,c7,c0,4
	mov pc,lr
    .size   _wfi, . - _wfi
	.endfunc

/*
 * Initial setup for handling interrupts on the processor
 * It is about setting up the stack for the interrupt mode.
 */
.global _irqs_setup
	.func _irqs_setup
_irqs_setup:
    /* get Program Status Register */
    mrs r0, cpsr
    /* go in IRQ mode */
    bic r1, r0, #0x1F
    orr r1, r1, #0x12
    msr cpsr, r1
    /* set IRQ stack */
    ldr sp, =irq_stack_top
    /* go back in Supervisor mode */
    msr cpsr, r0
    mov pc,lr
    .size   _irqs_setup, . - _irqs_setup
	.endfunc

/*
 * Enable all interrupts at the processor.
 */
.global _irqs_enable
	.func _irqs_enable
_irqs_enable:
    /* get Program Status Register */
    mrs r0, cpsr
    /* Enable IRQs on the processor by clearing the mask bit
     * The BIC (BIt Clear) instruction performs an AND operation
     * with the complements of the given contants #0x80.
     */
    bic r0, r0, #0x80
    /* go back in Supervisor mode */
    msr cpsr, r0
    mov pc,lr
    .size   _irqs_enable, . - _irqs_enable
	.endfunc

/*
 * Disable all interrupts at the processor and
 * at the processor only, the VIC is still managing
 * interrupts. When the interrupts will be turned back
 * on, the VIC will interrupt the processor if they are
 * pending interrupts.
 */
.global _irqs_disable
	.func _irqs_disable
_irqs_disable:
    /* get Program Status Register */
    mrs r0, cpsr
    /* Disable IRQs on the processor */
    orr r0, r0, #0x80
    /* go back in Supervisor mode */
    msr cpsr, r0
    mov pc,lr
    .size   _irqs_disable, . - _irqs_disable
	.endfunc

/*
 * The processor jumps here, in interrupt mode, when it decides
 * to handle an interrupt request from the VIC.
 * The fact that we use (LR-4) as the return address comes from
 * the processor pipeline that induces LR to be the address of
 * interrupted instruction plus 8.
 * So LR-8 would re-execute the instruction, usefull for handling
 * traps, such as handling page faults which requires re-executing
 * the instruction that trapped once the page table has been fixed.
 * LR-4 executes the next instruction, which is the normal behavior
 * for interrupts.
 * Nota Bene:
 *   The '^' symbol at the end of the last LDMFD instruction
 *   means that the CPSR will be restored from the save SPSR.
 *   The '^' restores the saved SPSR only if the PC is loaded
 *   by the LDMFD instruction.
 *   CPSR: Current Program Status Register
 *   SPSR: Saved Program Status Register
 */
_isr:
	sub lr,lr,#4
	stmfd sp!, {r0-r12,lr}
	bl isr
	ldmfd sp!, {r0-r12,pc}^

_fisr:
	b _panic // unexpected fast interrupt

_undef_handler:
	b _panic // unexpected trap for an undefined instruction

_swi_handler:
	b _panic  // unexpected software interrupt

_prefetch_abort_handler:
	b _panic  // unexpected prefetch-abort trap

_data_abort_handler:
	b _panic  // unexpected abort trap

.global _panic
_panic:
	b _panic


