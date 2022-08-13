;--------------------------------------------------------------------------
;File Name     		: autonomous_pill_indicator.asm
;Version 			: 3.0
;Created Date		: 19/05/2022
;Last Update		: 29/06/2022
;Authors   			: Tan Chee Phang, Dr. Fakhrul Zaman Rokhani, Lim Yang Wei, 
;					  Tan Zhi Lin, Tabina Kamal, Adlynn
;Description		: A manual-alarm simulation for the autonomous pill indicator, 
;					  pills checking and reminding system
;Hardware 			: 1. Intel Galileo Gen 1
;					  2. Grove-LCD RGB Backlight V2.0 connected using I2C connector 
;					  3. Grove-Base Shield V1.3
;					  4. Adafruit Motor Shield V2.0 and bipolar stepper 
;						 motor PM35S-048-BRY2
;					  5. LEDs, buzzer and vibrating motor disc
;					  6. IR sensor
;					  7. Grove-button socket
;Macro files		: galileo_gen_1.mac, grove_rgb_lcd.mac, pin_setup.mac, 
;					  adafruit_motor_shield_v2.mac, quark_soc_rtc.mac, 
;					  cyp_io_expander.mac
;Procedure files	: grove_rgb_lcd_lib.o, cyp_io_expander.o , galileo_gen_1.o 
;--------------------------------------------------------------------------	


BITS 32				;tell the assembler-NASM that this is 32-bit 


%include "..\ASM Macro\galileo_gen_1.mac"				;included macro library
%include "..\ASM Macro\grove_rgb_lcd.mac"				;included macro library
%include "..\ASM Macro\cyp_io_expander.mac"				;included macro library
%include "..\ASM Macro\adafruit_motor_shield_v2.mac"	;included macro library
%include "..\ASM Macro\quark_soc_rtc.mac"				;included macro library

;----------------------------------------tells NASM these are external procedure 
Extern lcd_initial, lcd_1st_line, lcd_2nd_line, 
Extern lcd_clear_screen, lcd_write, lcd_write_stop, lcd_data, lcd_print_data
Extern check
Extern delay, delay_1_53ms, delay_39us, delay_long, delay_short
Extern conv_hex_2_ascii


;-----------------------------------------code section
SECTION .text						;CODE section

;--------------------------------------------------------------------------
nop									;no operation	
nop									;no operation	

;--------------------------------------------------------------------------
;RTC_Setup
;--------------------------------------------------------------------------
;Invoke macro to set the RTC registers value
;uncomment this if dont want to reset the RTC
;		 sec	min		hour	day_of_week		day_of_month	month		year
reg_rtc  0x00,  0x54,	0x16,   0x04,			0x04,			0x06,		0x22		 	

;I2C_Setup
;invoke macro to enable i2c pin on the Galileo board
enable_i2c								
;configure LCD as slave device on i2c controller
setup_soc_i2c_controller   RGB_ADDRESS
;change LCD RGB LED to white color
lcd_rgb_on white		

	
;--------------------------------------------------------------------------
;Initializing the LCD
;--------------------------------------------------------------------------
;configure LCD as slave device #1 on i2c controller
setup_soc_i2c_controller   LCD_ADDRESS	
;initialize LCD controller and clear the LCD display
call lcd_initial			

;--------------------------------------------------------------------------
;Start program
;--------------------------------------------------------------------------
_start:
	call update_lcd_status
	
	call IO_5_set_input				;set IO_5 as Input
	call IO_9_set_input				;set IO_9 as Input

	read_cyp_io_input 		0x0		;invoke macro to read port_0 input data
									;port data will be moved to EDX register	

	and edx, 0x00000002				;masking, make sure only IO_5 (port_0, bit_1) 
									;will be checked
									;0bxxxx AND 0b0010 = 0b00x0

	cmp edx, 0x00000002				;check IO_5 (port_0, bit_1) 
									;compare the value of edx,(0b001x), with 
									;0x02,(0b0010), 
									;to ensure IO_5 is ON
	je released_IO5
	
	call IO_10_set_input			;set IO_10 as Input
	
	read_cyp_io_input 		0x0		;invoke macro to read port_0 input data
									;port data will be moved to EDX register
									
	and edx, 0x00000001				;masking, make sure only IO_10 (port_0, bit_0) 
									;will be checked
	cmp edx, 0x00000001				;compare the value store in EDX register
	je emergency
	
	jmp turn_off_output

;------------------------------------------------------------------------------
;Edge triggered to check the input 5 to ensure turn on only once when triggered
;------------------------------------------------------------------------------
released_IO5:
	call IO_5_set_input				;set IO_5 as Input
	read_cyp_io_input 		0x0		;invoke macro to read port_0 input data
									;port data will be moved to EDX register
	and edx, 0x00000002		
	cmp edx, 0x00000000
	
	je check_pill					;jump to check_pill once IO5 is released
	jmp released_IO5				;loop to check IO5 status
	
;--------------------------------------------------------------------------
;Check whether there is a pill in the section
;--------------------------------------------------------------------------
check_pill:
	call IO_9_set_input				;set IO_9 as Input
	read_cyp_io_input 		0x0		;invoke macro to read port_0 input data
									;port data will be moved to EDX register
									
	and edx, 0x00000008				;and check IO_9 (port_0, bit_3) will be checked
									;0bxxxx AND 0b1000 = 0bx000

	cmp edx, 0x00000008				;check IO_9 (port_0, bit_3)
									;compare the value of edx,(0bx000), with 
									;0x08 (0b1000) to ensure IO_9 is ON
	je turn_pill					;turn to a section have pill
	cmp dword [ds:counter], 0x00000030	;if the counter == 0
	je alert_refill						;alert user to refill the pills
	dec dword [ds:counter]				;else decrease number of pill by 1
	jmp alert							;alert the user to take pill

;--------------------------------------------------------------------------
;Turn to next section
;--------------------------------------------------------------------------								
turn_pill:
	cmp dword [ds:counter], 0x00000030	;if the counter == 0
	je alert_refill						;alert user to refill the pill
	mov byte [ds:count_pill], 0x04
	
	.l1:
		call update_lcd_status
		call IO_9_set_input				;set IO_9 as Input
		read_cyp_io_input 		0x0		;invoke macro to read port_0 input data
										;port data will be moved to EDX register
										
		and edx, 0x00000008				;and check IO_9 (port_0, bit_3) will be checked
										;0bxxxx AND 0b1000 = 0bx000

		cmp edx, 0x00000008				;check IO_9 (port_0, bit_3)
										;compare the value of edx,(0bx000), with 
										;0x08 (0b1000) to ensure IO_9 are ON
		jne .out						;turn to a section have pill
		call stepper_motor				;turn on the stepper to go through the 
										;next section
		dec byte [ds:count_pill]		;decrease ecx by one
		jz alert_refill
		call delay_long					;short delay 
		jmp .l1
	
	.out:
	dec dword [ds:counter]				;decrease number of pill by 1
	
;--------------------------------------------------------------------------
;Alert the user to take pill
;--------------------------------------------------------------------------
alert:
	mov ecx, 0x04						;set the number of loop 
	call alert_on
	jmp turn_off_output
;----------------------------------------------------------------------------
;Alert user to refil the pills and auto reset the number of pills to be taken
;----------------------------------------------------------------------------
alert_refill:
	;configure LCD as slave device on i2c controller 
	;and this is for setup of colored background
	setup_soc_i2c_controller   RGB_ADDRESS		
												
	mov ecx, 0x02					;counter to loop the rgb for 2 times
	
	rgb_loop:
		lcd_rgb_on red				;change LCD RGB LED to red color
		call delay
		
		lcd_rgb_on cyan				;change LCD RGB LED to cyan color
		call delay
		
		lcd_rgb_on yellow			;change LCD RGB LED to yellow color
		call delay
		
		lcd_rgb_on red				;change LCD RGB LED to red color
		call delay
	
		dec ecx						;subtract ECX register by one	
		jnz rgb_loop				;use JNZ to exist the loop
	
	;configure LCD as slave device on i2c controller
	;and this is for setup of colored background
	setup_soc_i2c_controller   LCD_ADDRESS
	
	call lcd_initial							;clear LCD screen
	call msg_alert_refil						;show the message to alert the user 
												;to refill 
	cmp dword [ds:counter], 0x00000030			;compare current counter with zero
	jne .r1
	mov dword [ds:counter], 0x00000034			;move decimal 4 into the counter 
	.r1:
	mov ecx, 0x02
	call delay_1_53ms
	
	;configure LCD as slave device on i2c controller
	;and this is for setup of colored background
	setup_soc_i2c_controller   RGB_ADDRESS	     
	
	lcd_rgb_on white							;change LCD RGB LED to white color
	
	;configure LCD as slave device on i2c controller
	;and this is for setup of colored background
	setup_soc_i2c_controller   LCD_ADDRESS		
	
	call lcd_initial
	call emergency_on							;alert user to consume the pill
	jmp turn_off_output							;jump to turn off the output

;-------------------------------------------------------
;Emergency button to simulate calling to the care giver
;-------------------------------------------------------
emergency:
	mov ecx, 0x08						;set the number of loop 
	call emergency_on					;alert the caregiver for instant help
	jmp turn_off_output

;----------------------------------------------------------------------------
;Turn off all of the output
;----------------------------------------------------------------------------
turn_off_output:		
	call IO_6_set_output				;set IO_6 as Output
	call IO_7_set_output				;set IO_7 as Output
	call IO_8_set_output				;set IO_8 as Output
	
	;switch OFF IO6, IO7, IO8 (0b0000_1101)
	unset_cyp_io_pin   	 			Port_1_out,  0b1111_0010	
	
jmp _start

;--------------------------------------------------------------------------
;Update the message on LCD 
;--------------------------------------------------------------------------
update_lcd_status:
	;  configure LCD as slave device #1 on i2c controller 
	;  invoke macro, please refer to galileo_gen_1.mac
	setup_soc_i2c_controller   LCD_ADDRESS		
												
	;Show real time 
	call lcd_1st_line 				; set cursor to head of 1st line
	mov eax, 'Time'					; print 'TIME' to LCD
	call print_eax_2_lcd
	mov eax, ':   '					; print ':   ' to LCD
	call print_eax_2_lcd
	print_rtc hours_reg				; invoke macro to print hours register value from RTC
	call print_colon
	print_rtc minutes_reg			; invoke macro to print minutes register value from RTC
	call print_colon
	print_rtc seconds_reg			; invoke macro to print seconds register value from RTC
	
	call lcd_2nd_line 				; move LCD cursor to 2nd line
	mov eax, 'Left'					; print 'Date' to LCD
	call print_eax_2_lcd
	mov eax, ':   '					; print ':   ' to LCD
	call print_eax_2_lcd
	call print_counter
ret

;--------------------------------------------------------------------------
;Show the message to alert the user to refill
;--------------------------------------------------------------------------
msg_alert_refil:
	; configure LCD as slave device #1 on i2c controller 
	; invoke macro, please refer to galileo_gen_1.mac
	setup_soc_i2c_controller   LCD_ADDRESS		
												
	;Show real time 
	call lcd_1st_line 							; Set cursor to head of 1st line
	
	mov eax, 'WARN'								;print 'WARN' to LCD
	call print_eax_2_lcd

	mov eax, 'ING!'								;print 'ING!' to LCD
	call print_eax_2_lcd

	mov eax, '!!!!'								;print '!!!!' to LCD
	call print_eax_2_lcd

	call lcd_2nd_line 							;move LCD cursor to 2nd line

	mov eax, 'PLEA'								;print 'PLEA' to LCD
	call print_eax_2_lcd

	mov eax, 'SE R'							    ;print 'SE' to LCD
	call print_eax_2_lcd
	
	mov eax, 'EFIL'								;print 'REFI' to LCD
	call print_eax_2_lcd

	mov eax, 'L!!!'								;print 'LI!!' to LCD
	call print_eax_2_lcd						
ret

;--------------------------------------------------------------------------
;Turn on intergrated reminder circuit
;--------------------------------------------------------------------------
alert_on:
	.l1:
	call IO_6_set_output			;set IO_6 as Output
	call IO_8_set_output			;set IO_8 as Output
	
	;switch ON IO6 (port_1, bit_0) & IO8 (port_1, bit_2)
	set_cyp_io_pin     			Port_1_out,  0b0000_0101			
	
	call delay
	call update_lcd_status			;update LCD status
		
	dec ecx							;subtract ECX register by ONE
	jnz .l1							;loop for ECX times
ret

;--------------------------------------------------------------------------
;Turn on emergency
;--------------------------------------------------------------------------
emergency_on:
	.l1:
	call IO_6_set_output			;set IO_6 as Output
	call IO_7_set_output			;set IO_7 as Output
	
	;switch ON IO6 (port_1, bit_0) & IO7 (port_1, bit_3)	
	set_cyp_io_pin     				Port_1_out,  0b0000_1001
	call delay
	
	;switch OFF IO6 (port_1, bit_0) & IO7 (port_1, bit_3)	
	unset_cyp_io_pin     			Port_1_out,  0b1111_0110			
	call update_lcd_status			;update LCD status
	dec ecx							;subtract ECX register by ONE
	jnz .l1
ret

;--------------------------------------------------------------------------
;Run the stepper to turn to the next section
;--------------------------------------------------------------------------
stepper_motor:
	; configure Adafruit Motor Shield component PCA9685 as slave device
	setup_soc_i2c_controller  	MOTOR_ADDR
	; setup PCA9685 mode 1 register
	setup_motor_shield							
	mov ecx, 0d7			;rotate the stepper motor 4 steps for 12 times 
							;total number of steps per rotation is 48

	.l1:					;local label		
		M3_forward			;configure port M3 top as positive, bottom as negative (1 step)
		M3_fully_on 		;switch on port M3

		M4_backward			;configure port M4 top as negative, bottom as positive (1 step)
		M4_fully_on 		;switch on port M4 

		M3_backward			;configure port M3 top as negative, bottom as positive (1 step)
		M3_fully_on  		;switch on port M3

		M4_forward			;configure port M4 top as positive, bottom as negative (1 step)	
		M4_fully_on 		;switch on port M4 

		dec ecx				;decrease ECX by 1	
		jnz .l1				;jump to local label .l1 if ECX is not ZERO
	M3_fully_off 			;switch off port M3 to reduce heat  	
	M4_fully_off 			;switch off port M4 to reduce heat 
ret

;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
;I/O Declaration
;-----------------------------------------------set IO_5 as Input -- Simuate alarm
IO_5_set_input:

	push eax										
	
	; configure slave device = IO Expander
	setup_soc_i2c_controller    IO_expander_ADDR				
	
	; select Port 0
	cyp_io_expander_port_sel   	0x00							
	
	; set pin direction to input - 0=output, 1=input  
	; change GPORT0_BIT1 to 1
	set_cyp_io_pin          	Port_0_pin_dir,	0b0000_0010		

	; set drive mode to pull-down
	; Grove switch is active high 
	set_cyp_io_pin_drive_mode	Pull_Down,	   	0b0000_0010		
	
    pop eax

ret
;-----------------------------------------------

;-----------------------------------------------set IO_9 as Input -- IR sensor
IO_9_set_input:

	push eax	
	
	; configure slave device = IO Expander
	setup_soc_i2c_controller    IO_expander_ADDR				
	
	; select Port 0
	cyp_io_expander_port_sel   	0x00							
	
	; set pin direction to input - 0=output, 1=input  
	; change GPORT0_BIT3 to 1
	set_cyp_io_pin          	Port_0_pin_dir,	0b0000_1000		

	; set drive mode to pull-down
	; Grove switch is active high 
	set_cyp_io_pin_drive_mode	Pull_Down,	   	0b0000_1000		
	
    pop eax

ret
;-----------------------------------------------

;-----------------------------------------------set IO_10 as Input -- Emergency button
IO_10_set_input:

	push eax										
	
	; configure slave device = IO Expander
	setup_soc_i2c_controller    IO_expander_ADDR				
	
	; select Port 0
	cyp_io_expander_port_sel   	0x00							
	
	; set pin direction to input - 0=output, 1=input  
	; change GPORT0_BIT0 to 1
	set_cyp_io_pin          	Port_0_pin_dir,	0b0000_0001	

	; set drive mode to pull-down
	; Grove switch is active high 
	set_cyp_io_pin_drive_mode	Pull_Down,	   	0b0000_0001	
    pop eax

ret
;-----------------------------------------------

;-----------------------------------------------set IO_6 as Output -- buzzer & vibrating motor
IO_6_set_output:

	push eax										
	
	; configure slave device = IO Expander
	setup_soc_i2c_controller    IO_expander_ADDR			
	
	; select Port 1
	cyp_io_expander_port_sel   	0x01							
	
	; set pin direction to input - 0=output, 1=input  
	; change GPORT1_BIT0 to 1
	unset_cyp_io_pin          	Port_1_pin_dir,	0b1111_1110		
	
	; set drive mode to strong											
	set_cyp_io_pin_drive_mode	Strong,	      	0b0000_0001		
	
    pop eax
	
ret
;-----------------------------------------------

;-----------------------------------------------set IO_7 as Output -- red light 
IO_7_set_output:

	push eax										
	
	; configure slave device = IO Expander
	setup_soc_i2c_controller    IO_expander_ADDR				
	
	; select Port 1
	cyp_io_expander_port_sel   	0x01							
	
	; set pin direction to input - 0=output, 1=input  
	; change GPORT1_BIT3 to 1
	unset_cyp_io_pin          	Port_1_pin_dir,	0b1111_0111		
					
	; set drive mode to strong	
	set_cyp_io_pin_drive_mode	Strong,	      	0b0000_0001		
	
    pop eax
	
ret
;-----------------------------------------------

;-----------------------------------------------set IO_8 as Output -- white light 
IO_8_set_output:

	push eax										
	
	; configure slave device = IO Expander
	setup_soc_i2c_controller    IO_expander_ADDR	
	
	; select Port 1
	cyp_io_expander_port_sel   	0x01							
	
	; set pin direction to input - 0=output, 1=input  
	; change GPORT1_BIT2 to 1
	unset_cyp_io_pin          	Port_1_pin_dir,	0b1111_1011	
	
	; set drive mode to strong									
	set_cyp_io_pin_drive_mode	Strong,	      	0b0000_0001		
	
    pop eax
	
ret
;-----------------------------------------------

;------------------------------------------------------------------------------------
;Local functions for LCD
;--------------------------------------------------------- Print EAX (4 bytes) to LCD 
print_eax_2_lcd:
	call lcd_data								; Configure LCD to start display data
	call lcd_write								
	shr eax, 8
	call lcd_write							
	shr eax, 8
	call lcd_write								
	shr eax, 8
	call lcd_write_stop						    
ret
;------------------------------------------------------------------------------------

;------------------------------------------------------------------- Print ' ' to LCD 
print_space:
	push eax
	mov al, ' '
	call lcd_data								; Configure LCD to start display data
	call lcd_write_stop
	pop eax
ret
;--------------------------------------------------------------------------------------

;-------------------------------------------------------------------- Print ':' to LCD 
print_colon:
push eax
mov al, ':'
call lcd_data									; Configure LCD to start display data
call lcd_write_stop	
pop eax
ret
;--------------------------------------------------------------------------------------

;---------------------------------------------------- Print the number of medicine left
print_counter:
push eax
mov al, [ds:counter]
call lcd_data									; Configure LCD to start display data
call lcd_write_stop
pop eax
ret
;---------------------------------------------------------------------------------------

;---------------------------------------------------- Data section
SECTION .data								;DATA section

counter 	dd 	0x00000034
count_pill 	db 	0x04
;-----------------------------------------------------------------