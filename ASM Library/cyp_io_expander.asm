;--------------------------------------------------------------------------
;File Name     		: cyp_io_expander.asm
;Version 			: 1.1
;Created Date		: 28/11/2016
;Last Update		: 16/12/2016
;Authors   			: Tan Chee Phang, Dr. Fakhrul Zaman Rokhani
;Description		: Setup data section to store the configuration register value of Cypress IO Expander 

;--------------------------------------------------------------------------	


Global Port_0_out, Port_1_out, Port_2_out, Port_3_out, Port_4_out, Port_5_out
Global Port_0_int_mask, Port_1_int_mask, Port_2_int_mask, Port_3_int_mask, Port_4_int_mask, Port_5_int_mask
Global Port_0_pwm, Port_1_pwm, Port_2_pwm, Port_3_pwm, Port_4_pwm, Port_5_pwm
Global Port_0_inv, Port_1_inv, Port_2_inv, Port_3_inv, Port_4_inv, Port_5_inv
Global Port_0_pin_dir, Port_1_pin_dir, Port_2_pin_dir, Port_3_pin_dir, Port_4_pin_dir, Port_5_pin_dir

Global check  	



;-------------------------------------------------------------------------- data section
SECTION .data
;Store Port Output Data
Port_0_out	: db 0 , 0x08
Port_1_out	: db 0 , 0x09
Port_2_out	: db 0 , 0x0A
Port_3_out	: db 0 , 0x0B
Port_4_out	: db 0 , 0x0C
Port_5_out	: db 0 , 0x0D

;;--------------------------------------------------------------------------


Port_0_int_mask			: db 0 , 0x19
Port_0_Port_pwm			: db 0 , 0x1A
Port_0_inv				: db 0 , 0x1B
Port_0_pin_dir			: db 0 , 0x1C

Port_1_int_mask			: db 0 , 0x19
Port_1_Port_pwm			: db 0 , 0x1A
Port_1_inv				: db 0 , 0x1B
Port_1_pin_dir			: db 0 , 0x1C

Port_2_int_mask			: db 0 , 0x19
Port_2_Port_pwm			: db 0 , 0x1A
Port_2_inv				: db 0 , 0x1B
Port_2_pin_dir			: db 0 , 0x1C

Port_3_int_mask			: db 0 , 0x19
Port_3_Port_pwm			: db 0 , 0x1A
Port_3_inv				: db 0 , 0x1B
Port_3_pin_dir			: db 0 , 0x1C

Port_4_int_mask			: db 0 , 0x19
Port_4_Port_pwm			: db 0 , 0x1A
Port_4_inv				: db 0 , 0x1B
Port_4_pin_dir			: db 0 , 0x1C

Port_5_int_mask			: db 0 , 0x19
Port_5_Port_pwm			: db 0 , 0x1A
Port_5_inv				: db 0 , 0x1B
Port_5_pin_dir			: db 0 , 0x1C
;-----------------------------------------------


