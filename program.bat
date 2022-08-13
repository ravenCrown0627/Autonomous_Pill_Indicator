::cd "Example1-I2C-LCD"

::cd "Example2-Digital_IO"

::cd "Example3-ADC"

::cd "Example4-Motor_shield"

::cd "Example5-4_digit_display"

::cd "Example6-Led_bar"

cd "Example7-RTC"

call assemble+link.bat


cd "..\"

start start_GDB.bat
