#include "main.h"
#include "isr.h"

volatile unsigned char text [2000];
volatile unsigned int pos = 0;
volatile unsigned int maxpos = 0;


/**
 * Receive a character from the given uart, this is a non-blocking call.
 * Returns 0 if there are no character available.
 * Returns 1 if a character was read.
 */
int uart_receive(int uart, unsigned char *s)
{
  unsigned short *uart_fr = (unsigned short *)(uart + UART_FR);
  unsigned short *uart_dr = (unsigned short *)(uart + UART_DR);
  //while (*uart_fr & UART_RXFE) ;

  *s = (*uart_dr & 0xff);

  return *s != 0;
}

/**
 * Sends a character through the given uart, this is a blocking call.
 * The code spins until there is room in the UART TX FIFO queue to send
 * the character.
 */
void uart_send(int uart, unsigned char s)
{
  unsigned short *uart_fr = (unsigned short *)(uart + UART_FR);
  unsigned short *uart_dr = (unsigned short *)(uart + UART_DR);
  while (*uart_fr & UART_TXFF)
    ;
  *uart_dr = s;
}

/**
 * This is a wrapper function, provided for simplicity,
 * it sends a C string through the given uart.
 */
void uart_send_string(int uart, const unsigned char *s)
{
  while (*s != '\0')
  {
    uart_send(uart, *s);
    s++;
  }
}

void uart_left(int uart)
{
  if(pos==0)
    return;
  uart_send(uart, '\b');
  pos --;
}

void uart_right(int uart)
{
    if(pos < maxpos)
      uart_send(uart, text[pos++]);
}

void uart_back(int uart)
{
  if(pos==0)
    return;

  uart_left(uart);
  uart_send(uart, ' ');
  text[pos++] = ' ';
  uart_left(uart);
}

void uart_del(int uart)
{
  if(pos==maxpos)
    return;
  uart_send(uart, ' ');
  text[pos++] = ' ';
  uart_left(uart);

}


unsigned int machine = 0;
void interpreter(unsigned char c)
{

  if(machine != 0){
    if(machine == 27 && c == 91){
      machine = c;
      return;       
    }
    if(machine == 91){
      if(c == 67)
        uart_right(UART0);
      if(c== 68)
        uart_left(UART0);
      if(c==51){
        machine = c;
        return ;
      }
    }

    if(machine == 51 && c == 126){
      uart_del(UART0);
    }
    machine = 0;
    return;
  }

  // Retour chariot
  if (c == 13)
  {
    uart_send(UART0, '\r');
    uart_send(UART0, '\n');
    if(pos == maxpos)
      maxpos ++;
    text[pos++] = c;
    return;
  }

  // Backspace
  if (c == 127)
  {
    uart_back(UART0);
    return;
  }

  if(c == 27){
    machine = 27;
  }else{
    if(pos == maxpos)
      maxpos ++;
    text[pos++] = c;
    uart_send(UART0, c);
    //kprintf("%d", c);
  }



}

/*
 * Define ECHO_ZZZ to have a periodic reminder that this code is polling
 * the UART, actively. This means the processor is running continuously.
 * Polling is of course not the way to go, the processor should halt in
 * a low-power state and wake-up only to handle an interrupt from the UART.
 * But this would require setting up interrupts...
 */
//#define ECHO_ZZZ

/**
 * This is the C entry point, upcalled once the hardware has been setup properly
 * in assembly language, see the startup.s file.
 */
void c_entry()
{
  _irqs_setup();
  irq_isr_setup(UART0);
  _irqs_enable();


  uart_send_string(UART0, "\nHello world!\n");
  uart_send_string(UART0, "\nQuit with \"C-a c\" and then type in \"quit\".\n");

  while (1) {
      unsigned char c = buf_get();

      while(c != 0){
        interpreter(c);
        c =  buf_get();
      }
      _wfi();
  }
}
