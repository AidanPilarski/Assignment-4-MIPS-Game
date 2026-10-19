.eqv SKY 0x008dd9f2
.eqv GREEN 0x0033af63
.eqv YELLOW 0x00ffd24a
.eqv RED 0x00ee5f65
.eqv DARK 0x001a3048
.eqv WHITE 0x00ffffff
.eqv GROUND 0x00e6cc91
.eqv KEYBOARD 0xffff0000
.eqv WAITING 0
.eqv PLAYING 1
.eqv GAME_OVER 2

.data 0x10010000
framebuffer: .space 16384

bird:
bird_x: .word 14
bird_y: .word 28
bird_width: .word 3
bird_height: .word 3
bird_color: .word YELLOW

top_pipe: .word 56, 8, 8, 14, GREEN
bottom_pipe: .word 56, 40, 8, 20, GREEN
erase_pipe: .word 56, 8, 8, 52, SKY
erase_bird: .word 14, 28, 3, 3, SKY
score_bar: .word 0, 0, 64, 8, DARK
ground: .word 0, 60, 64, 4, GROUND

bird_speed: .word 0
gravity_timer: .word 0
pipe_timer: .word 0
pipe_x: .word 56
gap_y: .word 22
pipe_scored: .word 0
score: .word 0
game_state: .word 0

menu: .asciiz "\nFLAPPY BIRD\n\n1 - Start\nSpace - Flap\nQ - Quit\n\n"
game_over_text: .asciiz "\nGame over\nScore: "
again_text: .asciiz "\n\n1 - Play again\nQ - Quit\n\n"

digits:
    .ascii "111", "101", "101", "101", "111"
    .ascii "010", "110", "010", "010", "111"
    .ascii "111", "001", "111", "100", "111"
    .ascii "111", "001", "111", "001", "111"
    .ascii "101", "101", "111", "001", "001"
    .ascii "111", "100", "111", "001", "111"
    .ascii "111", "100", "111", "101", "111"
    .ascii "111", "001", "001", "001", "001"
    .ascii "111", "101", "111", "101", "111"
    .ascii "111", "101", "111", "001", "111"

.text
.globl main

main:
    addi $sp, $sp, -4
    li $v0, 30
    syscall
    move $a1, $a0
    li $a0, 0
    li $v0, 40
    syscall
    li $t0, KEYBOARD
    sw $zero, 0($t0)
    la $a0, menu
    jal print_string
    jal reset_game

frame_loop:
    jal read_key
    li $t0, 'q'
    beq $v0, $t0, quit_game
    lw $t0, game_state
    li $t1, PLAYING
    beq $t0, $t1, playing
    li $t1, '1'
    bne $v0, $t1, frame_sleep
    jal reset_game
    li $t0, PLAYING
    sw $t0, game_state
    li $t0, -2
    sw $t0, bird_speed
    j frame_sleep

playing:
    li $t0, ' '
    bne $v0, $t0, update_frame
    li $t0, -2
    sw $t0, bird_speed
    sw $zero, gravity_timer

update_frame:
    jal erase_objects
    jal move_bird
    jal move_pipe
    jal check_collision
    bne $v0, $zero, game_over
    jal add_point
    jal draw_objects
    j frame_sleep

game_over:
    li $t0, GAME_OVER
    sw $t0, game_state
    li $t0, RED
    sw $t0, bird_color
    lw $t0, bird_y
    li $t1, 8
    slt $t2, $t0, $t1
    beq $t2, $zero, check_bottom
    li $t0, 8

check_bottom:
    li $t1, 57
    slt $t2, $t1, $t0
    beq $t2, $zero, show_game_over
    li $t0, 57

show_game_over:
    sw $t0, bird_y
    jal draw_objects
    la $a0, game_over_text
    jal print_string
    lw $a0, score
    li $v0, 1
    syscall
    la $a0, again_text
    jal print_string

frame_sleep:
    li $a0, 50
    li $v0, 32
    syscall
    j frame_loop

quit_game:
    li $v0, 10
    syscall

print_string:
    li $v0, 4
    syscall
    jr $ra

read_key:
    li $v0, 0
    li $t0, KEYBOARD
    lw $t1, 0($t0)
    beq $t1, $zero, key_done
    lw $v0, 4($t0)
    li $t1, 'Q'
    bne $v0, $t1, key_done
    li $v0, 'q'

key_done:
    jr $ra

reset_game:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    li $t0, 28
    sw $t0, bird_y
    li $t0, YELLOW
    sw $t0, bird_color
    li $t0, 56
    sw $t0, pipe_x
    li $t0, 22
    sw $t0, gap_y
    sw $zero, bird_speed
    sw $zero, gravity_timer
    sw $zero, pipe_timer
    sw $zero, pipe_scored
    sw $zero, score
    li $t0, WAITING
    sw $t0, game_state
    jal clear_screen
    la $a0, ground
    jal draw_rectangle
    jal draw_score
    jal draw_objects
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

move_bird:
    lw $t0, gravity_timer
    addi $t0, $t0, 1
    sw $t0, gravity_timer
    li $t1, 3
    bne $t0, $t1, update_bird_position
    sw $zero, gravity_timer
    lw $t0, bird_speed
    li $t1, 2
    beq $t0, $t1, update_bird_position
    addi $t0, $t0, 1
    sw $t0, bird_speed

update_bird_position:
    lw $t0, bird_y
    lw $t1, bird_speed
    add $t0, $t0, $t1
    sw $t0, bird_y
    jr $ra

move_pipe:
    lw $t0, pipe_timer
    addi $t0, $t0, 1
    sw $t0, pipe_timer
    li $t1, 2
    bne $t0, $t1, pipe_done
    sw $zero, pipe_timer
    lw $t0, pipe_x
    addi $t0, $t0, -1
    sw $t0, pipe_x
    li $t1, -8
    bne $t0, $t1, pipe_done
    li $t0, 64
    sw $t0, pipe_x
    sw $zero, pipe_scored
    li $a0, 0
    li $a1, 23
    li $v0, 42
    syscall
    addi $a0, $a0, 12
    sw $a0, gap_y

pipe_done:
    jr $ra

check_collision:
    li $v0, 1
    lw $t0, bird_y
    li $t1, 8
    slt $t2, $t0, $t1
    bne $t2, $zero, collision_done
    li $t1, 57
    slt $t2, $t1, $t0
    bne $t2, $zero, collision_done
    lw $t1, pipe_x
    li $t2, 17
    slt $t3, $t1, $t2
    beq $t3, $zero, no_collision
    addi $t1, $t1, 8
    li $t2, 14
    slt $t3, $t2, $t1
    beq $t3, $zero, no_collision
    lw $t1, gap_y
    slt $t2, $t0, $t1
    bne $t2, $zero, collision_done
    addi $t0, $t0, 3
    addi $t1, $t1, 18
    slt $t2, $t1, $t0
    bne $t2, $zero, collision_done

no_collision:
    li $v0, 0

collision_done:
    jr $ra

add_point:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    lw $t0, pipe_scored
    bne $t0, $zero, point_done
    lw $t0, pipe_x
    addi $t0, $t0, 8
    li $t1, 14
    slt $t2, $t1, $t0
    bne $t2, $zero, point_done
    li $t0, 1
    sw $t0, pipe_scored
    lw $t0, score
    li $t1, 999
    beq $t0, $t1, point_done
    addi $t0, $t0, 1
    sw $t0, score
    jal draw_score

point_done:
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

erase_objects:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    lw $t0, pipe_x
    sw $t0, erase_pipe
    la $a0, erase_pipe
    jal draw_rectangle
    lw $t0, bird_y
    la $a0, erase_bird
    sw $t0, 4($a0)
    jal draw_rectangle
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

draw_objects:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    lw $t0, pipe_x
    la $t2, top_pipe
    la $t3, bottom_pipe
    sw $t0, 0($t2)
    sw $t0, 0($t3)
    lw $t0, gap_y
    addi $t1, $t0, -8
    sw $t1, 12($t2)
    addi $t0, $t0, 18
    sw $t0, 4($t3)
    li $t1, 60
    sub $t1, $t1, $t0
    sw $t1, 12($t3)
    la $a0, top_pipe
    jal draw_rectangle
    la $a0, bottom_pipe
    jal draw_rectangle
    la $a0, bird
    jal draw_rectangle
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

clear_screen:
    la $t0, framebuffer
    li $t1, 4096
    li $t2, SKY

clear_pixel:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, clear_pixel
    jr $ra

draw_rectangle:
    lw $t0, 0($a0)
    lw $t1, 4($a0)
    lw $t2, 8($a0)
    lw $t3, 12($a0)
    lw $t4, 16($a0)
    slt $t5, $t0, $zero
    beq $t5, $zero, clip_right
    add $t2, $t2, $t0
    li $t0, 0

clip_right:
    li $t5, 64
    sub $t5, $t5, $t0
    slt $t6, $t5, $t2
    beq $t6, $zero, clip_top
    move $t2, $t5

clip_top:
    slt $t5, $t1, $zero
    beq $t5, $zero, clip_bottom
    add $t3, $t3, $t1
    li $t1, 0

clip_bottom:
    li $t5, 64
    sub $t5, $t5, $t1
    slt $t6, $t5, $t3
    beq $t6, $zero, check_rectangle
    move $t3, $t5

check_rectangle:
    slt $t5, $zero, $t2
    beq $t5, $zero, rectangle_done
    slt $t5, $zero, $t3
    beq $t5, $zero, rectangle_done
    mul $t1, $t1, 64
    add $t0, $t0, $t1
    mul $t0, $t0, 4
    la $t1, framebuffer
    add $t0, $t0, $t1

rectangle_row:
    move $t1, $t0
    move $t5, $t2

rectangle_pixel:
    sw $t4, 0($t1)
    addi $t1, $t1, 4
    addi $t5, $t5, -1
    bne $t5, $zero, rectangle_pixel
    addi $t0, $t0, 256
    addi $t3, $t3, -1
    bne $t3, $zero, rectangle_row

rectangle_done:
    jr $ra

draw_score:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)
    la $a0, score_bar
    jal draw_rectangle
    lw $s0, score
    li $t0, 100
    div $s0, $t0
    mflo $a1
    mfhi $s0
    li $a0, 26
    jal draw_digit
    li $t0, 10
    div $s0, $t0
    mflo $a1
    mfhi $s0
    li $a0, 30
    jal draw_digit
    move $a1, $s0
    li $a0, 34
    jal draw_digit
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

draw_digit:
    mul $t0, $a1, 15
    la $t1, digits
    add $t0, $t0, $t1
    mul $t1, $a0, 4
    la $t2, framebuffer
    add $t1, $t1, $t2
    addi $t1, $t1, 256
    li $t2, 5
    li $t6, WHITE

digit_row:
    move $t3, $t1
    li $t4, 3

digit_pixel:
    lbu $t5, 0($t0)
    li $t7, '1'
    bne $t5, $t7, skip_digit_pixel
    sw $t6, 0($t3)

skip_digit_pixel:
    addi $t0, $t0, 1
    addi $t3, $t3, 4
    addi $t4, $t4, -1
    bne $t4, $zero, digit_pixel
    addi $t1, $t1, 256
    addi $t2, $t2, -1
    bne $t2, $zero, digit_row
    jr $ra
