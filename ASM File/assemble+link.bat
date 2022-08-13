nasm -f elf autonomous_pill_indicator.asm 

ld -o "..\ELF Files"\autonomous_pill_indicator.elf -T ..\link.x autonomous_pill_indicator.o "..\ASM Library"\grove_rgb_lcd_lib.o "..\ASM Library"\cyp_io_expander.o "..\ASM Library"\galileo_gen_1.o 

pause

