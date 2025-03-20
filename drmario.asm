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
# - Display width in pixels:    64
# - Display height in pixels:   64
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
# The address the game board starts at.
ADDR_BOARD:
    .word 0x11000000

##############################################################################
# Mutable Data
##############################################################################
# The game board, 33  rows * 24 cols * 4 bytes per slot 
# BOARD_GRID: 
#     .space 3168

##############################################################################
# Code
##############################################################################
	.text
	.globl main

   
main:     
    # Initialize the board
    jal init_board
    # Draw the bottle
    jal draw_bottle
    # Draw 4 random viruses in the lower half of the board
    jal generate_draw_viruses
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

init_board: # Initializes 33x24 board to empty (type = 0, color = black)
    lw $t0, ADDR_BOARD # t0 stores board address
    li $t1, 0          # row = 0
    init_board_row_loop:
    li $t2, 0          # col = 0
    init_board_col_loop:
    # calculate offset (row * 24 + col) * 4
    mul $t3, $t1, 24   # t3 = row * 24
    add $t3, $t3, $t2  # t3 = row * 24 + col
    mul $t3, $t3, 4    # t3 = offset in bytes
    
    add $t4, $t0, $t3 # add offset to base address
    sb $zero, 0($t4) # store 0 into type byte 
    sb $zero, 1($t4) # store 0 (black) into color bytes
    sb $zero, 2($t4) # store 0 (black) into color bytes
    sb $zero, 3($t4) # store 0 (black) into color bytes
  
    addi $t2, $t2, 1 # increment col
    blt $t2, 24, init_board_col_loop

    addi $t1, $t1, 1 # increment row
    blt $t1, 33, init_board_row_loop
    
    jr $ra # return 

draw_bottle:
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
        
    # draw left half of top of bottle
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
    
    # draw right half of top of bottle
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

generate_draw_viruses: #TODO: debug, viruses are everywhere
    addiu $sp, $sp, -4  
    sw $ra, 0($sp)      
    li $t5, 0             #  counter for number of viruses
    generate_virus_loop:
    # generate random row
    li $v0, 42 # syscall number 
    li $a0, 0 # stores return value
    li $a1, 16 # gets random number between 0 and 15
    syscall
    addi $a0, $a0, 17 # changes random number to a row between 17 and 32
    move $t9, $a0 # put result in $t9
    # generate random col
    li $v0, 42 # syscall number 
    li $a0, 0 # stores return value
    li $a1, 24 # gets random number between 0 and 23
    syscall
    move $t8, $a0 # put result in $t8
    #calculate memory offset
    mul $t6, $t9, 24      # t6 = row * 24
    add $t6, $t6, $t8     # t6 = row * 24 + col
    mul $t6, $t6, 4       # t6 = offset in bytes
    lw $t3, ADDR_BOARD    # base address of board
    add $t3, $t3, $t6     # t3 = base + offset
    # check if already occupied (type != 0 means already a virus here)
    lb $t4, 0($t3)
    bne $t4, $zero, generate_virus_loop
    # store the virus (type = 1)
    li $t4, 1
    sb $t4, 0($t3)
    # store color 
    jal generate_random_virus_color
    srl $t7, $v0, 16   # shift right 16 bits to get Red
    sb  $t7, 1($t3)    # store Red at offset +1
    srl $t7, $v0, 8    # shift right 8 bits to get Green
    andi $t7, $t7, 0xFF
    sb  $t7, 2($t3)    # store Green at offset +2
    andi $t7, $v0, 0xFF
    sb  $t7, 3($t3)    # store Blue at offset +3
    # draw virus pixel on display
    addi $t7, $t9, 7    # display_row = 7 + board_row
    addi $t8, $t8, 3    # display_col = 3 + board_col
    lw $t6, ADDR_DSPL
    mul $t7, $t7, 256   # t7 = row * 256
    sll $t8, $t8, 2     # column * 4 (4 bytes per pixel)
    add $t7, $t7, $t8   # t7 = row offset + column offset
    add $t6, $t6, $t7   # t6 = screen address + offset
    sw $v0, 0($t6)      # draw pixel with color
    # increment counter
    addi $t5, $t5, 1      
    blt $t5, 4, generate_virus_loop
    # return
    lw $ra, 0($sp)      
    addiu $sp, $sp, 4   
    jr $ra

generate_random_virus_color:
    li $v0 , 42 # syscall number
    li $a0 , 0 # contains the return value
    li $a1 , 3 # sets maximum value of 2
    syscall
    li $s1, 0x900000   # dark red
    li $s2, 0x009000   # dark green
    li $s3, 0x000090   # dark blue
    
    beq $a0, 0, return_dark_red # 0 = red
    beq $a0, 1, return_dark_green # 1 = green
    move $v0, $s3      # 2 = blue
    jr $ra
return_dark_red:
    move $v0, $s1      # return red
    jr $ra
return_dark_green:
    move $v0, $s2      # return green
    jr $ra

generate_random_block_color:
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
    
    jal generate_random_block_color  # generate random color and store in $v0
    move $a0, $v0       # move color to $a0 for drawing
    lw $t0, ADDR_DSPL # reset location
    li $t5, 1084  # position is col 63, row 4
    addu $t6, $t0, $t5 # add offset to start location
    sw $a0, 0($t6) # draw the pixel
    
    jal generate_random_block_color  # repeat for the bottom half
    move $a0, $v0  # move color to $a0 for drawing
    li $t5, 1088 # position is col 64, row 4
    addu $t6, $t0, $t5 # add offset to start location
    sw $a0, 0($t6) # draw the pixel
    
    lw $ra, 0($sp)    # return
    addiu $sp, $sp, 4
    jr $ra
