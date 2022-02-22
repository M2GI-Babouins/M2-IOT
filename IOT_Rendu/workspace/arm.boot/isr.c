#include "isr.h"
#include "main.h"

int uart;


void irq_isr_setup(int _uart){
    uart = _uart;
  int* uart_addr = (int*)(uart + UART_IMSC);
  *(uart_addr) = UART_IMSC_TXIM;
  int* vic_addr = (int*)(VIC_BASE_ADDR + VICINTENABLE);
  *(vic_addr) = (UART0_VIC_IRQ_MASK);
}


volatile unsigned char buffer[MAX_CHARS];
volatile int head = 0;
volatile int tail = 0;

int buf_put(unsigned char item){
  if(tail+1 == head)
    return 0;

  buffer[tail++] = item;
  tail%= MAX_CHARS;

  return 1;
}

unsigned char buf_get(){
  if(head == tail)
    return 0;

  unsigned char item = buffer[head++];
  head %= MAX_CHARS;
  return item;
}



void isr(){
  unsigned char c; 
  int have_next = uart_receive(uart, &c);

  if (!have_next){
    //erreur
    return;
  }


  while(have_next){
    if(!buf_put(c))
      return;
      
    have_next = uart_receive(uart, &c);
  }

}
