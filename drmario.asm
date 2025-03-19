################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Avanti Tandon, 1010498695
# Student 2: Serene Stoller, 1009898522
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    32
# - Display height in pixels:   32
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

   
main:     
    # Draw the bottle
    jal draw_background
    # Draw the first randomly colored pill
    jal draw_pill
    # Initialize the game


game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop

draw_background:
    # return addresses and reinitialsatoon 
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $t4, 0xffffff        # $t4 = white 
    lw $t0, ADDR_DSPL       
    
    # left wall init
    add $t5, $zero, $zero   # $loop variable
    addi $t6, $zero, 34     # $heigh
    addi $t8, $t0, 1548      # row 6, col 3
    
    draw_left_wall:
        sw $t4, 0($t8) 
        addi $t5, $t5, 1    # Increment counter
        addi $t8, $t8, 256  
        blt $t5, $t6, draw_left_wall
        
    #Draw the bottom
    add $t5, $zero, $zero
    addi $t6, $zero, 26
    addi $t8, $t0,  10252
    
    draw_bottom_hehe:
        sw $t4, 0($t8)
        addi $t5, $t5, 1    # Increment counter
        addi $t8, $t8, 4  
        blt $t5, $t6, draw_bottom_hehe
        
    # Draw right wall (from top to bottom)
    add $t5, $zero, $zero   # Reset 
    addi $t6, $zero, 34   # $ height
    addi $t8, $t0, 1648     # row 6 col 28
    
    draw_right_wall:
        sw $t4, 0($t8)      # Draw white pixel at $t8
        addi $t5, $t5, 1    # Increment counter
        addi $t8, $t8, 256  # Move down one row
        blt $t5, $t6, draw_right_wall
        
    #draw first half of top
    add $t5, $zero, $zero   # Reset 
    addi $t6, $zero, 10
    addi $t8, $t0, 1548  #row 5 col 3

    draw_top_h1:
        sw $t4, 0($t8)      
        addi $t5, $t5, 1    
        addi $t8, $t8, 4  
        blt $t5, $t6, draw_top_h1
    
    add $t5, $zero, $zero   # Reset 
    addi $t6, $zero, 10
    addi $t8, $t0, 1648   #row 5 col 17
    
    draw_top_h2:
        sw $t4, 0($t8)      
        addi $t5, $t5, 1    
        addi $t8, $t8, -4  
        blt $t5, $t6, draw_top_h2
        
    # draw top part of the bottle
    
    add $t5, $zero, $zero   # Reset 
    addi $t6, $zero, 4
    addi $t8, $t0, 820 
    
    draw_top_h3:
        sw $t4, 0($t8)      
        addi $t5, $t5, 1    
        addi $t8, $t8, 256  
        blt $t5, $t6, draw_top_h3
    
    add $t5, $zero, $zero   # Reset 
    addi $t6, $zero, 4
    addi $t8, $t0, 840
    
    draw_top_h4:
        sw $t4, 0($t8)      
        addi $t5, $t5, 1    
        addi $t8, $t8, 256  
        blt $t5, $t6, draw_top_h4
    
    # Return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
generate_random_color:
    li $v0 , 42 # syscall number
    li $a0 , 0 # contains the return value
    li $a1 , 3 # sets maximum value of 2
    syscall
    li $t1, 0xff0000   # red
    li $t2, 0x00ff00   # green
    li $t3, 0x0000ff   # blue
    
    beq $a0, 0, return_red # 0 = red
    beq $a0, 1, return_green # 1 = green
    move $v0, $t3      # 2 = blue
    jr $ra

return_red:
    move $v0, $t1      # return red
    jr $ra
    
return_green:
    move $v0, $t2      # return green
    jr $ra

draw_pill:
    addiu $sp, $sp, -4  # save return address
    sw $ra, 0($sp)
    
    jal generate_random_color  # generate random color and store in $v0
    move $a0, $v0       # move color to $a0 for drawing
    lw $t0, ADDR_DSPL # reset location
    li $t5, 1084  # position is col 63, row 4
    addu $t6, $t0, $t5 # add offset to start location
    sw $a0, 0($t6) # draw the pixel
    
    jal generate_random_color  # repeat for the bottom half
    move $a0, $v0  # move color to $a0 for drawing
    li $t5, 1088 # position is col 64, row 4
    addu $t6, $t0, $t5 # add offset to start location
    sw $a0, 0($t6) # draw the pixel
    
    lw $ra, 0($sp)    # return
    addiu $sp, $sp, 4
    jr $ra
