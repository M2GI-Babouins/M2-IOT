#pragma once

/*
* UARTICR : Interrupt Clear Register
* Write only, 11 lower bits
* Write High bits clear register
*/
#define UART_ICR 0x44

/*
* UART_IMSC : Interrupt Mask Set/Clear
*/
#define UART_IMSC 0x038
#define UART_IMSC_TXIM (1<<4)

/*
*  IRQ
*/
#define UART0_IRQ 12

/*
* VIC
*/
#define VIC_BASE_ADDR 0x10140000
#define VICINTENABLE 0x010
#define UART0_VIC_IRQ_MASK (1<<UART0_IRQ)



#define MAX_CHARS 512

extern volatile unsigned char buffer[MAX_CHARS];
extern volatile int head;
extern volatile int tail;

void irq_isr_setup(int uart);
void isr();

int buf_put(unsigned char item);
unsigned char buf_get();
