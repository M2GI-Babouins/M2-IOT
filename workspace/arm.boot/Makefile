
QEMU=qemu-system-arm

TOOLCHAIN=arm-none-eabi

ASFLAGS= -mcpu=arm926ej-s -g 
CFLAGS= -c -mcpu=arm926ej-s -g -nostdlib
LDFLAGS= -T kernel.ld -g -nostdlib

MACHINE=versatilepb
#MACHINE=versatileab

MEMORY=1M

# Notice that we link with our own linker script: test.ld
all: exception.o startup.o main.o
	$(TOOLCHAIN)-ld $(LDFLAGS) exception.o startup.o main.o -o kernel.elf
	$(TOOLCHAIN)-objcopy -O binary kernel.elf kernel.bin

clean: 
	rm -f startup.o test.o kernel.elf 

exception.o : exception.s
	$(TOOLCHAIN)-as $(ASFLAGS) exception.s -o exception.o

startup.o: startup.s
	$(TOOLCHAIN)-as $(ASFLAGS) startup.s -o startup.o

main.o: main.c
	$(TOOLCHAIN)-gcc $(CFLAGS) main.c -o main.o



#run: all
#	$(QEMU) -M $(MACHINE) -m $(MEMORY) -nographic -kernel kernel.bin -serial mon:stdio

#debug: all
#	$(QEMU) -M $(MACHINE) -m $(MEMORY) -nographic -kernel kernel.bin -serial mon:stdio -gdb tcp::1234 -S

run: all
	$(QEMU) -M $(MACHINE) -m $(MEMORY) -nographic -serial mon:stdio -device loader,file=kernel.elf

debug: all
	$(QEMU) -M $(MACHINE) -m $(MEMORY) -nographic -serial mon:stdio  -device loader,file=kernel.elf -gdb tcp::1234 -S

kill:
	pkill qemu-system-arm

