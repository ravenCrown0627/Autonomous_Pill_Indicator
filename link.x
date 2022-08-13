SECTIONS
{
  . = 0x0e3ac0f0;
  .text : { *(.text) }

  . = 0x100000;
  .data : { *(.data) }
  .bss  : { *(.bss) }
}