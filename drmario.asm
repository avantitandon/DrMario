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
    # 1 type byte and 3 color bytes per slot
    # type 0: empty
    # type 1: virus
    # type 2: block with no other half
    # type 3: block with other half to the left
    # type 4: block with other half on top
    # type 5: block with other half to the right
    # type 6: block with other half below
    BOARD_GRID: 
        .space 3168
    pill_left_offset:  
        .word 1084    # Starting memory offset for left pill
    pill_right_offset: 
        .word 1088  # Starting memory offset for right pill
    gravity_counter: 
        .word 0           # counter to keep track of time for gravity
    gravity_interval: 
        .word 60         # initial amount to wait before applying gravity (approx 1 sec)
    
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
        li $v0, 32 # system call for sleeping
        li $a0, 17 # sleep time is 17 milliseconds (1/60 seconds)
        syscall
        
        # Update gravity counter
        lw $t0, gravity_counter
        addi $t0, $t0, 1
        sw $t0, gravity_counter
        # check if it's time to apply gravity
        lw $t1, gravity_interval
        blt $t0, $t1, skip_gravity
        li $t0, 0
        sw $t0, gravity_counter # reset counter
        # speed up gravity over time
        lw $t2, gravity_interval       # Reload current interval
    #    subi $t2, $t2, 1               # Decrease interval TEMPORARY COMMENTED OUT FOR EASE OF TESTING
        li $t3, 5                 
        bge $t2, $t3, store_speed      # max speed
        li $t2, 5                    
        store_speed:
            sw $t2, gravity_interval       # Store updated speed
        jal apply_gravity
    
    skip_gravity:
        jal drop_all_blocks
        
        # 1b. Check which key has been pressed
        lw $t0, ADDR_KBRD #initialise keyboard to t0
        lw $t9, 0($t0) # load the input in the keyboard in rt9
        beq $t9, 1, keyboard_input
    
        # b game_loop
        lw $t0, ADDR_DSPL        # load display address
        li $t7, 0                # black color (0)
        
        # Check bottle neck to see if it's full    
        li   $t5, 1340     
        addu $t6, $t0, $t5 
        lw   $t1, 0($t6)   
        beq  $t1, $t7, continue_game  # If any is zero, continue game
    
        li   $t5, 1344     
        addu $t6, $t0, $t5 
        lw   $t1, 0($t6)   
        beq  $t1, $t7, continue_game
    
        li   $t5, 1596     
        addu $t6, $t0, $t5 
        lw   $t1, 0($t6)   
        beq  $t1, $t7, continue_game
    
        li   $t5, 1600     
        addu $t6, $t0, $t5 
        lw   $t1, 0($t6)   
        beq  $t1, $t7, continue_game
    
        j game_over # If all are nonzero, go to game over
        
    continue_game:
        # 2a. Check for collisions
        # 2b. Update locations (capsules)
        # 3. Draw the screen
        # 4. Sleep
        # 5. Go back to Step 1
        j game_loop
        
    apply_gravity:
        addi $sp, $sp, -4
        sw $ra, 0($sp)  
        jal check_orientation_s # Pretend s was pressed
        lw $ra, 0($sp)         # Restore return address
        addi $sp, $sp, 4
        jr $ra
    
    keyboard_input:                     # A key is pressed
        lw $a0, 4($t0)                  # Load second word from keyboard
        beq $a0, 0x70, handle_pause     # pause game if p is pressed
        beq $a0, 0x77, check_orientation_w
        beq $a0, 0x61, check_orientation_a
        beq $a0, 0x64, check_orientation_d
        beq $a0, 0x73, check_orientation_s 
        beq $a0, 0x71, respond_to_Q # Check if the key q was pressed
    
        li $v0, 1                       # ask system to print $a0
        syscall
    
        b game_loop
        
    respond_to_Q:
    	li $v0, 10                      # Quit gracefully
    	syscall
    	
    handle_pause:
        # draw pause message
        jal display_paused_message
        pause_loop:
            li $v0, 32           # system call for sleeping
            li $a0, 17           # sleep for 17 milliseconds
            syscall
            # Check if a key is pressed
            lw $t0, ADDR_KBRD
            lw $t9, 0($t0)
            beq $t9, 1, check_pause_key   # If a key is pressed, check which one
            j pause_loop
        check_pause_key:
            lw $a0, 4($t0)
            beq $a0, 0x70, resume_game     # If 'p' is pressed again, resume game
            j pause_loop
        resume_game:
            # clear the paused message by painting rows 50 to 55 black
            lw    $t0, ADDR_DSPL
            li    $t1, 0x000000
            li   $t2, 50 # startrow
            paint_black_rows:   
                mul  $t5, $t2, 256         # row * 256
                add  $t5, $t5, $t6
                add  $t5, $t5, $t0        # add base address      
                # paint 23 pixels in the row black
                li   $t7, 23              # counter
            draw_pixels_in_row:
                sw   $t1, 0($t5)          # draw black pixel
                addi  $t5, $t5, 4         # move to next pixel
                subi  $t7, $t7, 1         # decrementcolumn counter
                bnez  $t7, draw_pixels_in_row  # loop if more pixels to draw
                addi  $t2, $t2, 1         # increment row
                bgt   $t2, 54, done_painting  # exit if we've painted row 54
                j paint_black_rows
            done_painting:
                j game_loop
            
    display_paused_message:
        lw    $t0, ADDR_DSPL
        li    $t1, 0xffffff
        li  $t7, 0x000000
        li   $t2, 50               # startrow
        li   $t3, 14               # startCol
        # offset = (row*64 + col)*4 = row*256 + col*4
        mul  $t5, $t2, 256         # row * 256
        sll  $t6, $t3, 2           # col * 4
        add  $t5, $t5, $t6
        add  $t5, $t5, $t0         # add base address
        # draw row 1 of "paused"
        sw   $t1, 0($t5)           # draw white pixel
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        # draw row 2 of "paused"
        addi  $t5, $t5, 172        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 16        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 16        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8       
        sw   $t1, 0($t5)
        # draw row 3 of "paused"
        addi  $t5, $t5, 168        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        # draw row 4 of "paused"
        addi  $t5, $t5, 168        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 16        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 16        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 16        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        # draw row 5 of "paused"
        addi  $t5, $t5, 168        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 16        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 8        
        sw   $t1, 0($t5)
        addi  $t5, $t5, 4        
        sw   $t1, 0($t5)
        jr $ra                 # Return
    
    check_orientation_w:
        jal check_orientation     # Call helper function to determine orientation
        beq $v0, 1, respond_to_w  # If horizontal, branch to appropriate handler
        beq $v0, 2, respond_to_w_2 # If vertical, branch to appropriate handler
        j game_loop               # If neither, return to game loop
    
    check_orientation_a:
        jal check_orientation     # Call helper function to determine orientation
        beq $v0, 1, respond_to_a_hor # If horizontal, branch to appropriate handler
        beq $v0, 2, respond_to_a_vert # If vertical, branch to appropriate handler
        j game_loop               # If neither, return to game loop
        
    check_orientation_s:
        jal check_orientation           # Call helper function to determine orientation
        beq $v0, 1, respond_to_s_hor    # If horizontal, branch to appropriate handler
        beq $v0, 2, respond_to_s_vert   # If vertical, branch to appropriate handler
        j game_loop                     # If neither, return to game loop
    
    check_orientation_d:
        jal check_orientation           # Call helper function to determine orientation
        beq $v0, 1, respond_to_d_hor    # If horizontal, branch to appropriate handler
        beq $v0, 2, respond_to_d_vert   # If vertical, branch to appropriate handler
        j game_loop                     # If neither, return to game loop
    
    # Orientation helper function
    # Returns in $v0: 1 for horizontal, 2 for vertical
    check_orientation:
        lw $t0, ADDR_DSPL         # get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        sub $t5, $t2, $t1         # calculate offset difference
        
        # Check for horizontal orientation (difference of 4)
        li $t6, 4
        beq $t5, $t6, horizontal_orientation
        
        # Check for vertical orientation (difference of 256)
        li $t6, 256
        beq $t5, $t6, vertical_orientation
        
    horizontal_orientation:
        li $v0, 1                 # Set return value to 1 (horizontal)
        jr $ra                    # Return to caller
        
    vertical_orientation:
        li $v0, 2                 # Set return value to 2 (vertical)
        jr $ra                    # Return to caller
    
    store_pill:
        addiu $sp, $sp, -36         # Allocate stack space (9 words)
        sw $ra, 0($sp)              # Save return address
        sw $s0, 4($sp)              # Preserve s0
        sw $s1, 8($sp)              # Preserve s1
        sw $s2, 12($sp)             # Preserve s2
        sw $s3, 16($sp)             # Preserve s3
        sw $s4, 20($sp)             # Preserve s4
        sw $s5, 24($sp)             # Preserve s5
        sw $s6, 28($sp)             # Preserve s6
        sw $s7, 32($sp)             # Preserve s7
    
        lw $s0, ADDR_DSPL           # s0 = display base address
        lw $s1, pill_left_offset    # s1 = left pill offset
        lw $s2, pill_right_offset   # s2 = right pill offset
    
        # determine pill orientation using offset difference
        sub $t0, $s2, $s1           # t0 = right_offset - left_offset
        li $t1, 4                   # Horizontal pills have 4-byte difference
        beq $t0, $t1, horizontal_orient
        li $t1, 256                 # Vertical pills have 256-byte (1 row) difference
        beq $t0, $t1, vertical_orient
        j end_store_pill            # Invalid orientation (shouldn't happen)
    
    horizontal_orient:
        move $a0, $s1               # Arg1: left pill offset
        li $a1, 5                  # Arg2: type code
        jal store_pill_part         # Store left pill part
        move $a0, $s2               # Arg1: right pill offset
        li $a1, 3                  # Arg2: type code
        jal store_pill_part         # Store right pill part
        j end_store_pill
    
    vertical_orient:
        move $a0, $s1               # Arg1: left pill offset
        li $a1, 6                  # Arg2: type code
        jal store_pill_part         # Store left pill part
        move $a0, $s2               # Arg1: right pill offset
        li $a1, 4                  # Arg2: type code
        jal store_pill_part         # Store right pill part
    
    end_store_pill:
        # Restore registers and return
        lw $ra, 0($sp)              # Restore return address
        lw $s0, 4($sp)              # Restore s0
        lw $s1, 8($sp)              # Restore s1
        lw $s2, 12($sp)             # Restore s2
        lw $s3, 16($sp)             # Restore s3
        lw $s4, 20($sp)             # Restore s4
        lw $s5, 24($sp)             # Restore s5
        lw $s6, 28($sp)             # Restore s6
        lw $s7, 32($sp)             # Restore s7
        addiu $sp, $sp, 36          # Deallocate stack space
        jr $ra                      # Return to caller
    
    store_pill_part: # args: a0 = display offset, a1 = type code
        addiu $sp, $sp, -24         # Allocate stack space (6 words)
        sw $ra, 0($sp)              # Save return address
        sw $s0, 4($sp)              # Preserve s0
        sw $s1, 8($sp)              # Preserve s1
        sw $s2, 12($sp)             # Preserve s2
        sw $s3, 16($sp)             # Preserve s3
        sw $s4, 20($sp)             # Preserve s4
    
        lw $s0, ADDR_DSPL           # s0 = display base address
        add $s1, $s0, $a0           # s1 = absolute display address
        lw $s2, 0($s1)              # s2 = RGB color value
    
        # Convert display offset to board coordinates
        sub $t0, $s1, $s0           # t0 = offset from display base
        srl $t0, $t0, 2             # Convert bytes->pixels (divide by 4)
        li $t1, 64                  # 64 pixels per row
        div $t0, $t1                # Divide pixel offset by 64
        mflo $s3                    # s3 = display row (quotient)
        mfhi $s4                    # s4 = display column (remainder)
        addi $s3, $s3, -7           # board_row = display_row - 7
        addi $s4, $s4, -3           # board_col = display_col - 3
    
        # Calculate board memory address
        lw $s5, ADDR_BOARD          # s5 = board base address
        mul $t0, $s3, 24            # t0 = board_row * 24 columns
        add $t0, $t0, $s4           # t0 += board_col
        sll $t0, $t0, 2             # t0 *= 4 (bytes per cell)
        add $s6, $s5, $t0           # s6 = absolute board address
    
        # Store type and color components
        # sb $a1, 0($s6)              # Store type code in byte 0
        # srl $t0, $s2, 16            # Extract red component (bits 16-23)
        # sb $t0, 1($s6)              # Store red in byte 1
        # srl $t0, $s2, 8             # Extract green component (bits 8-15)
        # andi $t0, $t0, 0xFF         # Mask to 8 bits
        # sb $t0, 2($s6)              # Store green in byte 2
        # andi $t0, $s2, 0xFF         # Extract blue component (bits 0-7)
        # sb $t0, 3($s6)              # Store blue in byte 3
        sb $a1, 0($s6)              # Store type code in byte 0
        andi $t0, $s2, 0xFF         # Extract blue component
        sb   $t0, 1($s6)            # Store blue in byte 1
        srl  $t0, $s2, 8            # Shift right by 8 bits
        andi $t0, $t0, 0xFF         # Mask to 8 bits
        sb   $t0, 2($s6)            # Store green in byte 2
        srl  $t0, $s2, 16           # Shift right by 16 bits
        andi $t0, $t0, 0xFF         # Mask to 8 bits (optional for consistency)
        sb   $t0, 3($s6)            # Store red in byte 3
        
        lw $ra, 0($sp)              # Restore return address
        lw $s0, 4($sp)              # Restore s0
        lw $s1, 8($sp)              # Restore s1
        lw $s2, 12($sp)             # Restore s2
        lw $s3, 16($sp)             # Restore s3
        lw $s4, 20($sp)             # Restore s4
        addiu $sp, $sp, 24          # Deallocate stack space
        jr $ra                      # Return to caller
    
    respond_to_s_vert:
        lw $t0, ADDR_DSPL # get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 # gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        lw $s0, 0($t3)
        lw $s1, 0($t4)
        li $t7, 0 
        
        addi $t5, $t1, 256  # get offset of the left pixel
        add $t5, $t5, $t0 # Add base address to get memory address
        addi $t6, $t2, 256  # get offset of the right pixel
        add $t6, $t6, $t0
        
        # check for bottom collision
        lw $t9, 0($t6)             # load the pixel color under the pill
        bne $t9, $t7, skip_move_regenerate # if new cell is white, skip moving
        
        sw $s0, 0($t5)
        sw $s1, 0($t6)
        sw $t7, 0($t3)
        addi $t2, $t2, 256
        addi $t1, $t1, 256
        sw $t1, pill_left_offset
        sw $t2, pill_right_offset
        j game_loop
        
    respond_to_s_hor:
        lw $t0, ADDR_DSPL # get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 # gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        lw $s0, 0($t3)
        lw $s1, 0($t4)
        li $t7, 0 
        
        addi $t5, $t1, 256  # get offset of the right pixel
        add $t5, $t5, $t0 # Add base address to get memory address
        addi $t6, $t2, 256  # get offset of the left pixel
        add $t6, $t6, $t0
        
        # check for bottom collision
        lw $t9, 0($t5) 
        bne $t9, $t7, skip_move_regenerate    
        lw $t9, 0($t6)             # load the pixel color under the pill     
        bne $t9, $t7, skip_move_regenerate  # if new cell is white, skip moving and generate new pill
    
        sw $s0, 0($t5)
        sw $s1, 0($t6)
        sw $t7, 0($t3) #code for horizontal
        sw $t7, 0($t4)
    
        addi $t2, $t2, 256
        addi $t1, $t1, 256
        sw $t1, pill_left_offset
        sw $t2, pill_right_offset
        j game_loop
        
        
    respond_to_a_vert:
        lw $t0, ADDR_DSPL # get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 # gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        lw $s0, 0($t3)
        lw $s1, 0($t4)
        
        addi $t5, $t1, -4  # get offset of the left pixel
        add $t5, $t5, $t0 # Add base address to get memory address
        addi $t6, $t2, -4  # get offset of the right pixel
        add $t6, $t6, $t0
        
        # check for wall collision
        lw $t9, 0($t5)             # load the pixel color to the left of pill
        lw $t8, 0($t6)
        li $s3, 0x000000        
        bne $t9, $s3, skip_move  # if new cell is not black, skip moving
        bne $t8, $s3, skip_move  # if new cell is not black, skip moving
        
        sw $s0, 0($t5)
        sw $s1, 0($t6)
        li $t7, 0 
        sw $t7, 0($t3)
        sw $t7, 0($t4) # code for vertical
        addi $t2, $t2, -4
        addi $t1, $t1, -4
        sw $t1, pill_left_offset
        sw $t2, pill_right_offset
        j game_loop
    
    respond_to_a_hor:
        lw $t0, ADDR_DSPL #get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 # gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        lw $s0, 0($t3) # save current pill info
        lw $s1, 0($t4)
        
        addi $t5, $t1, -4  # get offset of the left pixel    
        add $t5, $t5, $t0 # Add base address to get memory address
        addi $t6, $t2, -4  # get offset of the right pixel
        add $t6, $t6, $t0
        
        # check for left wall collision
        lw $t9, 0($t5)             # load the pixel color to the left of pill
        li $s3, 0x000000        
        bne $t9, $s3, skip_move  # if new cell is not black, skip moving
        
        li $t7, 0 
        sw $t7, 0($t4)
        sw $s0, 0($t5)
        sw $s1, 0($t6)
        
        addi $t2, $t2, -4
        addi $t1, $t1, -4
        sw $t1, pill_left_offset
        sw $t2, pill_right_offset
        j game_loop
        
        skip_move:
        j game_loop
        
        skip_move_regenerate:
        jal store_pill   # Store current pill into game board memory
        jal check_horizontal_left_pill
        jal check_horizontal_right_pill
        jal check_vertical_left_pill
        jal check_vertical_right_pill
        j game_loop
    
    respond_to_d_hor:
        lw $t0, ADDR_DSPL # get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 # gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        lw $s0, 0($t3)
        lw $s1, 0($t4)
        
        addi $t5, $t1, 4  # get offset of the left pixel
        add $t5, $t5, $t0 # Add base address to get memory address
        addi $t6, $t2, 4  # get offset of the right pixel
        add $t6, $t6, $t0
        
        # check for right wall collision
        lw $t9, 0($t6)             # load the pixel color to the right of pill
        li $s3, 0x000000        
        bne $t9, $s3, skip_move  # if new cell is not black, skip moving
        
        li $t7, 0
        sw $t7, 0($t3)
        sw $s0, 0($t5)
        sw $s1, 0($t6)
        addi $t2, $t2, 4
        addi $t1, $t1, 4
        sw $t1, pill_left_offset
        sw $t2, pill_right_offset
        
        j game_loop
    
    respond_to_d_vert:
        lw $t0, ADDR_DSPL # get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 # gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        lw $s0, 0($t3)
        lw $s1, 0($t4)
        
        addi $t5, $t1, 4  # get offset of the left pixel
        add $t5, $t5, $t0 # Add base address to get memory address
        addi $t6, $t2, 4  # get offset of the right pixel
        add $t6, $t6, $t0
        
        # check for right wall collision
        lw $t9, 0($t5)             # load the pixel color to the right of pill
        lw $t8, 0($t6)
        li $s3, 0x000000        
        bne $t9, $s3, skip_move  # if new cell is not black, skip moving
        bne $t8, $s3, skip_move  # if new cell is not black, skip moving
        
        li $t7, 0
        sw $t7, 0($t3)
        sw $t7, 0($t4)
        sw $s0, 0($t5)
        sw $s1, 0($t6)
        addi $t2, $t2, 4
        addi $t1, $t1, 4
        sw $t1, pill_left_offset
        sw $t2, pill_right_offset
        
        j game_loop
    
    respond_to_w:
        lw $t0, ADDR_DSPL # get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 # gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        
        lw $s0, 0($t3)
        lw $s1, 0($t4)
        
        addi $t5, $t1, 256        # Add 256 to get offset of pixel one row below
        add $t5, $t5, $t0 # Add base address to get memory address
    
        sw $s1, 0($t5)
        li $t6, 0            # Load black color (0) into $t6
        sw $t6, 0($t4)
        addi $t2, $t2, 252        # Update right pill offset
        sw $t2, pill_right_offset # Save back to memory
        j game_loop   
        
    respond_to_w_2:
        lw $t0, ADDR_DSPL #get address display again
        lw $t1, pill_left_offset
        lw $t2, pill_right_offset
        add $t3, $t1, $t0 #gets left pills addresss
        add $t4, $t2, $t0 # gets right pills address
        
        lw $s0, 0($t3)
        lw $s1, 0($t4)
        
        addi $t5, $t1, 4  # get offset of the right pixel
        add $t5, $t5, $t0 # Add base address to get memory address
    
        sw $s0, 0($t5) 
        li $t6, 0            # Load black color (0) into $t6
        sw $t6, 0($t4)
        
        sw $s1, 0($t3)
        
        addi $t2, $t2, -252        # Update right pill offset
        sw $t2, pill_right_offset # Save back to memory
        j game_loop
    
    paint_black:
        lw $t0, ADDR_DSPL       # Load base address of display
        addi $t1, $t0, 16384    # Calculate end address (64x64 pixels * 4 bytes)
    paint_black_loop:
        sw $zero, 0($t0)        # Store black (0) at current address
        addi $t0, $t0, 4        # Move to next pixel
        bne $t0, $t1, paint_black_loop  # Loop until all pixels are black
        jr $ra                  # Return from function
        
    init_board: # Initializes 33x24 board to empty (type = 0, color = black)
        lw $t0, ADDR_BOARD # t0 stores board address
        li $t1, 0          # row = 0
        init_board_row_loop:
        li $t2, 0          # col = 0
        init_board_col_loop:
        # calculate offset (row * 24 + col) * 4
        mul $t3, $t1, 24  # t3 = row * 24
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
        add $t5, $zero, $zero   # loop variable
        addi $t6, $zero, 34     # height
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
        addi $t6, $zero, 34     # height
        addi $t8, $t0, 1648     # row 6 col 28
        draw_right_wall:
            sw $t4, 0($t8)      # Draw white pixel at $t8
            addi $t5, $t5, 1    # Increment counter
            addi $t8, $t8, 256  # Move down one row
            blt $t5, $t6, draw_right_wall
            
        # draw left half of top of bottle
        add $t5, $zero, $zero   # Reset 
        addi $t6, $zero, 10
        addi $t8, $t0, 1548  # row 5 col 3
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
    
    generate_draw_viruses:
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
        addi $a0, $a0, 1 # changes random number to a col between 1 and 24
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
        sw $t5, pill_left_offset
    
        jal generate_random_block_color  # repeat for the bottom half
        move $a0, $v0  # move color to $a0 for drawing
        li $t5, 1088 # position is col 64, row 4
        addu $t6, $t0, $t5 # add offset to start location
        sw $a0, 0($t6) # draw the pixel
        sw $t5, pill_right_offset
    
        lw $ra, 0($sp)    # return
        addiu $sp, $sp, 4
        jr $ra
        
    check_horizontal_left_pill:
        # Setup: Get pill address and color
        lw $t0, ADDR_DSPL             # Get display base address
        lw $t1, pill_left_offset      # Get left pill offset
        add $t3, $t1, $t0             # Get left pill's address
        lw $s0, 0($t3)                # Get color of left pill
        
        beqz $s0, no_match            # black  thus no match
        
        # Initialize check variables
        addi $t4, $t3, -16            # Start 4 positions to the left
        li $t5, 0                     # Position counter (0-6)
        li $t6, 0                     # Consecutive match counter
        move $t7, $zero               # match addy
        
        j scan_loop_left
        
    scan_loop_left:
    # Check if we've reached the end of loop
    slti $t9, $t5, 8              # strange syntax, otheres werent wotkng 
    beqz $t9, no_match            # If $t5 >= 8, exit this
    
    # Check current position
    lw $t8, 0($t4)                # Load color
    bne $t8, $s0, reset_counter_left  # If colors don't match, reset counter

    beqz $t6, mark_start_left     # If first match, remember position
    j increment_counter_left 
    
    no_match:
        jr $ra
        
    reset_counter_left:
        li $t6, 0                     # Reset match counter
        addi $t4, $t4, 4              # Move right one pixel
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_left
    
    mark_start_left:
        move $t7, $t4 
        j increment_counter_left  
        
    increment_counter_left:
        addi $t6, $t6, 1    
        
        beq $t6, 4, deal_with_hor      # If 4 matches, we found a sequence!
        
        # Move to next position
        addi $t4, $t4, 4              # Move right one pixel
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_left
        
    deal_with_hor:
        addi   $sp, $sp, -16      # allocate space for 4 registers
        sw     $ra, 0($sp)        # save return address
        sw     $s0, 4($sp)        # save $s0
        sw     $s3, 8($sp)        # save $s3
        sw     $t7, 12($sp)       # save $t7
        move $s0, $t7
        # s0 has it's original value, used later to check 5 in a row
        li $s3, 0
        sw $s3, 0($t7)
        sw $s3, 4($t7)
        sw $s3, 8($t7)
        sw $s3, 12($t7)
        
        move   $a0, $t7         # $a0 = display offset for block 1
        jal    store_cleared_block
    
        # Block 2 at $t7 + 4
        addi   $a0, $t7, 4
        jal    store_cleared_block
    
        # Block 3 at $t7 + 8
        addi   $a0, $t7, 8
        jal    store_cleared_block
    
        # Block 4 at $t7 + 12
        addi   $a0, $t7, 12
        jal    store_cleared_block
        
        lw     $t7, 12($sp)       # restore $t7
        lw     $s3, 8($sp)        # restore $s3
        lw     $s0, 4($sp)        # restore $s0
        lw     $ra, 0($sp)        # restore return address
        addi   $sp, $sp, 16       # deallocate stack frame
        jr     $ra                # return to caller
 
    store_cleared_block:
        addiu  $sp, $sp, -32        # Allocate stack space for 8 registers
        sw     $ra, 0($sp)          # Save return address
        sw     $a0, 4($sp)          # Save a0 (board row)
        sw     $a1, 8($sp)          # Save a1 (board col)
        sw     $s0, 12($sp)
        sw     $s1, 16($sp)
        sw     $s2, 20($sp)
        sw     $s3, 24($sp)
        sw     $s4, 28($sp)
    
        lw     $s0, ADDR_DSPL      # s0 = display base address
        # Subtract the base so that $t0 is now a relative offset.
        sub    $t0, $a0, $s0       # t0 = relative offset (in bytes)
        srl    $t0, $t0, 2         # convert byte offset to pixel offset
        
        li     $t1, 64              # display has 64 pixels per row
        div    $t0, $t1            # divide pixel offset by 64
        mflo   $s3                # s3 = display row
        mfhi   $s4                # s4 = display column
        addi   $s3, $s3, -7       # board_row = display_row - 7
        addi   $s4, $s4, -3       # board_col = display_col - 3
    
        # Calculate board memory address for this cell.
        lw     $s5, ADDR_BOARD    # s5 = board base address
        mul    $t0, $s3, 24       # t0 = board_row * 24 columns
        add    $t0, $t0, $s4      # t0 = board_row * 24 + board_col
        sll    $t0, $t0, 2        # t0 = byte offset (each cell is 4 bytes)
        add    $s6, $s5, $t0      # s6 = absolute board address
    
        # Write type and color into the board.
        sb     $zero, 0($s6)        # Store type (0) in byte 0.
        li     $t2, 0             # Black color (0x000000).
        sb     $t2, 1($s6)        # red = 0
        sb     $t2, 2($s6)        # green = 0
        sb     $t2, 3($s6)        # blue = 0
        
        move   $a0, $s3         # a0 = board row
        move   $a1, $s4         # a1 = board col
        jal    update_orphaned_neighbors
    
        lw     $ra, 0($sp)         # Restore registers
        lw     $a0, 4($sp)
        lw     $a1, 8($sp)
        lw     $s0, 12($sp)
        lw     $s1, 16($sp)
        lw     $s2, 20($sp)
        lw     $s3, 24($sp)
        lw     $s4, 28($sp)
        addiu  $sp, $sp, 32
        jr     $ra
     
    check_horizontal_right_pill:
        # Setup: Get pill address and color
        lw $t0, ADDR_DSPL             # Get display base address
        lw $t1, pill_right_offset     # Get right pill offset
        add $t3, $t1, $t0             # Get right pill's address
        lw $s0, 0($t3)                # Get color of right pill
        
        beqz $s0, no_match            # Skip if pill is empty/black
        
        # Initialize check variables - start scanning from right pill position
        addi $t4, $t3, -16            # Start 4 positions to the left
        li $t5, 0                     # Position counter (0-7)
        li $t6, 0                     # Consecutive match counter
        move $t7, $zero               # Starting match address
        
        j scan_loop_right
        
    scan_loop_right:
        # Check if we've reached the end of loop
        slti $t9, $t5, 8              # Set $t9 to 1 if $t5 < 8, else 0
        beqz $t9, no_match            # If $t5 >= 8, exit loop
        
        lw $t8, 0($t4)                # Load color at current position
        bne $t8, $s0, reset_counter_right  # If colors don't match, reset counter
        
        # We found a matching color
        beqz $t6, mark_start_right    # If first match, remember position
        j increment_counter_right 
    
    reset_counter_right:
        li $t6, 0                     # Reset match counter
        addi $t4, $t4, 4              # Move right one pixel
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_right
    
    mark_start_right:
        move $t7, $t4  
        j increment_counter_right
        
    increment_counter_right:
        addi $t6, $t6, 1    
        
        beq $t6, 4, deal_with_hor     # If 4 matches, we found a sequence!
        
        # Move to next position
        addi $t4, $t4, 4              # Move right one pixel
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_right
        
    check_vertical_left_pill:
        # Setup: Get pill address and color
        lw $t0, ADDR_DSPL             # Get display base address
        lw $t1, pill_left_offset      # Get left pill offset
        add $t3, $t1, $t0             # Get left pill's address
        lw $s0, 0($t3)                # Get color of left pill
        
        beqz $s0, vert_no_match_left  # Skip if pill is empty/black
        
        # Initialize check variables
        addi $t4, $t3, -1024          # Start 4 positions up (4*256 = 1024)
        li $t5, 0                     # Position counter (0-7)
        li $t6, 0                     # Consecutive match counter
        move $t7, $zero               # Starting match address
        
        j scan_loop_vert_left
        
    scan_loop_vert_left:
        # Check if we've reached the end of loop
        slti $t9, $t5, 8              # Set $t9 to 1 if $t5 < 8, else 0
        beqz $t9, vert_no_match_left  # If $t5 >= 8, exit loop
        
        lw $t8, 0($t4)                # Load color at current position
        bne $t8, $s0, reset_counter_vert_left  # If colors don't match, reset counter
        
        # We found a matching color
        beqz $t6, mark_start_vert_left # If first match, remember position
        j increment_counter_vert_left
    
    vert_no_match_left:
        jr $ra
        
    vert_no_match_right:
        j draw_pill 
    
    reset_counter_vert_left:
        li $t6, 0                     # Reset match counter
        addi $t4, $t4, 256            # Move down one row (256 bytes)
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_vert_left
    
    mark_start_vert_left:
        move $t7, $t4
        j increment_counter_vert_left
        
    increment_counter_vert_left:
        addi $t6, $t6, 1
        
        # Check for 4 matches
        beq $t6, 4, deal_with_vert     # If 4 matches, we found a sequence!
        
        # Move to next position
        addi $t4, $t4, 256            # Move down one row (256 bytes)
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_vert_left
        
    deal_with_vert:
        addi   $sp, $sp, -16      # allocate space for 4 registers
        sw     $ra, 0($sp)        # save return address
        sw     $s0, 4($sp)        # save $s0
        sw     $s3, 8($sp)        # save $s3
        sw     $t7, 12($sp)       # save $t7
        
        move $s0, $t7
        #s0 has it's original value, used later to check 5 in a row
        li $s3, 0
        sw $s3, 0($t7)
        sw $s3, 256($t7)
        sw $s3, 512($t7)
        sw $s3, 768($t7)
        # Block 1 at display offset in $t7.
        move   $a0, $t7         # $a0 = display offset for block 1
        jal    store_cleared_block
    
        # Block 2 at $t7 + 256 (next row)
        addi   $a0, $t7, 256
        jal    store_cleared_block
    
        # Block 3 at $t7 + 512 (two rows down)
        addi   $a0, $t7, 512
        jal    store_cleared_block
    
        # Block 4 at $t7 + 768 (three rows down)
        addi   $a0, $t7, 768
        jal    store_cleared_block
        
        lw     $t7, 12($sp)       # restore $t7
        lw     $s3, 8($sp)        # restore $s3
        lw     $s0, 4($sp)        # restore $s0
        lw     $ra, 0($sp)        # restore return address
        addi   $sp, $sp, 16       # deallocate stack frame
    
        
    check_vertical_right_pill:
        # Setup: Get pill address and color
        lw $t0, ADDR_DSPL             # Get display base address
        lw $t1, pill_right_offset     # Get right pill offset
        add $t3, $t1, $t0             # Get right pill's address
        lw $s0, 0($t3)                # Get color of right pill
        
        beqz $s0, vert_no_match_right # Skip if pill is empty/black
        
        # Initialize check variables
        addi $t4, $t3, -1024          # Start 4 positions up (4*256 = 1024)
        li $t5, 0                     # Position counter (0-7)
        li $t6, 0                     # Consecutive match counter
        move $t7, $zero               # Starting match address
        
        j scan_loop_vert_right
        
    scan_loop_vert_right:
        # Check if we've reached the end of loop
        slti $t9, $t5, 8              # Set $t9 to 1 if $t5 < 8, else 0
        beqz $t9, vert_no_match_right # If $t5 >= 8, exit loop
    
        lw $t8, 0($t4)                # Load color at current position
        bne $t8, $s0, reset_counter_vert_right  # If colors don't match, reset counter
        
        # We found a matching color
        beqz $t6, mark_start_vert_right # If first match, remember position
        j increment_counter_vert_right
    
    reset_counter_vert_right:
        li $t6, 0                     # Reset match counter
        addi $t4, $t4, 256            # Move down one row (256 bytes)
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_vert_right
    
    mark_start_vert_right:
        move $t7, $t4
        j increment_counter_vert_right
        
    increment_counter_vert_right:
        addi $t6, $t6, 1
        
        # Check for 4 matches (made consistent with left pill)
        beq $t6, 4, deal_with_vert      # If 4 matches, we found a sequence!
        
        # Move to next position
        addi $t4, $t4, 256            # Move down one row (256 bytes)
        addi $t5, $t5, 1              # Increment position counter
        j scan_loop_vert_right
        
    update_orphaned_neighbors:
        addiu  $sp, $sp, -28       # Allocate stack space for 7 registers
        sw     $ra, 0($sp)         # Save return address
        sw     $t0, 4($sp)
        sw     $t1, 8($sp)
        sw     $t2, 12($sp)
        sw     $t3, 16($sp)
        sw     $t4, 20($sp)
        sw     $t5, 24($sp)
    
        lw     $t0, ADDR_BOARD      # Load board base address into t0
    
        # Check left neighbor (cell at (row, col-1)) if col > 0.
        blez   $a1, check_right_neighbor   # if board col <= 0, skip left
        addi   $t1, $a1, -1         # t1 = col - 1
        mul    $t2, $a0, 24         # t2 = row * 24
        add    $t2, $t2, $t1        # t2 = row*24 + (col-1)
        sll    $t2, $t2, 2          # convert to byte offset
        add    $t2, $t0, $t2        # absolute address of left neighbor
        lb     $t3, 0($t2)          # load type from left neighbor
        beq  $t3, $zero, check_right_neighbor
        li     $t4, 5               # expected type for a left-half block (5)
        bne    $t3, $t4, check_right_neighbor
        li     $t4, 2               # update type to 2
        sb     $t4, 0($t2)          # store updated type
    check_right_neighbor:
        # Check right neighbor (cell at (row, col+1)) if col < 23.
        li     $t5, 23
        bge    $a1, $t5, check_above_neighbor  # if col >= 23, skip right neighbor
        addi   $t1, $a1, 1          # t1 = col + 1
        mul    $t2, $a0, 24         # t2 = row * 24
        add    $t2, $t2, $t1        # t2 = row*24 + (col+1)
        sll    $t2, $t2, 2          # convert to byte offset
        add    $t2, $t0, $t2        # absolute address of right neighbor
        lb     $t3, 0($t2)          # load type from right neighbor
        beq  $t3, $zero, check_above_neighbor
        li     $t4, 3               # expected type for a right-half block (3)
        bne    $t3, $t4, check_above_neighbor
        li     $t4, 2               # update type to 2
        sb     $t4, 0($t2)          # store updated type
    check_above_neighbor:
        # Check above neighbor (cell at (row-1, col)) if row > 0.
        blez   $a0, check_below_neighbor   # if row <= 0, skip above neighbor
        addi   $t1, $a0, -1         # t1 = row - 1
        mul    $t2, $t1, 24         # t2 = (row-1) * 24
        add    $t2, $t2, $a1        # t2 = (row-1)*24 + col
        sll    $t2, $t2, 2          # convert to byte offset
        add    $t2, $t0, $t2        # absolute address of above neighbor
        lb     $t3, 0($t2)          # load type from above neighbor
        beq  $t3, $zero, check_below_neighbor
        li     $t4, 6               # expected type for a top-half block (6)
        bne    $t3, $t4, check_below_neighbor
        li     $t4, 2               # update type to 2
        sb     $t4, 0($t2)          # store updated type
    check_below_neighbor:
        # Check below neighbor (cell at (row+1, col)) if row < 32.
        li     $t5, 32
        bge    $a0, $t5, finish_update  # if row >= 32, skip below neighbor
        addi   $t1, $a0, 1          # t1 = row + 1
        mul    $t2, $t1, 24         # t2 = (row+1) * 24
        add    $t2, $t2, $a1        # t2 = (row+1)*24 + col
        sll    $t2, $t2, 2          # convert to byte offset
        add    $t2, $t0, $t2        # absolute address of below neighbor
        lb     $t3, 0($t2)          # load type from below neighbor
        beq  $t3, $zero, finish_update
        li     $t4, 4               # expected type for a bottom-half block (4)
        bne    $t3, $t4, finish_update
        li     $t4, 2               # update type to 2
        sb     $t4, 0($t2)          # store updated type
    finish_update:
        lw     $ra, 0($sp)
        lw     $t0, 4($sp)
        lw     $t1, 8($sp)
        lw     $t2, 12($sp)
        lw     $t3, 16($sp)
        lw     $t4, 20($sp)
        lw     $t5, 24($sp)
        addiu  $sp, $sp, 28
        jr     $ra                
        
    game_over:
        jal display_retry_message
        game_over_loop:
            li $v0, 32                    
            li $a0, 17                    # Sleep for 17 milliseconds
            syscall 
            lw $t0, ADDR_KBRD             # Check for key press
            lw $t9, 0($t0)
            beq $t9, 1, check_retry_key   # If key pressed, check if it's 'r'
            j game_over_loop
        check_retry_key:
            lw $a0, 4($t0)                # Load the pressed key
            beq $a0, 0x72, reset_game     
            j game_over_loop              # Continue loop if not 'r'
        reset_game:
            jal paint_black
            sw $zero, gravity_counter     # Reset gravity counter
            li $t1, 1084                  # Initial pill positions
            sw $t1, pill_left_offset
            li $t2, 1088
            sw $t2, pill_right_offset
            li $t3, 60
            sw $t3, gravity_interval
            # Re-initialize the game board and elements
            jal init_board                 # Clear the board
            jal draw_bottle                # Redraw the bottle
            jal generate_draw_viruses      # Generate new viruses
            jal draw_pill                  # Draw new pill
            j game_loop                   # Restart the game loop
        display_retry_message:
            addi $sp, $sp, -4
            sw $ra, 0($sp)  
            jal paint_black
            lw    $t0, ADDR_DSPL          # Load display address
            li    $t1, 0xffffff           # White color
            li    $t2, 25                 # Starting row
            li    $t3, 14                 # Starting column
            # offset = (row*64 + col)*4 = row*256 + col*4
            mul  $t5, $t2, 256         # row * 256
            sll  $t6, $t3, 2           # col * 4
            add  $t5, $t5, $t6
            add  $t5, $t5, $t0         # add base address
            # draw row 1 of retry message
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 20
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            # draw row 2 of retry
            addi  $t5, $t5, 160    
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 16
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 20
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            # draw row 3 of retry
            addi  $t5, $t5, 160  
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            # draw row 4 of retry
            addi  $t5, $t5, 164
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 16
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 24
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            # draw row 5 of retry
            addi  $t5, $t5, 160  
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 4
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            addi  $t5, $t5, 12
            sw   $t1, 0($t5)
            addi  $t5, $t5, 24
            sw   $t1, 0($t5)
            addi  $t5, $t5, 8
            sw   $t1, 0($t5)
            
            lw $ra, 0($sp)         # Restore return address
            addi $sp, $sp, 4
            jr $ra
            
    # Iterates 10 passes over the board (33 rows × 24 cols). For each cell:
    #  - If the type is 0 or 1, nothing is done.
    #  - For type 2,4,5: if the cell immediately below is empty then copy the block
    #    one row down and clear the original.
    #  - For type 3 (horizontal pill right–half): if not at bottom or left edge,
    #    and both the cell directly below and the one below the left neighbor are empty,
    #    then drop both the current cell and its left partner.
    #  - For type 6 (vertical pill top–half): if row+2 is in bounds and the cell two rows
    #    down is empty, then drop both this cell and the one immediately below.
    drop_all_blocks:
        addiu  $sp, $sp, -68
        sw     $ra, 0($sp)
        sw     $s0, 4($sp)
        sw     $s1, 8($sp)
        sw     $s2, 12($sp)
        sw     $s3, 16($sp)
        sw     $s4, 20($sp)
        sw     $s5, 24($sp)
        sw     $s6, 28($sp)
        sw     $s7, 32($sp)
        sw     $t0, 36($sp)
        sw     $t1, 40($sp)
        sw     $t2, 44($sp)
        sw     $t3, 48($sp)
        sw     $t4, 52($sp)
        sw     $t5, 56($sp)
        sw     $t6, 60($sp)
        sw     $t7, 64($sp)
    
        lw     $s0, ADDR_BOARD
        li     $s1, 10       # Use $s1 as our pass counter (10 passes)
    
    drop_pass_loop:
        beqz   $s1, drop_all_blocks_end
        addi   $s1, $s1, -1
    
        li     $s2, 31     # For each pass, iterate rows (we process rows 31 downto 0)
    row_loop:
        bltz   $s2, end_of_pass   # when row index becomes negative, finish pass
        li     $s3, 0     # Set col index = 0 for each row
    
    col_loop:
        bge    $s3, 24, next_row  # if col >= 24, go to next row
    
        # Compute current cell address:
        #   offset = ((row * 24) + col) * 4, then add board base in $s0.
        mul    $t0, $s2, 24
        add    $t0, $t0, $s3
        sll    $t0, $t0, 2
        add    $t0, $s0, $t0
    
        # Load cell type (stored as the first byte)
        lb     $t1, 0($t0)
    
        # If type is 0 or 1, do nothing.
        li     $t2, 0
        beq    $t1, $t2, cell_end
        li     $t2, 1
        beq    $t1, $t2, cell_end
    
        # For types 2, 4, and 5: drop normally.
        li     $t2, 2
        beq    $t1, $t2, drop_normal
        li     $t2, 4
        beq    $t1, $t2, drop_normal
        li     $t2, 5
        beq    $t1, $t2, drop_normal
    
        # For type 3 (horizontal pill, right half)
        li     $t2, 3
        beq    $t1, $t2, drop_horizontal
    
        # For type 6 (vertical pill, top half)
        li     $t2, 6
        beq    $t1, $t2, drop_vertical
    
        j      cell_end   # If type not handled, do nothing
    
    # drop_normal:  For types 2,4,5.
    # If the cell is not in the bottom row, check the cell immediately below.
    # If below is empty, move the block down one row.
    drop_normal:
        # Prologue: Save all registers (even temporary ones)
        addiu  $sp, $sp, -68
        sw     $ra, 64($sp)
        sw     $s0, 60($sp)
        sw     $s2, 56($sp)
        sw     $s3, 52($sp)
        sw     $t0, 48($sp)
        sw     $t1, 44($sp)
        sw     $t2, 40($sp)
        sw     $t3, 36($sp)
        sw     $t4, 32($sp)
        sw     $t5, 28($sp)
        sw     $t6, 24($sp)
        sw     $t7, 20($sp)
        sw     $t8, 16($sp)
        sw     $t9, 12($sp)
        sw     $a0, 8($sp)
        sw     $a1, 4($sp)
        sw     $a2, 0($sp)
    
        # If current board row ($s2) == 32, we are at the bottom.
        li     $t2, 32
        beq    $s2, $t2, drop_normal_end
    
        # Compute destination cell address:
        addi   $t3, $s2, 1         # new row = s2+1
        mul    $t4, $t3, 24        # t4 = (s2+1)*24
        add    $t4, $t4, $s3       # t4 = (s2+1)*24 + s3
        sll    $t4, $t4, 2         # multiply by 4 to get byte offset
        add    $t4, $s0, $t4       # t4 = destination cell address
    
        # Check that destination is empty:
        lb     $t5, 0($t4)
        li     $t6, 0
        bne    $t5, $t6, drop_normal_end
    
        # Copy the block: load the source cell (at address in $t0)
        lw     $t7, 0($t0)
        sw     $t7, 0($t4)
        # Clear the source cell:
        sw     $zero, 0($t0)
    
        # Extract the 24–bit color (the cell’s word is [color (24 bits) | type (8 bits)])
        andi   $t8, $t7, 0xFFFFFF00  # mask out the type byte
        srl    $t8, $t8, 8         # now $t8 holds the proper 24–bit color
    
        # Update the display for the new (destination) cell:
        addi   $a0, $s2, 1         # board row = s2+1
        move   $a1, $s3            # board col stays the same
        move   $a2, $t8            # the extracted color
        jal    update_display
    
        # Update the display for the source cell (now cleared):
        move   $a0, $s2            # board row = s2 (source)
        move   $a1, $s3
        li     $a2, 0
        jal    update_display
    
    drop_normal_end:
        # Epilogue: Restore registers and return.
        lw     $a2, 0($sp)
        lw     $a1, 4($sp)
        lw     $a0, 8($sp)
        lw     $t9, 12($sp)
        lw     $t8, 16($sp)
        lw     $t7, 20($sp)
        lw     $t6, 24($sp)
        lw     $t5, 28($sp)
        lw     $t4, 32($sp)
        lw     $t3, 36($sp)
        lw     $t2, 40($sp)
        lw     $t1, 44($sp)
        lw     $t0, 48($sp)
        lw     $s3, 52($sp)
        lw     $s2, 56($sp)
        lw     $s0, 60($sp)
        lw     $ra, 64($sp)
        addiu  $sp, $sp, 68
        jr     $ra
    
    # drop_horizontal: For type 3 (horizontal pill right–half).
    # Ensure not on bottom row and not in leftmost column.
    # Check that both the cell directly below (for right half)
    # and the cell below the left partner are empty. Then drop both.
    drop_horizontal:
        # Prologue: Save all registers
        addiu  $sp, $sp, -68
        sw     $ra, 64($sp)
        sw     $s0, 60($sp)
        sw     $s2, 56($sp)
        sw     $s3, 52($sp)
        sw     $t0, 48($sp)
        sw     $t1, 44($sp)
        sw     $t2, 40($sp)
        sw     $t3, 36($sp)
        sw     $t4, 32($sp)
        sw     $t5, 28($sp)
        sw     $t6, 24($sp)
        sw     $t7, 20($sp)
        sw     $t8, 16($sp)
        sw     $t9, 12($sp)
        sw     $a0, 8($sp)
        sw     $a1, 4($sp)
        sw     $a2, 0($sp)
    
        # Must not be on bottom row, and there must be a left partner (col ≠ 0)
        li     $t2, 32
        beq    $s2, $t2, drop_horizontal_end
        beqz   $s3, drop_horizontal_end
    
        # Compute destination for right half: (s2+1, s3)
        addi   $t3, $s2, 1
        mul    $t4, $t3, 24
        add    $t4, $t4, $s3
        sll    $t4, $t4, 2
        add    $t4, $s0, $t4    # $t4 = dest address for right half
    
        # Compute destination for left half: (s2+1, s3-1)
        addi   $t7, $s2, 1       # new row for left half
        mul    $t5, $t7, 24
        addi   $t6, $s3, -1      # new col for left half = s3-1
        add    $t5, $t5, $t6
        sll    $t5, $t5, 2
        add    $t5, $s0, $t5    # $t5 = dest address for left half
    
        # Check that both destination cells are empty.
        lb     $t8, 0($t4)
        li     $t9, 0
        bne    $t8, $t9, drop_horizontal_end
        lb     $t8, 0($t5)
        bne    $t8, $t9, drop_horizontal_end
    
        # Get current block data:
        lw     $t6, 0($t0)       # current right half from cell at address in $t0
        # Compute current left partner address:
        mul    $t8, $s2, 24
        addi   $t7, $s3, -1
        add    $t8, $t8, $t7
        sll    $t8, $t8, 2
        add    $t8, $s0, $t8     # $t8 = current left partner address
        lw     $t7, 0($t8)       # current left half data
    
        # Extract 24–bit colors:
        andi   $t2, $t6, 0xFFFFFF00
        srl    $t2, $t2, 8       # $t2 now holds right half color
        andi   $t3, $t7, 0xFFFFFF00
        srl    $t3, $t3, 8       # $t3 now holds left half color
    
        # Move the blocks:
        sw     $t6, 0($t4)       # copy right half to destination
        sw     $t7, 0($t5)       # copy left half to destination
        sw     $zero, 0($t0)     # clear original right half cell
        sw     $zero, 0($t8)     # clear original left half cell
    
        # Update display for destination right half:
        addi   $a0, $s2, 1       # new row = s2+1
        move   $a1, $s3
        move   $a2, $t2         # color for right half
        jal    update_display
    
        # Update display for destination left half:
        addi   $a0, $s2, 1
        addi   $a1, $s3, -1
        move   $a2, $t3         # color for left half
        jal    update_display
    
        # Update display for cleared source cells:
        move   $a0, $s2         # source right half cell (s2, s3)
        move   $a1, $s3
        li     $a2, 0
        jal    update_display
    
        move   $a0, $s2         # source left half cell (s2, s3-1)
        addi   $a1, $s3, -1
        li     $a2, 0
        jal    update_display
    
    drop_horizontal_end:
        # Epilogue: Restore all registers and return.
        lw     $a2, 0($sp)
        lw     $a1, 4($sp)
        lw     $a0, 8($sp)
        lw     $t9, 12($sp)
        lw     $t8, 16($sp)
        lw     $t7, 20($sp)
        lw     $t6, 24($sp)
        lw     $t5, 28($sp)
        lw     $t4, 32($sp)
        lw     $t3, 36($sp)
        lw     $t2, 40($sp)
        lw     $t1, 44($sp)
        lw     $t0, 48($sp)
        lw     $s3, 52($sp)
        lw     $s2, 56($sp)
        lw     $s0, 60($sp)
        lw     $ra, 64($sp)
        addiu  $sp, $sp, 68
        jr     $ra
    
    # For type 6 (vertical pill top–half).
    # Check that the destination for the bottom half (row+2) is empty.
    drop_vertical:
        # Prologue: Save all registers.
        addiu  $sp, $sp, -68
        sw     $ra, 64($sp)
        sw     $s0, 60($sp)
        sw     $s2, 56($sp)
        sw     $s3, 52($sp)
        sw     $t0, 48($sp)
        sw     $t1, 44($sp)
        sw     $t2, 40($sp)
        sw     $t3, 36($sp)
        sw     $t4, 32($sp)
        sw     $t5, 28($sp)
        sw     $t6, 24($sp)
        sw     $t7, 20($sp)
        sw     $t8, 16($sp)
        sw     $t9, 12($sp)
        sw     $a0, 8($sp)
        sw     $a1, 4($sp)
        sw     $a2, 0($sp)
    
        # For a vertical drop, we require that s2 < 31.
        li     $t2, 31
        bge    $s2, $t2, drop_vertical_end
    
        # Compute destination for top half: (s2+1, s3)
        addi   $t3, $s2, 1         # row+1
        mul    $t4, $t3, 24
        add    $t4, $t4, $s3       # (s2+1)*24 + s3
        sll    $t4, $t4, 2
        add    $t4, $s0, $t4       # destination address for top half in $t4
    
        # Compute destination for bottom half: (s2+2, s3)
        addi   $t5, $s2, 2         # row+2
        mul    $t6, $t5, 24
        add    $t6, $t6, $s3       # (s2+2)*24 + s3
        sll    $t6, $t6, 2
        add    $t6, $s0, $t6       # destination address for bottom half in $t6
    
        # Check that the destination bottom cell is empty.
        lb     $t7, 0($t6)
        li     $t8, 0
        bne    $t7, $t8, drop_vertical_end
    
        # Move the top half:
        lw     $t9, 0($t0)         # load the top half from current cell (at [s2, s3])
        sw     $t9, 0($t4)         # store to destination top half
    
        # Extract top half color:
        andi   $t2, $t9, 0xFFFFFF00
        srl    $t2, $t2, 8         # $t2 now holds the top half’s 24–bit color
    
        # Compute source for bottom half: it is the cell immediately below the top half, i.e. (s2+1, s3)
        addi   $t7, $s2, 1
        mul    $t7, $t7, 24
        add    $t7, $t7, $s3
        sll    $t7, $t7, 2
        add    $t7, $s0, $t7       # $t7 is now the source address for bottom half
    
        # Move the bottom half:
        lw     $t9, 0($t7)         # load bottom half from its source cell
        sw     $t9, 0($t6)         # store to destination bottom half
    
        # Extract bottom half color:
        andi   $t3, $t9, 0xFFFFFF00
        srl    $t3, $t3, 8         # $t3 now holds the bottom half’s 24–bit color
    
        # Clear the original source cells:
        sw     $zero, 0($t0)       # clear top half cell at [s2, s3]
        sw     $zero, 0($t7)       # clear bottom half cell at [s2+1, s3]
    
        # Update display for the new top half:
        addi   $a0, $s2, 1         # new board row = s2+1
        move   $a1, $s3
        move   $a2, $t2            # color from top half
        jal    update_display
    
        # Update display for the new bottom half:
        addi   $a0, $s2, 2         # new board row = s2+2
        move   $a1, $s3
        move   $a2, $t3            # color from bottom half
        jal    update_display
    
        # Update display for the cleared old top half:
        move   $a0, $s2           # row s2 (old top half)
        move   $a1, $s3
        li     $a2, 0
        jal    update_display
    
        # Update display for the cleared old bottom half:
        addi   $a0, $s2, 1         # row s2+1 (old bottom half)
        move   $a1, $s3
        li     $a2, 0
        jal    update_display
    
    drop_vertical_end:
        # Epilogue: Restore all registers and return.
        lw     $a2, 0($sp)
        lw     $a1, 4($sp)
        lw     $a0, 8($sp)
        lw     $t9, 12($sp)
        lw     $t8, 16($sp)
        lw     $t7, 20($sp)
        lw     $t6, 24($sp)
        lw     $t5, 28($sp)
        lw     $t4, 32($sp)
        lw     $t3, 36($sp)
        lw     $t2, 40($sp)
        lw     $t1, 44($sp)
        lw     $t0, 48($sp)
        lw     $s3, 52($sp)
        lw     $s2, 56($sp)
        lw     $s0, 60($sp)
        lw     $ra, 64($sp)
        addiu  $sp, $sp, 68
        jr     $ra
    
    cell_end:
        addi   $s3, $s3, 1        # Increment col index
        j      col_loop
    
    next_row:
        addi   $s2, $s2, -1       # Decrement row index
        j      row_loop
    
    end_of_pass:
        j      drop_pass_loop
    
    drop_all_blocks_end:
        # Restore registers.
        lw     $t7, 64($sp)
        lw     $t6, 60($sp)
        lw     $t5, 56($sp)
        lw     $t4, 52($sp)
        lw     $t3, 48($sp)
        lw     $t2, 44($sp)
        lw     $t1, 40($sp)
        lw     $t0, 36($sp)
        lw     $s7, 32($sp)
        lw     $s6, 28($sp)
        lw     $s5, 24($sp)
        lw     $s4, 20($sp)
        lw     $s3, 16($sp)
        lw     $s2, 12($sp)
        lw     $s1, 8($sp)
        lw     $s0, 4($sp)
        lw     $ra, 0($sp)
        addiu  $sp, $sp, 68
        jr     $ra
    
    update_display:
        # Save registers if needed (only using temporary $t registers here)
        lw   $t0, ADDR_DSPL       # $t0 = display base address
        addi $t1, $a0, 7          # display row = board row + 7
        li   $t2, 64
        mul  $t1, $t1, $t2        # $t1 = display row * 64
        addi $t3, $a1, 3          # display col = board col + 3
        add  $t1, $t1, $t3       # $t1 = (display row * 64) + display col
        sll  $t1, $t1, 2         # multiply by 4 to get byte offset
        add  $t1, $t0, $t1       # final display address
        sw   $a2, 0($t1)         # update pixel with color in $a2
        jr   $ra
