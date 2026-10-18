.eqv BG       0x00121b2b
.eqv TILE     0x00283750
.eqv WHITE    0x00eef4ff
.eqv BLUE     0x005cc8ff
.eqv GOLD     0x00ffd166

.data 0x10010000
framebuffer: .space 16384
input_buffer: .space 256
board: .word 0:9
win_lines: .word 0,1,2, 3,4,5, 6,7,8
           .word 0,3,6, 1,4,7, 2,5,8, 0,4,8, 2,4,6
font: .word 31599,11415,29671,29647,23497,31183,31215,29257
      .word 31727,31695,23213,11114,11245,4719,11131,23861,29314,29842
bad_input: .asciiz "Invalid input. Enter one listed command, then Enter.\n"
bye: .asciiz "Goodbye!\n"
tt_intro: .ascii "\nTIC-TAC-TOE: two players.\n"
          .ascii "X goes first. Choose an empty numbered square.\n"
          .asciiz "Three in a row wins. Enter q to quit.\n"
grid_space: .asciiz " "
grid_divider: .asciiz " | "
grid_row_end: .asciiz " \n"
grid_separator: .asciiz "---+---+---\n"
grid_newline: .asciiz "\n"
x_turn: .asciiz "X: choose an empty square (1-9): "
o_turn: .asciiz "O: choose an empty square (1-9): "
occupied: .asciiz "That square is occupied. Same player's turn.\n"
x_wins: .asciiz "X wins!\n"
o_wins: .asciiz "O wins!\n"
tt_draw: .asciiz "Draw! The board is full.\n"

.text
.globl main
main:
    li $t0, -8
    and $sp, $sp, $t0
    jal tic_tac_toe
    la $a0, bye
    jal print_string
    li $v0, 10
    syscall

print_string:
    li $v0, 4
    syscall
    jr $ra

print_number:
    li $v0, 1
    syscall
    jr $ra

read_command:
    la $a0, input_buffer
    li $a1, 256
    li $v0, 8
    syscall
    la $t0, input_buffer
    lbu $t1, 0($t0)
    beq $t1, $zero, command_bad
    li $t9, 32
    slt $t8, $t9, $t1
    beq $t8, $zero, command_bad
    addi $t0, $t0, 1

command_tail:
    lbu $t2, 0($t0)
    beq $t2, $zero, command_ok
    li $t9, 10
    beq $t2, $t9, command_ok
    li $t9, 13
    beq $t2, $t9, command_next
    li $t9, 32
    bne $t2, $t9, command_bad

command_next:
    addi $t0, $t0, 1
    j command_tail

command_ok:
    li $t9, 'A'
    slt $t8, $t1, $t9
    bne $t8, $zero, command_return
    li $t9, 'Z'
    slt $t8, $t9, $t1
    bne $t8, $zero, command_return
    addi $t1, $t1, 32

command_return:
    move $v0, $t1
    jr $ra

command_bad:
    li $v0, -1
    jr $ra

fill_screen:
    la $t0, framebuffer
    li $t1, 4096

fill_loop:
    sw $a0, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, fill_loop
    jr $ra

draw_rect:
    srl $t0, $a2, 16
    andi $t1, $a2, 65535
    sll $t2, $a1, 6
    add $t2, $t2, $a0
    sll $t2, $t2, 2
    la $t3, framebuffer
    add $t2, $t2, $t3

rect_row:
    move $t3, $t2
    move $t4, $t0

rect_pixel:
    sw $a3, 0($t3)
    addi $t3, $t3, 4
    addi $t4, $t4, -1
    bne $t4, $zero, rect_pixel
    addi $t2, $t2, 256
    addi $t1, $t1, -1
    bne $t1, $zero, rect_row
    jr $ra

draw_glyph:
    sll $t0, $a2, 2
    la $t1, font
    add $t0, $t0, $t1
    lw $t0, 0($t0)
    li $t1, 16384
    li $t2, 0

glyph_row:
    li $t3, 0

glyph_col:
    and $t4, $t0, $t1
    beq $t4, $zero, glyph_skip
    sll $t5, $t2, 1
    add $t5, $t5, $a1
    sll $t5, $t5, 6
    sll $t6, $t3, 1
    add $t6, $t6, $a0
    add $t5, $t5, $t6
    sll $t5, $t5, 2
    la $t6, framebuffer
    add $t5, $t5, $t6
    sw $a3, 0($t5)
    sw $a3, 4($t5)
    sw $a3, 256($t5)
    sw $a3, 260($t5)

glyph_skip:
    srl $t1, $t1, 1
    addi $t3, $t3, 1
    li $t9, 3
    slt $t8, $t3, $t9
    bne $t8, $zero, glyph_col
    addi $t2, $t2, 1
    li $t9, 5
    slt $t8, $t2, $t9
    bne $t8, $zero, glyph_row
    jr $ra

tic_tac_toe:
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    li $s0, 1
    li $s1, 0
    la $t0, board
    li $t1, 9

tt_reset:
    sw $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, tt_reset
    la $a0, tt_intro
    jal print_string
    jal draw_ttt

tt_turn:
    la $a0, x_turn
    li $t9, 1
    beq $s0, $t9, tt_prompt
    la $a0, o_turn

tt_prompt:
    jal print_string
    jal read_command
    li $t9, 'q'
    beq $v0, $t9, tt_return
    li $t9, '1'
    slt $t8, $v0, $t9
    bne $t8, $zero, tt_invalid
    li $t9, '9'
    slt $t8, $t9, $v0
    bne $t8, $zero, tt_invalid
    addi $t0, $v0, -49
    sll $t0, $t0, 2
    la $t1, board
    add $t0, $t0, $t1
    lw $t1, 0($t0)
    bne $t1, $zero, tt_occupied
    sw $s0, 0($t0)
    addi $s1, $s1, 1
    jal draw_ttt
    jal check_winner
    bne $v0, $zero, tt_won
    li $t9, 9
    beq $s1, $t9, tt_tied
    li $t0, 3
    sub $s0, $t0, $s0
    j tt_turn

tt_invalid:
    la $a0, bad_input
    jal print_string
    jal print_board
    j tt_turn

tt_occupied:
    la $a0, occupied
    jal print_string
    jal print_board
    j tt_turn

tt_won:
    la $a0, x_wins
    li $t9, 1
    beq $v0, $t9, tt_result
    la $a0, o_wins
    j tt_result

tt_tied:
    la $a0, tt_draw

tt_result:
    jal print_string

tt_return:
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra

check_winner:
    la $t0, win_lines
    la $t1, board
    li $t2, 8

winner_loop:
    lw $t3, 0($t0)
    sll $t3, $t3, 2
    add $t3, $t3, $t1
    lw $t3, 0($t3)
    beq $t3, $zero, winner_next
    lw $t4, 4($t0)
    sll $t4, $t4, 2
    add $t4, $t4, $t1
    lw $t4, 0($t4)
    bne $t3, $t4, winner_next
    lw $t4, 8($t0)
    sll $t4, $t4, 2
    add $t4, $t4, $t1
    lw $t4, 0($t4)
    bne $t3, $t4, winner_next
    move $v0, $t3
    jr $ra

winner_next:
    addi $t0, $t0, 12
    addi $t2, $t2, -1
    bne $t2, $zero, winner_loop
    move $v0, $zero
    jr $ra

draw_ttt:
    addi $sp, $sp, -40
    sw $ra, 36($sp)
    sw $s0, 32($sp)
    sw $s1, 28($sp)
    sw $s2, 24($sp)
    li $a0, BG
    jal fill_screen
    li $s0, 0

tt_tile:
    li $t0, 3
    div $s0, $t0
    mflo $s2
    mfhi $s1
    mul $s1, $s1, 20
    mul $s2, $s2, 20
    addi $s1, $s1, 3
    addi $s2, $s2, 3
    move $a0, $s1
    move $a1, $s2
    li $a2, 0x00120012
    li $a3, TILE
    jal draw_rect
    sll $t0, $s0, 2
    la $t1, board
    add $t0, $t0, $t1
    lw $t0, 0($t0)
    addi $a2, $s0, 1
    li $a3, WHITE
    beq $t0, $zero, tt_glyph
    li $a2, 10
    li $a3, BLUE
    li $t9, 1
    beq $t0, $t9, tt_glyph
    li $a2, 11
    li $a3, GOLD

tt_glyph:
    addi $a0, $s1, 6
    addi $a1, $s2, 4
    jal draw_glyph
    addi $s0, $s0, 1
    li $t9, 9
    slt $t8, $s0, $t9
    bne $t8, $zero, tt_tile
    jal print_board
    lw $s2, 24($sp)
    lw $s1, 28($sp)
    lw $s0, 32($sp)
    lw $ra, 36($sp)
    addi $sp, $sp, 40
    jr $ra

print_board:
    la $a0, grid_newline
    li $v0, 4
    syscall
    la $a0, grid_space
    li $v0, 4
    syscall
    li $t0, 0
    li $t1, 0
    la $t2, board

print_board_cell:
    lw $t3, 0($t2)
    beq $t3, $zero, print_empty_cell
    li $t4, 1
    beq $t3, $t4, print_x_cell
    li $a0, 'O'
    j print_cell_character

print_x_cell:
    li $a0, 'X'
    j print_cell_character

print_empty_cell:
    addi $a0, $t0, 49

print_cell_character:
    li $v0, 11
    syscall
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, 4
    li $t4, 3
    beq $t1, $t4, print_row_end
    la $a0, grid_divider
    li $v0, 4
    syscall
    j print_board_cell

print_row_end:
    la $a0, grid_row_end
    li $v0, 4
    syscall
    li $t4, 9
    beq $t0, $t4, print_board_done
    la $a0, grid_separator
    li $v0, 4
    syscall
    la $a0, grid_space
    li $v0, 4
    syscall
    li $t1, 0
    j print_board_cell

print_board_done:
    la $a0, grid_newline
    li $v0, 4
    syscall
    jr $ra