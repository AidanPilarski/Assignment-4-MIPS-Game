.eqv TABLE_COLOR 0x00113b32
.eqv CARD_COLOR  0x00eef4ff
.eqv INK_COLOR   0x00121b2b
.eqv LINE_COLOR  0x00ffd166

.data 0x10010000
framebuffer: .space 16384
input_buffer: .space 256
deck: .space 208
player_hand: .space 48
dealer_hand: .space 48
player_count: .word 0
dealer_count: .word 0
player_total: .word 0
dealer_total: .word 0
dealer_hidden: .word 1

invalid_action_message: .asciiz "\nChoose H, S, or Q.\n\n"
invalid_start_message: .asciiz "\nEnter 1 or Q.\n\n"
blank_line: .asciiz "\n\n"
title: .asciiz "\nBLACKJACK\n\n"
start_prompt: .asciiz "1 - Start\nQ - Quit\n\nChoice: "
action_prompt: .asciiz "H - Hit   S - Stand   Q - Quit\nChoice: "
player_label: .asciiz "You:    "
dealer_label: .asciiz "Dealer: "
hidden_text: .asciiz "[?]  "
card_open: .asciiz "["
card_close: .asciiz "]  "
ten_text: .asciiz "10"
total_label: .asciiz "\nTotal:  "
player_win_message: .asciiz "You win\n\n"
dealer_win_message: .asciiz "Dealer wins\n\n"
tie_message: .asciiz "Tie\n\n"
player_bust_message: .asciiz "You bust. Dealer wins\n\n"
dealer_bust_message: .asciiz "Dealer busts. You win\n\n"
blackjack_message: .asciiz "You win with blackjack\n\n"
dealer_blackjack_message: .asciiz "Dealer wins with blackjack\n\n"
rank_chars: .asciiz "?A23456789TJQK"

card_patterns:
question_pattern: .ascii "111", "001", "010", "000", "010"
ace_pattern: .ascii "010", "101", "111", "101", "101"
two_pattern: .ascii "111", "001", "111", "100", "111"
three_pattern: .ascii "111", "001", "111", "001", "111"
four_pattern: .ascii "101", "101", "111", "001", "001"
five_pattern: .ascii "111", "100", "111", "001", "111"
six_pattern: .ascii "111", "100", "111", "101", "111"
seven_pattern: .ascii "111", "001", "001", "001", "001"
eight_pattern: .ascii "111", "101", "111", "101", "111"
nine_pattern: .ascii "111", "101", "111", "001", "111"
ten_pattern: .ascii "111", "010", "010", "010", "010"
jack_pattern: .ascii "001", "001", "001", "101", "111"
queen_pattern: .ascii "010", "101", "101", "111", "011"
king_pattern: .ascii "101", "110", "100", "110", "101"

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
    la $a0, title
    jal print_string

start_menu:
    la $a0, start_prompt
    jal print_string
    jal read_choice
    li $t0, 'q'
    beq $v0, $t0, quit_game
    li $t0, '1'
    bne $v0, $t0, invalid_start

start_round:
    jal reset_round
    la $a0, player_hand
    la $a1, player_count
    jal deal_card
    la $a0, dealer_hand
    la $a1, dealer_count
    jal deal_card
    la $a0, player_hand
    la $a1, player_count
    jal deal_card
    la $a0, dealer_hand
    la $a1, dealer_count
    jal deal_card
    jal update_totals
    jal show_hands
    lw $t0, player_total
    lw $t1, dealer_total
    li $t2, 21
    beq $t0, $t2, player_blackjack
    beq $t1, $t2, dealer_blackjack

player_turn:
    la $a0, action_prompt
    jal print_string
    jal read_choice
    li $t0, 'q'
    beq $v0, $t0, quit_game
    li $t0, 's'
    beq $v0, $t0, dealer_turn
    li $t0, 'h'
    bne $v0, $t0, invalid_action
    la $a0, player_hand
    la $a1, player_count
    jal deal_card
    jal update_totals
    jal show_hands
    lw $t0, player_total
    li $t1, 21
    slt $t2, $t1, $t0
    bne $t2, $zero, player_bust
    beq $t0, $t1, dealer_turn
    j player_turn

invalid_start:
    la $a0, invalid_start_message
    jal print_string
    j start_menu

invalid_action:
    la $a0, invalid_action_message
    jal print_string
    j player_turn

dealer_turn:
    sw $zero, dealer_hidden

dealer_draw:
    jal update_totals
    lw $t0, dealer_total
    li $t1, 17
    slt $t2, $t0, $t1
    beq $t2, $zero, compare_totals
    la $a0, dealer_hand
    la $a1, dealer_count
    jal deal_card
    j dealer_draw

compare_totals:
    lw $t0, dealer_total
    li $t1, 21
    slt $t2, $t1, $t0
    bne $t2, $zero, dealer_bust
    lw $t1, player_total
    beq $t0, $t1, tie_game
    slt $t2, $t0, $t1
    bne $t2, $zero, player_wins
    la $a0, dealer_win_message
    j finish_round

player_blackjack:
    li $t2, 21
    beq $t1, $t2, tie_game
    la $a0, blackjack_message
    j finish_round

dealer_blackjack:
    la $a0, dealer_blackjack_message
    j finish_round

player_bust:
    la $a0, player_bust_message
    j finish_round

dealer_bust:
    la $a0, dealer_bust_message
    j finish_round

player_wins:
    la $a0, player_win_message
    j finish_round

tie_game:
    la $a0, tie_message

finish_round:
    move $s0, $a0
    sw $zero, dealer_hidden
    jal show_hands
    move $a0, $s0
    jal print_string
    j start_menu

quit_game:
    li $v0, 10
    syscall

print_string:
    li $v0, 4
    syscall
    jr $ra

read_choice:
    la $a0, input_buffer
    li $a1, 256
    li $v0, 8
    syscall
    la $t0, input_buffer
    lbu $v0, 0($t0)
    addi $t0, $t0, 1

check_input_end:
    lbu $t1, 0($t0)
    beq $t1, $zero, lowercase_choice
    li $t2, 10
    beq $t1, $t2, lowercase_choice
    li $t2, 32
    beq $t1, $t2, next_input_character
    li $t2, 13
    bne $t1, $t2, invalid_choice

next_input_character:
    addi $t0, $t0, 1
    j check_input_end

lowercase_choice:
    li $t1, 'H'
    beq $v0, $t1, make_lowercase
    li $t1, 'S'
    beq $v0, $t1, make_lowercase
    li $t1, 'Q'
    bne $v0, $t1, choice_done

make_lowercase:
    addi $v0, $v0, 32

choice_done:
    jr $ra

invalid_choice:
    li $v0, -1
    jr $ra

reset_round:
    sw $zero, player_count
    sw $zero, dealer_count
    sw $zero, player_total
    sw $zero, dealer_total
    li $t0, 1
    sw $t0, dealer_hidden
    la $t0, deck
    li $t1, 52
    li $t2, 1

reset_deck:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    li $t3, 14
    bne $t2, $t3, next_deck_card
    li $t2, 1

next_deck_card:
    addi $t1, $t1, -1
    bne $t1, $zero, reset_deck
    jr $ra

deal_card:
    move $t0, $a0
    move $t1, $a1

choose_card:
    li $a0, 0
    li $a1, 52
    li $v0, 42
    syscall
    mul $t2, $a0, 4
    la $t3, deck
    add $t2, $t2, $t3
    lw $t3, 0($t2)
    beq $t3, $zero, choose_card
    sw $zero, 0($t2)
    lw $t4, 0($t1)
    mul $t5, $t4, 4
    add $t5, $t5, $t0
    sw $t3, 0($t5)
    addi $t4, $t4, 1
    sw $t4, 0($t1)
    jr $ra

update_totals:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    sw $v0, player_total
    la $a0, dealer_hand
    lw $a1, dealer_count
    jal hand_total
    sw $v0, dealer_total
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

hand_total:
    li $v0, 0
    li $t0, 0

count_cards:
    beq $a1, $zero, adjust_aces
    lw $t1, 0($a0)
    li $t2, 1
    beq $t1, $t2, count_ace
    li $t2, 10
    slt $t3, $t2, $t1
    beq $t3, $zero, add_card_value
    li $t1, 10
    j add_card_value

count_ace:
    li $t1, 11
    addi $t0, $t0, 1

add_card_value:
    add $v0, $v0, $t1
    addi $a0, $a0, 4
    addi $a1, $a1, -1
    j count_cards

adjust_aces:
    li $t1, 21
    slt $t2, $t1, $v0
    beq $t2, $zero, total_done
    beq $t0, $zero, total_done
    addi $v0, $v0, -10
    addi $t0, $t0, -1
    j adjust_aces

total_done:
    jr $ra

show_hands:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    jal clear_table
    la $a0, dealer_hand
    lw $a1, dealer_count
    li $a2, 3
    lw $a3, dealer_hidden
    jal draw_hand
    la $a0, player_hand
    lw $a1, player_count
    li $a2, 35
    li $a3, 0
    jal draw_hand
    la $a0, blank_line
    jal print_string
    la $a0, dealer_label
    jal print_string
    la $a0, dealer_hand
    lw $a1, dealer_count
    lw $a2, dealer_hidden
    jal print_hand
    la $a0, player_label
    jal print_string
    la $a0, player_hand
    lw $a1, player_count
    li $a2, 0
    jal print_hand
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

print_hand:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    li $s3, 0

print_hand_loop:
    slt $t8, $s3, $s1
    beq $t8, $zero, print_hand_total
    li $t9, 1
    bne $s3, $t9, print_rank
    beq $s2, $zero, print_rank
    la $a0, hidden_text
    jal print_string
    j print_hand_next

print_rank:
    la $a0, card_open
    jal print_string
    mul $t0, $s3, 4
    add $t0, $t0, $s0
    lw $t0, 0($t0)
    li $t9, 10
    beq $t0, $t9, print_ten
    la $t1, rank_chars
    add $t0, $t0, $t1
    lbu $a0, 0($t0)
    li $v0, 11
    syscall
    j print_card_end

print_ten:
    la $a0, ten_text
    jal print_string

print_card_end:
    la $a0, card_close
    jal print_string

print_hand_next:
    addi $s3, $s3, 1
    j print_hand_loop

print_hand_total:
    bne $s2, $zero, print_hand_done
    la $a0, total_label
    jal print_string
    move $a0, $s0
    move $a1, $s1
    jal hand_total
    move $a0, $v0
    li $v0, 1
    syscall

print_hand_done:
    la $a0, blank_line
    jal print_string
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra

clear_table:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    la $t0, framebuffer
    li $t1, 4096
    li $t2, TABLE_COLOR

clear_pixel:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, clear_pixel
    la $a0, framebuffer
    li $t0, 31
    mul $t0, $t0, 256
    add $a0, $a0, $t0
    li $a1, 64
    li $a2, 2
    li $a3, LINE_COLOR
    jal draw_rectangle
    lw $ra, 4($sp)
    addi $sp, $sp, 8
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

draw_hand:
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    li $s4, 0

next_card_picture:
    beq $s4, $s1, drawing_done
    move $t1, $s4
    move $t2, $s2
    li $t0, 6
    slt $t3, $t1, $t0
    bne $t3, $zero, card_position
    addi $t1, $t1, -6
    addi $t2, $t2, 13

card_position:
    mul $t1, $t1, 10
    addi $t1, $t1, 2
    mul $t2, $t2, 64
    add $t2, $t2, $t1
    mul $t2, $t2, 4
    la $s5, framebuffer
    add $s5, $s5, $t2
    move $a0, $s5
    li $a1, 9
    li $a2, 12
    li $a3, CARD_COLOR
    jal draw_rectangle
    mul $t0, $s4, 4
    add $t0, $t0, $s0
    lw $a1, 0($t0)
    beq $s3, $zero, draw_card_symbol
    li $t0, 1
    bne $s4, $t0, draw_card_symbol
    li $a1, 0

draw_card_symbol:
    addi $a0, $s5, 260
    jal draw_symbol
    addi $s4, $s4, 1
    j next_card_picture

drawing_done:
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra

draw_symbol:
    mul $t0, $a1, 15
    la $t1, card_patterns
    add $t0, $t0, $t1
    li $t1, 5
    li $t5, INK_COLOR

symbol_row:
    move $t2, $a0
    li $t3, 3

symbol_pixel:
    lbu $t4, 0($t0)
    li $t6, '1'
    bne $t4, $t6, skip_symbol_pixel
    sw $t5, 0($t2)
    sw $t5, 4($t2)
    sw $t5, 256($t2)
    sw $t5, 260($t2)

skip_symbol_pixel:
    addi $t0, $t0, 1
    addi $t2, $t2, 8
    addi $t3, $t3, -1
    bne $t3, $zero, symbol_pixel
    addi $a0, $a0, 512
    addi $t1, $t1, -1
    bne $t1, $zero, symbol_row
    jr $ra
