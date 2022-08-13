;--------------------------------------------------------------------------
;File Name     		: grove_4_digit_display.asm
;Version 			: 1.0
;Created Date		: 19/11/2016
;Last Update		: 19/12/2016
;Authors   			: Tan Chee Phang, Dr. Fakhrul Zaman Rokhani
;Description		: Procedures to control Grove 4-Digit Display 
;					  Connect Data line (white wire) to IO 2
;					  Connect Clock line (yellow wire) to IO 3	
;--------------------------------------------------------------------------	


%include "..\ASM Macro\galileo_gen_1.mac"		;include macro library
%include "..\ASM Macro\grove_rgb_lcd.mac"		;include macro library

Extern delay, delay_2us, delay_3us, delay_5us, delay_1_53ms, delay_39us, delay_long, delay_short
Global display_4_digit

;-------------------------------------------------------------------------- code section
SECTION .text


;-------------------------------------------------------------------------- 
;display BX register value (eg. 0x1234) to Grove 4-digit display 
;-------------------------------------------------------------------------- 
display_4_digit:
push eax
push edx
push ebx
push ebx


call i2c_start						;set command data
mov edx, 0x00000040
call i2c_write
call i2c_ask
call i2c_stop


call i2c_start						;send to command data to command register
mov edx, 0x000000c0
call i2c_write
call i2c_ask

 
pop ebx 

call  change_format
rol edx, 8 
call hex_2_seven_segment_display
call i2c_write						;start sending the LSB of BX register
call i2c_ask


ror edx, 16							;sending the second byte of BX register
call hex_2_seven_segment_display

;or edx, 0x80						;uncomment to enable colon 
call i2c_write
call i2c_ask

ror edx, 16

call hex_2_seven_segment_display	;sending the third byte of BX register
call i2c_write
call i2c_ask

ror edx, 16
call hex_2_seven_segment_display	;sending the MSB of BX register
call i2c_write
call i2c_ask
call i2c_stop


call i2c_start						;set the brightness of the 4-digit display
mov edx, 0x0000008f
call i2c_write
call i2c_ask
call i2c_stop
	


pop ebx
pop edx 
pop eax

ret



;-------------------------------------------------------------------------- 
;control Data and Clock line individually
;--------------------------------------------------------------------------
dio_1:										; set GPIO 6 -> HIGH	(DATA line = 1)
push eax
mov eax , [gpio_bar + GPIO_SWPORTA_DR]		;check the last written data
or eax, 0x00000040 							;just switch on the GPIO 6
mov [gpio_bar + GPIO_SWPORTA_DR]	, eax 	;to control GPIO[7:0], GPIO_6 ON
pop eax
ret



dio_0:										; set GPIO 6 -> LOW		(DATA line = 0)
push eax
mov eax , [gpio_bar + GPIO_SWPORTA_DR]
and eax, 0x000000bf 
mov [gpio_bar + GPIO_SWPORTA_DR]  	, eax 	;to control GPIO[7:0], GPIO_6 OFF
pop eax
ret


clk_1:										; set GPIO 7 -> HIGH	(CLOCK line = 1)
push eax
mov  eax , [gpio_bar + GPIO_SWPORTA_DR]
or   eax, 0x00000080 
mov  [gpio_bar + GPIO_SWPORTA_DR]	, eax 	;to control GPIO[7:0], GPIO_7 ON
pop  eax
ret




clk_0:										; set GPIO 7 -> LOW		(CLOCK line = 0)
push eax
mov eax , [gpio_bar + GPIO_SWPORTA_DR]
and eax, 0x0000007f 
mov [gpio_bar + GPIO_SWPORTA_DR]	, eax	;to control GPIO[7:0], GPIO_7 OFF
pop eax
ret
;-------------------------------------------------------------------------- 







;-------------------------------------------------------------------------- 	
;control Data and Clock line together
;-------------------------------------------------------------------------- 	
clk_0_dio_0:											; (CLOCK = 0, DATA = 0)
mov [gpio_bar + GPIO_SWPORTA_DR]	, dword 0x00000000 	; GPIO 6 -> LOW and GPIO 7 -> LOW
ret


clk_0_dio_1:											; (CLOCK = 1, DATA = 0)
mov [gpio_bar + GPIO_SWPORTA_DR]	, dword 0x00000040 	; GPIO 6 -> HIGH and GPIO 7 -> LOW
ret


clk_1_dio_0:											; (CLOCK = 0, DATA = 1)
mov [gpio_bar + GPIO_SWPORTA_DR]	, dword 0x00000080 	; GPIO 6 -> LOW and GPIO 7 -> HIGH
ret

clk_1_dio_1:											; (CLOCK = 1, DATA = 1)
mov [gpio_bar + GPIO_SWPORTA_DR]	, dword 0x000000c0 	; GPIO 6 -> HIGH and GPIO 7 -> HIGH
ret
;-------------------------------------------------------------------------- 



;-------------------------------------------------------------------------- send start command
i2c_start:

call clk_1_dio_0
call clk_1_dio_1
call delay_2us
call clk_1_dio_0
ret




;-------------------------------------------------------------------------- send stop command
i2c_stop:

call clk_0
call delay_2us
call clk_0_dio_0
call delay_2us
call clk_1_dio_0
call delay_2us
call clk_1_dio_1
ret



;-------------------------------------------------------------------------- check whether TM1637 device receive the data successfully 
i2c_ask:   

call clk_0
call delay_5us


mov [gpio_bar + GPIO_SWPORTA_DDR]	, dword 0x000000bf	;to control GPIO[7:0]  , GPIO_6 changed to input


mov ecx, 0x0000f0000  									; number of loop to check for DIO low, 
														;jump to _start to restart the program if no reply from TM1637 device
.l1: 

mov eax , [gpio_bar + GPIO_EXT_PORTA]
and eax, 0x00000040

jz .cont
loop .l1
mov [gpio_bar + GPIO_SWPORTA_DDR]	, dword 0x000000ff 	;change back all port as output
mov [gpio_bar + GPIO_SWPORTA_DR]	, dword 0x00000000 	;to control GPIO[7:0], All OFF 		;pull down DIO before reset again
call delay_5us
ret

.cont:

mov [gpio_bar + GPIO_SWPORTA_DDR]	, dword 0x000000ff 	;change back all port as output

call clk_1_dio_0  										;straight away assign DIO to zero, no need to check the previous port register
call delay_2us
call clk_0_dio_0

ret




;--------------------------------------------------------------------------  write 8 bits data to TM1637 device
i2c_write:

mov ecx, 0x00000008


l2: 
push ecx
push edx

call clk_0

and  edx, 0x00000001
jz j1
call dio_1
jmp j2
j1: call dio_0

j2:
call delay_3us


pop edx

shr edx, 1
call clk_1
call delay_3us

pop ecx
loop l2 
ret



;-------------------------------------------------------------------------- change the hex to seven segment display format
hex_2_seven_segment_display:
push edx
cmp dl,  0x00
pop edx
jnz con_1
and edx,  0xffffff00
or  edx,  0x0000003f	;0
ret

con_1: 
push edx
cmp dl,  0x01
pop edx
jnz con_2
and edx,  0xffffff00
or  edx,  0x00000006	;1
ret

con_2: 
push edx
cmp dl,  0x02
pop edx
jnz con_3
and edx,  0xffffff00
or  edx,  0x0000005b	;2
ret

con_3: 
push edx
cmp dl,  0x03
pop edx
jnz con_4
and edx,  0xffffff00
or  edx,  0x0000004f	;3
ret

con_4: 
push edx
cmp dl,  0x04
pop edx
jnz con_5
and edx,  0xffffff00
or  edx,  0x00000066	;4
ret

con_5: 
push edx
cmp dl,  0x05
pop edx
jnz con_6
and edx,  0xffffff00
or  edx,  0x0000006d	;5
ret

con_6: 
push edx
cmp dl,  0x06
pop edx
jnz con_7
and edx,  0xffffff00
or  edx,  0x0000007d	;6
ret

con_7: 
push edx
cmp dl,  0x07
pop edx
jnz con_8
and edx,  0xffffff00
or  edx,  0x00000007	;7
ret

con_8: 
push edx
cmp dl,  0x08
pop edx
jnz con_9
and edx,  0xffffff00
or  edx,  0x0000007f	;8
ret

con_9: 
push edx
cmp dl,  0x09
pop edx
jnz con_a
and edx,  0xffffff00
or  edx,  0x0000006f	;9
ret

con_a: 
push edx
cmp dl,  0x0a
pop edx
jnz con_b
and edx,  0xffffff00
or  edx,  0x00000077	;a
ret

con_b: 
push edx
cmp dl,  0x0b
pop edx
jnz con_c
and edx,  0xffffff00
or  edx,  0x0000007c	;b
ret

con_c: 
push edx
cmp dl,  0x0c
pop edx
jnz con_d
and edx,  0xffffff00
or  edx,  0x00000039	;c
ret

con_d: 
push edx
cmp dl,  0x0d
pop edx
jnz con_e
and edx,  0xffffff00
or  edx,  0x0000005e	;d
ret

con_e: 
push edx
cmp dl,  0x0e
pop edx
jnz con_f
and edx,  0xffffff00
or  edx,  0x00000079	;e
ret

con_f: 
push edx
cmp dl,  0x0f
pop edx
and edx,  0xffffff00
or  edx,  0x00000071	;f
ret


						
						

;-------------------------------------------------------------------------- 
;change the format before calling the hex_2_seven_segment_display
;-------------------------------------------------------------------------- 
change_format:		; 0x1234 -> 0x01020304

push ebx
 
and ebx, 0xf
or edx, ebx
ror edx, 8
pop ebx
 
shr ebx, 4
 
push ebx
 
and ebx, 0xf
or edx, ebx
ror edx, 8
pop ebx

shr ebx, 4
 
push ebx
 
and ebx, 0xf
or edx, ebx
ror edx, 8
pop ebx
 
shr ebx, 4

and ebx, 0xf
or edx, ebx
ror edx, 8

ret
