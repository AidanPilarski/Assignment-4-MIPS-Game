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

symbol_patterns:
zero_pattern: .ascii "111", "101", "101", "101", "111"
one_pattern: .ascii "010", "110", "010", "010", "111"
two_pattern: .ascii "111", "001", "111", "100", "111"
three_pattern: .ascii "111", "001", "111", "001", "111"
four_pattern: .ascii "101", "101", "111", "001", "001"
five_pattern: .ascii "111", "100", "111", "001", "111"
six_pattern: .ascii "111", "100", "111", "101", "111"
seven_pattern: .ascii "111", "001", "001", "001", "001"
eight_pattern: .ascii "111", "101", "111", "101", "111"
nine_pattern: .ascii "111", "101", "111", "001", "111"
x_pattern: .ascii "101", "101", "010", "101", "101"
o_pattern: .ascii "010", "101", "101", "101", "010"

bad_input: .asciiz "Invalid input. Enter one listed command, then Enter.\n"
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
x_wins: .asciiz "X wins\n"
o_wins: .asciiz "O wins\n"
tt_draw: .asciiz "Tie\n"

.text
.globl main

main:
    addi $sp, $sp, -4
    jal tic_tac_toe
    li $v0, 10
    syscall

print_string:
    li $v0, 4
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
    li $t2, 'Q'
    bne $t1, $t2, command_return
    li $t1, 'q'

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

draw_rectangle:
    move $t0, $a0

rectangle_row:
    move $t1, $t0
    move $t2, $a1

rectangle_pixel:
    sw $a3, 0($t1)
    addi $t1, $t1, 4
    addi $t2, $t2, -1
    bne $t2, $zero, rectangle_pixel
    addi $t0, $t0, 256
    addi $a2, $a2, -1
    bne $a2, $zero, rectangle_row
    jr $ra

draw_symbol:
    mul $t0, $a1, 15
    la $t1, symbol_patterns
    add $t0, $t0, $t1
    li $t1, 5

symbol_row:
    move $t2, $a0
    li $t3, 3

symbol_pixel:
    lbu $t4, 0($t0)
    li $t5, '1'
    bne $t4, $t5, skip_symbol_pixel
    sw $a3, 0($t2)
    sw $a3, 4($t2)
    sw $a3, 256($t2)
    sw $a3, 260($t2)

skip_symbol_pixel:
    addi $t0, $t0, 1
    addi $t2, $t2, 8
    addi $t3, $t3, -1
    bne $t3, $zero, symbol_pixel
    addi $a0, $a0, 512
    addi $t1, $t1, -1
    bne $t1, $zero, symbol_row
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

clear_board:
    sw $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, clear_board
    la $a0, tt_intro
    jal print_string
    jal draw_board

next_turn:
    la $a0, x_turn
    li $t9, 1
    beq $s0, $t9, ask_for_square
    la $a0, o_turn

ask_for_square:
    jal print_string
    jal read_command
    li $t9, 'q'
    beq $v0, $t9, game_done
    li $t9, '1'
    slt $t8, $v0, $t9
    bne $t8, $zero, invalid_move
    li $t9, '9'
    slt $t8, $t9, $v0
    bne $t8, $zero, invalid_move
    addi $t0, $v0, -49
    mul $t0, $t0, 4
    la $t1, board
    add $t0, $t0, $t1
    lw $t1, 0($t0)
    bne $t1, $zero, occupied_square
    sw $s0, 0($t0)
    addi $s1, $s1, 1
    jal draw_board
    jal check_winner
    bne $v0, $zero, game_won
    li $t9, 9
    beq $s1, $t9, game_tied
    li $t0, 3
    sub $s0, $t0, $s0
    j next_turn

invalid_move:
    la $a0, bad_input
    jal print_string
    jal print_board
    j next_turn

occupied_square:
    la $a0, occupied
    jal print_string
    jal print_board
    j next_turn

game_won:
    la $a0, x_wins
    li $t9, 1
    beq $v0, $t9, show_result
    la $a0, o_wins
    j show_result

game_tied:
    la $a0, tt_draw

show_result:
    jal print_string

game_done:
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
    mul $t3, $t3, 4
    add $t3, $t3, $t1
    lw $t3, 0($t3)
    beq $t3, $zero, winner_next
    lw $t4, 4($t0)
    mul $t4, $t4, 4
    add $t4, $t4, $t1
    lw $t4, 0($t4)
    bne $t3, $t4, winner_next
    lw $t4, 8($t0)
    mul $t4, $t4, 4
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

draw_board:
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    li $a0, BG
    jal fill_screen
    li $s0, 0
    li $s1, 3
    li $s2, 3
    li $s3, 0

draw_square:
    mul $t0, $s2, 64
    add $t0, $t0, $s1
    mul $t0, $t0, 4
    la $s4, framebuffer
    add $s4, $s4, $t0
    move $a0, $s4
    li $a1, 18
    li $a2, 18
    li $a3, TILE
    jal draw_rectangle
    mul $t0, $s0, 4
    la $t1, board
    add $t0, $t0, $t1
    lw $t0, 0($t0)
    addi $a1, $s0, 1
    li $a3, WHITE
    beq $t0, $zero, draw_square_symbol
    li $a1, 10
    li $a3, BLUE
    li $t1, 1
    beq $t0, $t1, draw_square_symbol
    li $a1, 11
    li $a3, GOLD

draw_square_symbol:
    li $t0, 4
    mul $t0, $t0, 256
    addi $t0, $t0, 24
    add $a0, $s4, $t0
    jal draw_symbol
    addi $s0, $s0, 1
    li $t0, 9
    beq $s0, $t0, board_drawn
    addi $s1, $s1, 20
    addi $s3, $s3, 1
    li $t0, 3
    bne $s3, $t0, draw_square
    li $s1, 3
    li $s3, 0
    addi $s2, $s2, 20
    j draw_square

board_drawn:
    jal print_board
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
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