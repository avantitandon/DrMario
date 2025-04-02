# Dr. Mario Polyphonic Music Sample

.data
.align 2  # Ensure memory alignment
frame_counter:     .word 0     # Current frame count
melody_index:      .word 0     # Current position in melody
bass_index:        .word 0  
melody_active:     .word 1   # Current position in bass line
theme_song_speed:  .word 12    # Frames between notes
bass_active:       .word 0
intro_length:      .word 16
.align 2
melody_length:     .word 120
melody:   
         .word 70, 71, 70, 71, 69, 67, 67, 69, 
        .word 70, 71, 69, 67, 67, -2, -1
        .word 70, 71, 70, 71, 69, 67, 67, 69,
        .word 59, -2, 60, -2, 61, -2, 62, -2
        .word 70, 71, 70, 71, 69, 67, 67, 69, 
        .word 70, 71, 69, 67, 67, -2, -1
        .word 70, 71, 70, 71, 69, 67, 67, 69,
        .word 59, -2, 60, -2, 61, -2, 62, -2
        .word 75, 76, 75, 76, 74, 72, 72, 74
        .word 75, 76, 74, 72, 72, -1, -2
        .word 75, 76, 75, 76, 74, 72, 72, 74
        .word 66, 69, 72, 74, 72, -2, 71, -2
        .word 75, 76, 74, 72, 72, -1, -2
        .word 75, 76, 74, 72, 72, -1, -2
        .word 75, 76, 75, 76, 74, 72, 72, 74
        .word 72, -2, 74, -2, 72, -2
        
        
        
        
    

# -1 is a crotchet rest
# -2 is a semi quaver rest 
        
.align 2
bass_length: .word 16
# bassline: .word 43, 43, 46, 47, 48, 47, 46, 45
          # .word 43, 43, 46, 47, 48, 47, 46, 45
.text
.globl main

main:
    # Initialize music
    jal init_music
main_loop:
    li $v0, 32
    li $a0, 16
    syscall
    
    lw $t0, frame_counter
    addi $t0, $t0, 1
    sw $t0, frame_counter
    
    jal update_music
    
     j main_loop
     
init_music:
    li $t0, 0 
    sw $t0, melody_active
    li $t0, 1 
    sw $t0, bass_active
    
    jr $ra

# This is the fixed version of the update_music function:

update_music:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # load_frame_counter
    lw $s0, frame_counter
    
    # Check if it's time to play note
    lw $s1, theme_song_speed
    div $s0, $s1
    mfhi $s2
    bnez $s2, music_done
    
    # Check if melody is done and we need to reset everything
    lw $s0, melody_index
    lw $s1, melody_length
    blt $s0, $s1, continue_music  # If melody index < melody length, continue normally
    
    # Melody is complete, reset everything to start over with bass intro
    li $t0, 0
    sw $t0, melody_index  # Reset melody position
    sw $t0, bass_index    # Reset bass position
    sw $t0, melody_active  # Turn off melody until bass intro completes again
    j bass_only            # Jump to play bass only
    
continue_music:
    # Check if we should activate melody based on bass progression
    lw $s0, bass_index
    lw $s1, intro_length
    blt $s0, $s1, bass_only
    
    # We've passed the intro length, so ensure melody is active
    li $t0, 1
    sw $t0, melody_active
    
bass_only:
    # Play bass note (if active)
    lw $t0, bass_active
    beqz $t0, check_melody
    jal play_next_bass_note

check_melody:
    # Play melody note (if active)
    lw $t0, melody_active
    beqz $t0, music_done
    jal play_next_melody_note
    j music_done
    
    # Play both instruments - first bass then melody
    

    
    
skip_melody_check:
    # Play bass note 
    lw $t0, bass_active
    beqz $t0, skip_bass
    jal play_next_bass_note

skip_bass:
    
    # Play melody note if active
    lw $t0, melody_active
    beqz $t0, skip_melody
    jal play_next_melody_note
    
    
skip_melody:
    j music_done

    
play_next_melody_note:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    lw $s0, melody_index
    lw $s1, melody_length
    
    bge $s0, $s1, reset_melody
    
    j continue_melody

    



music_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    

reset_melody:
    li $s0, 0
    sw $s0, melody_index
    j continue_melody
    
continue_melody:
    la $s1, melody #loads_melody_address
    sll $s2, $s0, 2 #multiply 4 
    
    add $s2, $s1, $s2 #address of note 
    
    lw $a0, 0($s2) #value of note
    
    li $t0, -1
    beq $a0, $t0, skip_note_crotchet   # If it's a rest, skip playing
    li $t0, -2
    beq $a0, $t0, skip_note_quaver   # If it's a rest, skip playing
    
    li $v0, 31 
    li $a1, 180
    li $a2, 12 #piano
    li $a3, 70
    
    syscall
    
    addi $s0, $s0, 1      # Increment the index
    sw $s0, melody_index  # Store updated index
    
    #reset everything
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
    
    
skip_note_crotchet:
    li $v0, 32                # Sleep syscall
    li $a0, 180               # Sleep for the same duration as a note
    syscall
    j return_rest

skip_note_quaver:
    li $v0, 32                # Sleep syscall
    li $a0, 45               # Sleep for the same duration as a note
    syscall
    j return_rest
   
    
return_rest:
    addi $s0, $s0, 1
    sw $s0, melody_index  #increments index as well
    
    # Return from function
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
  
play_next_bass_note:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    # Load current index
    lw $s0, bass_index
    lw $s1, bass_length
    
    # Check if we need to loop back
    bge $s0, $s1, reset_bass
    j continue_bass
    
reset_bass:
    li $s0, 0
    sw $s0, bass_index
    
continue_bass:
    la $s1, bassline #loads_melody_address
    sll $s2, $s0, 2 #multiply 4 
    
    add $s2, $s1, $s2 #address of note 
    
    lw $a0, 0($s2) #value of note
    
    li $t0, -1
    beq $a0, $t0, skip_note_crotchet   # If it's a rest, skip playing
    li $t0, -2
    beq $a0, $t0, skip_note_quaver   # If it's a rest, skip playing
    
    li $v0, 31 
    li $a1, 180
    li $a2, 33 #bass
    li $a3, 50
    
    syscall
    
    addi $s0, $s0, 1      # Increment the index
    sw $s0, bass_index  # Store updated index
    
    #reset everything
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    
    
    
   
# Octave 3
# C3:  .word 36
# Cs3: .word 37  # C sharp
# D3:  .word 38
# Ds3: .word 39  # D sharp
# E3:  .word 40
# F3:  .word 41
# Fs3: .word 42  # F sharp
# G3:  .word 43
# Gs3: .word 44  # G sharp
# A3:  .word 45
# As3: .word 46  # A sharp / B flat
# B3:  .word 47

# # Octave 4
# C4:  .word 48
# Cs4: .word 49
# D4:  .word 50
# Ds4: .word 51
# E4:  .word 52
# F4:  .word 53
# Fs4: .word 54
# G4:  .word 55
# Gs4: .word 56
# A4:  .word 57
# As4: .word 58
# B4:  .word 59

# # Octave 5
# C5:  .word 60
# Cs5: .word 61
# D5:  .word 62
# Ds5: .word 63
# E5:  .word 64
# F5:  .word 65
# Fs5: .word 66
# G5:  .word 67
# Gs5: .word 68
# A5:  .word 69
# As5: .word 70
# B5:  .word 71

# # Octave 6
# C6:  .word 72