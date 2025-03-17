##############################################################################
# Example: Displaying Pixels
#
# This file demonstrates how to draw pixels with different colours to the
# bitmap display.
##############################################################################

######################## Bitmap Display Configuration ########################
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
##############################################################################
    .data
ADDR_DSPL:
    .word 0x10008000

    .text
	.globl main

main:
    li $t1, 0xff0000        # $t1 = red
    li $t2, 0x00ff00        # $t2 = green
    li $t3, 0x0000ff 
    li $t4, 0xffffff        # white

    lw $t0, ADDR_DSPL       # $t0 = base address for display
    sw $t4, 24($t0)          # paint the first unit (i.e., top-left) red
    sw $t4, 4($t0)          # paint the second unit on the first row green
    sw $t4, 128($t0) 
    
    
 
exit:
    li $v0, 10              # terminate the program gracefully
    syscall
