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

    # Run the game.
main:
    # Initialize the game
    li $t1, 0xff0000        # $t1 = red
    li $t2, 0x00ff00        # $t2 = green
    li $t3, 0x0000ff        # $t3 = blue
    li $t4, 0xffffff        # $t4 = white
    
    lw $t0, ADDR_DSPL       # $t0 = base address for display
    
    add $t5, $zero, $zero # store zero in $t5, initial i
    addi $t6, $zero, 125 # store 125 in $t6, final i
    addi $t0, $t0, 384 # update initial position
    
    draw_left:
    sw $t4, 0($t0) # draw white pixel
    addi $t5, $t5, 1 # increment i
    addi $t0, $t0, 128 # update position to draw 
    beq $t5, $t6, stop_drawing_left
    j draw_left
    stop_drawing_left:
    
    lw $t0, ADDR_DSPL   # reload base address again (0x10008000)
    addi $t0, $t0, 480  # offset into display memory correctly
    add $t5, $zero, $zero # store zero in $t5, initial i
    draw_right:
    sw $t4, 0($t0) # draw white pixel
    addi $t5, $t5, 1 # increment i
    addi $t0, $t0, 128 # update position to draw 
    beq $t5, $t6, stop_drawing_right
    j draw_right
    stop_drawing_right:

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
