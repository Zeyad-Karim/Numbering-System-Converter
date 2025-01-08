.data
    # Buffers
    input_buffer:    .space 100
    output_buffer:   .space 100
    
    # Messages
    prompt_base1:    .asciiz "Enter the current system: "
    prompt_number:   .asciiz "Enter the number: "
    prompt_base2:    .asciiz "Enter the new system: "
    error_msg:       .asciiz "Error: Invalid input for the given base system.\n"
    result_msg:      .asciiz "The number in the new system: "
    newline:         .asciiz "\n"

.text
.globl main

main:

    addi    $sp, $sp, -4
    sw      $ra, 0($sp)


    li      $v0, 4           
    la      $a0, prompt_base1
    syscall

    li      $v0, 5
    syscall
    move    $s0, $v0 


    li      $v0, 4   
    la      $a0, prompt_number
    syscall

    li      $v0, 8  
    la      $a0, input_buffer
    li      $a1, 100
    syscall


    la      $t0, input_buffer
remove_newline:
    lb      $t1, ($t0)
    beqz    $t1, input_done
    beq     $t1, 10, replace_newline
    addi    $t0, $t0, 1
    j       remove_newline

replace_newline:
    sb      $zero, ($t0)

input_done:

    la      $a0, input_buffer
    move    $a1, $s0
    jal     validate_input
    beqz    $v0, error  


    li      $v0, 4     
    la      $a0, prompt_base2
    syscall

    li      $v0, 5     
    syscall
    move    $s1, $v0      


    la      $a0, input_buffer
    move    $a1, $s0    
    move    $a2, $s1      
    la      $a3, output_buffer
    jal     convert_base


    li      $v0, 4
    la      $a0, result_msg
    syscall

    la      $a0, output_buffer
    syscall

    li      $v0, 4
    la      $a0, newline
    syscall

    j       exit

error:
    li      $v0, 4
    la      $a0, error_msg
    syscall

exit:
    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    li      $v0, 10     
    syscall


validate_input:



    li      $v0, 1   
    li      $t0, 0      

validate_loop:
    lb      $t1, ($a0)    
    beqz    $t1, validate_done   
    

    li      $t2, '0'
    li      $t3, '9'
    blt     $t1, $t2, check_letter
    ble     $t1, $t3, check_digit
    
check_letter:

    li      $t2, 'A'
    li      $t3, 'F'
    blt     $t1, $t2, invalid_char
    bgt     $t1, $t3, invalid_char
    

    subi    $t1, $t1, 'A'
    addi    $t1, $t1, 10
    j       check_value

check_digit:

    subi    $t1, $t1, '0'

check_value:

    bge     $t1, $a1, invalid_char
    
    addi    $a0, $a0, 1    
    j       validate_loop

invalid_char:
    li      $v0, 0     

validate_done:
    jr      $ra

convert_base:
    addi    $sp, $sp, -20
    sw      $ra, 16($sp)
    sw      $s0, 12($sp)
    sw      $s1, 8($sp)
    sw      $s2, 4($sp)
    sw      $s3, 0($sp)

    move    $s0, $a0     
    move    $s1, $a1  
    move    $s2, $a2  
    move    $s3, $a3   

    li      $t0, 0    
    li      $t1, 0     

to_decimal_loop:
    lb      $t2, ($s0)
    beqz    $t2, to_decimal_done

    li      $t3, '0'
    li      $t4, '9'
    blt     $t2, $t3, convert_letter
    ble     $t2, $t4, convert_digit

convert_letter:
    subi    $t2, $t2, 'A'
    addi    $t2, $t2, 10
    j       multiply_base

convert_digit:
    subi    $t2, $t2, '0'

multiply_base:

    mul     $t0, $t0, $s1
    add     $t0, $t0, $t2

    addi    $s0, $s0, 1
    j       to_decimal_loop

to_decimal_done:
    move    $t1, $t0    
    move    $t2, $s3      
    li      $t3, 0    

convert_to_base:
    div     $t1, $s2  
    mfhi    $t4      
    mflo    $t1   

    li      $t5, 10
    blt     $t4, $t5, to_digit
    
    addi    $t4, $t4, 'A'
    subi    $t4, $t4, 10
    j       store_char

to_digit:
    addi    $t4, $t4, '0'

store_char:
    sb      $t4, ($t2) 
    addi    $t2, $t2, 1    
    addi    $t3, $t3, 1  
    
    bnez    $t1, convert_to_base

    sb      $zero, ($t2)

    move    $t4, $s3    
    subi    $t2, $t2, 1   

reverse_loop:
    bge     $t4, $t2, done_conversion
    
    lb      $t5, ($t4)
    lb      $t6, ($t2)
    sb      $t6, ($t4)
    sb      $t5, ($t2)
    
    addi    $t4, $t4, 1
    subi    $t2, $t2, 1
    j       reverse_loop

done_conversion:

    lw      $ra, 16($sp)
    lw      $s0, 12($sp)
    lw      $s1, 8($sp)
    lw      $s2, 4($sp)
    lw      $s3, 0($sp)
    addi    $sp, $sp, 20
    
    jr      $ra
