#include "main.h"

/**
 * Receive a character from the given uart, this is a non-blocking call.
 * Returns 0 if there are no character available.
 * Returns 1 if a character was read.
 */
int uart_receive(int uart, unsigned char *s) {
  unsigned short* uart_fr = (unsigned short*) (uart + UART_FR);
  unsigned short* uart_dr = (unsigned short*) (uart + UART_DR);
  if (*uart_fr & UART_RXFE)
    return 0;
  *s = (*uart_dr & 0xff);
  return 1;
}

/**
 * Sends a character through the given uart, this is a blocking call.
 * The code spins until there is room in the UART TX FIFO queue to send
 * the character.
 */
void uart_send(int uart, unsigned char s) {
  unsigned short* uart_fr = (unsigned short*) (uart + UART_FR);
  unsigned short* uart_dr = (unsigned short*) (uart + UART_DR);
  while (*uart_fr & UART_TXFF)
    ;
  *uart_dr = s;
}

/**
 * This is a wrapper function, provided for simplicity,
 * it sends a C string through the given uart.
 */
void uart_send_string(int uart, const unsigned char *s) {
  while (*s != '\0') {
    uart_send(uart, *s);
    s++;
  }
}

/*
 * Define ECHO_ZZZ to have a periodic reminder that this code is polling
 * the UART, actively. This means the processor is running continuously.
 * Polling is of course not the way to go, the processor should halt in
 * a low-power state and wake-up only to handle an interrupt from the UART.
 * But this would require setting up interrupts...
 */
#define ECHO_ZZZ

/**
 * This is the C entry point, upcalled once the hardware has been setup properly
 * in assembly language, see the startup.s file.
 */
void c_entry() {
  int i = 0;
  int count = 0;
  uart_send_string(UART0, "\nHello world!\n");
  uart_send_string(UART0, "\nQuit with \"C-a c\" and then type in \"quit\".\n");
  while (1) {
    unsigned char c;
#ifdef ECHO_ZZZ
    while (0 == uart_receive(UART0, &c)) {
      count++;
      if (count > 50000000) {
        uart_send_string(UART0, "\n\rZzzz....\n\r");
        count = 0;
      }
    }
#else
    if (0==uart_receive(UART0,&c))
    continue;
#endif
    if (c == 13) {
      uart_send(UART0, '\r');
      uart_send(UART0, '\n');
    } else {
      uart_send(UART0, c);
    }
  }
}
