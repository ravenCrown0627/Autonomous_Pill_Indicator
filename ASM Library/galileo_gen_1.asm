;--------------------------------------------------------------------------
;File Name     		: galileo_gen_1.asm
;Version 			: 1.1
;Created Date		: 28/11/2016
;Last Update		: 16/12/2016
;Authors   			: Tan Chee Phang, Dr. Fakhrul Zaman Rokhani
;Description		: Procedures for delay functions and i2c controller checking function 	 	
;
;--------------------------------------------------------------------------	


%include "..\ASM Macro\galileo_gen_1.mac"		;include macro library

Global check 
Global delay, delay_2us, delay_3us, delay_5us, delay_1_53ms, delay_39us, delay_long, delay_short



Section .text
; --------------------------------------------------------------------------
check:									;check to make sure i2c controller TX buffer not overflow
push ebx
.l1:									;local label
mov ebx, [i2c_bar+ IC_RAW_INTR_STAT]
and ebx, 0x00000010 					;mask for TX_EMPTY
jz .l1
pop ebx			
ret



;--------------------------------------------------------------------------delay functions
delay:
push ecx
mov ecx, 0x00ff0000   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret


delay_long:
push ecx
mov ecx, 0x02c5c430   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret


delay_short:
push ecx
mov ecx, 0x000f0000   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret


delay_2us:
push ecx
mov ecx, 0x0049   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret



delay_3us:
push ecx
mov ecx, 0x007f   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret



delay_5us:
push ecx
mov ecx, 0x00e0   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret


delay_39us:
push ecx
mov ecx, 0x0AB0   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret


delay_1_53ms:
push ecx
mov ecx, 0x3f900   ;loop NOP to delay 
.l1: nop
loop .l1
pop ecx
ret
;--------------------------------------------------------------------------