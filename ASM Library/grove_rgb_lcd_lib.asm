;--------------------------------------------------------------------------
;File Name     		: grove_rgb_lcd_lib.asm
;Version 			: 1.1
;Created Date		: 28/11/2016
;Last Update		: 16/12/2016
;Authors   			: Tan Chee Phang, Dr. Fakhrul Zaman Rokhani
;Description		: Procedures to control the Grove LCD  	
;
;--------------------------------------------------------------------------	


%include "..\ASM Macro\galileo_gen_1.mac"		;include macro library
%include "..\ASM Macro\grove_rgb_lcd.mac"		;include macro library


;--------------------------------------------------------------------------procedures shared with other file
Global lcd_i2c_enable, lcd_rgb_i2c_enable, lcd_initial, lcd_1st_line, lcd_2nd_line, 
Global lcd_clear_screen, lcd_write_stop, lcd_data, lcd_print_data, lcd_write
Global conv_hex_2_ascii


;--------------------------------------------------------------------------procesures from other object file
Extern check
Extern delay, delay_1_53ms, delay_39us, delay_long, delay_short



	
;--------------------------------------------------------------------------LCD	initialization
lcd_initial:
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000080	;
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000238	;Function set 0011 1100
 
	call check										;call check to make sure i2c controller transmit data not overflow
	call delay										;LCD need some delay time to settle


	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000080	;
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x0000020E	;Display ON/OFF

	call check										;call check to make sure i2c controller transmit data not overflow
	call delay

	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000080	;
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000201	;Display Clear

	call check										;call check to make sure i2c controller transmit data not overflow
	call delay_1_53ms

	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000080	;
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000206	;Entry mode set

	call check										;call check to make sure i2c controller transmit data not overflow
	call delay
	ret
;--------------------------------------------------------------------------

	
	
	
;--------------------------------------------------------------------------
lcd_1st_line:
	call check
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000080	;
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000202	;Set cursor to head of 1st line
	ret

	
	
	
;--------------------------------------------------------------------------
lcd_2nd_line:
	call check
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000080	;
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x000002c0	;Set cursor to head of 2nd line
	ret
	
	
	
	
;--------------------------------------------------------------------------
;tell LCD controller to clear screen
lcd_clear_screen:
	call check
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000080	;
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000201	;Display Clear
	ret



	
;--------------------------------------------------------------------------
;tell LCD controller to print received data to LCD

lcd_data:
	call check
	mov [i2c_bar+ IC_DATA_CMD]	, dword 0x00000040	;Display data	, Co = 0 
	ret
	
	
	
	
;--------------------------------------------------------------------------print EAX last one byte data to LCD
lcd_write:												
	
	push edx									;push edx register value to stack
	mov edx, eax								;move EAX data to EDX
	and edx, 0x000000ff							;remain the last one byte of data only 
	mov [i2c_bar+ IC_DATA_CMD]	, edx			;start sending the data via i2c bus
	pop edx										;restore back the edx register value
	call check									;call check to make sure i2c controller transmit data not overflow
	ret

	
	
	
;--------------------------------------------------------------------------
;tell LCD controller this is the last byte of data, send stop command to I2C
lcd_write_stop:
	push edx									;push edx register value to stack
	mov edx, eax								;move EAX data to EDX
	and edx, 0x000000ff							;remain the last one byte of data only 
	or  edx, 0x200								;set the bit_10 to one, send stop commmand to slave device
	mov [i2c_bar+ IC_DATA_CMD]	, edx			;start sending the data via i2c bus
	pop edx 									;restore back the edx register value		
	call check									;call check to make sure i2c controller transmit data not overflow
	ret

	
	
	
;--------------------------------------------------------------------------
lcd_print_data:				;before call this, set reg ESI (data) and reg ECX (data length)
	dec ecx					;decrease ECX by 1

.lcd_loop:					;local label
	lodsb 					;register ESI will increase one after this instruction is executed 
	call lcd_write			;write data to LCD

	push ecx				;push ECX to stack,because delay function is using ECX too 
	call delay				;call delay
	pop ecx					;restore ECX value

	loop .lcd_loop			;continue to write data to LCD	

	lodsb 					;load a byte from data section to register AL	
	call lcd_write_stop		;last byte of string
	
	call check				;call check to make sure i2c controller transmit data not overflow

	ret						;return
;--------------------------------------------------------------------------



;--------------------------------------------------------------------------Local procedure
conv_hex_2_ascii:					;convert 4-bit hexadecimal to match 
									;HD44780 LCD controller Character Codes
									;Example: if EDX is 0x01, EAX will be changed to 0x31
						
						
push edx				
and dl,  0x0f			
cmp dl,  0x00
pop edx
jnz .con_1
mov eax,  0x00000030	;0
ret

.con_1: 
push edx
and dl,  0x0f
cmp dl,  0x01
pop edx
jnz .con_2
mov eax,  0x00000031	;1
ret

.con_2: 
push edx
and dl,  0x0f
cmp dl,  0x02
pop edx
jnz .con_3
mov eax,  0x00000032	;2
ret

.con_3: 
push edx
and dl,  0x0f
cmp dl,  0x03
pop edx
jnz .con_4
mov eax,  0x00000033	;3
ret

.con_4: 
push edx
and dl,  0x0f
cmp dl,  0x04
pop edx
jnz .con_5
mov eax,  0x00000034	;4
ret

.con_5: 
push edx
and dl,  0x0f
cmp dl,  0x05
pop edx
jnz .con_6
mov eax,  0x00000035	;5
ret

.con_6: 
push edx
and dl,  0x0f
cmp dl,  0x06
pop edx
jnz .con_7
mov eax,  0x00000036	;6
ret

.con_7: 
push edx
and dl,  0x0f
cmp dl,  0x07
pop edx
jnz .con_8
mov eax,  0x00000037	;7
ret

.con_8: 
push edx
and dl,  0x0f
cmp dl,  0x08
pop edx
jnz .con_9
mov eax,  0x00000038	;8
ret

.con_9: 
push edx
and dl,  0x0f
cmp dl,  0x09
pop edx
jnz .con_a
mov eax,  0x00000039	;9
ret

.con_a: 
push edx
and dl,  0x0f
cmp dl,  0x0a
pop edx
jnz .con_b
mov eax,  0x00000041	;a
ret

.con_b: 
push edx
and dl,  0x0f
cmp dl,  0x0b
pop edx
jnz .con_c
mov eax,  0x00000042	;b
ret

.con_c: 
push edx
and dl,  0x0f
cmp dl,  0x0c
pop edx
jnz .con_d
mov eax,  0x00000043	;c
ret

.con_d: 
push edx
and dl,  0x0f
cmp dl,  0x0d
pop edx
jnz .con_e
mov eax,  0x00000044	;d
ret

.con_e: 
push edx
and dl,  0x0f
cmp dl,  0x0e
pop edx
jnz .con_f
mov eax,  0x00000045	;e
ret

.con_f: 
push edx
and dl,  0x0f
cmp dl,  0x0f
pop edx
mov eax,  0x00000046	;f
ret
;--------------------------------------------------------------------------


