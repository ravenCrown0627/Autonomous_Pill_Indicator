MEMORY
{
DDR_code : org = 0x0e3ac0f0, len = 0x500
DDR_data : org = 0x100000 , len = 0x200
}
 
SECTIONS
{
my_code :
{*(.text);} >DDR_code
my_data :
{*(.data);} >DDR_data
}

