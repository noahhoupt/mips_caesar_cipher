##########################
### Noah Houpt (Nah70)
### Luca Lemnij (lpl16)
### EECS 314 Final Project
##########################

# Strings to be used in console
        .data
str_welcome: .asciiz "This program will encrypt or decrpt any input that does not contain symbols using the caesar cypher algorithm.\n\nIf invalid input is entered at any point, the program may exhibit unexpected behavior.\n\n"
str_opr:     .asciiz "0: Encrypt | 1: Decrypt: \n"
str_key:     .asciiz "\nenter key greater than 0 to be used for encryption/decryption: \n"
str_text:    .asciiz "\nenter text to be encypted/decrypted: \n"
str_result:  .asciiz "\nencypted/decrypted text: \n"
str_exit:    .asciiz "\n\nexited\n"

text:       .space 64 # reserve 64 bytes for text input

# specify to the compiler where the code will be
.text

main:

  li $v0, 4                                # print string code for syscall
  la $a0, str_welcome                      # load string to be printed
  syscall                                  # print welcome message 

########################
### User input algorithm
########################

prompt_and_read_operation:
  li $v0, 4                                # print string code for syscall
  la $a0, str_opr                          # load string to be printed
  syscall                                  # print prompt for user to input key

  li $v0, 5                                # read integer code for syscall
  syscall

  blt $v0, 0, prompt_and_read_operation    # if operation less than 0, reprompt user          
  bgt $v0, 1, prompt_and_read_operation    # if operation greater than 1, reprompt user 

  addi $s0, $v0, 0                         # save operation in $s0

prompt_and_read_key:                       
  li $v0, 4                                # print string code for syscall
  la $a0, str_key                          # load string to be printed
  syscall                                  # print prompt for user to input key

  li $v0, 5                                # read integer code for syscall
  syscall                                  # read integer from user

  jal calculate_key                        # calculate key, stored in $s1

  beq $s1, $zero, prompt_and_read_key      # if key is 0, reprompt user
  blt $s1, $0, prompt_and_read_key         # if key is less than 0, reprompt user

prompt_and_read_text:                   
  li $v0, 4                                # print string code for syscall
  la $a0, str_text                         # load string to be printed
  syscall                                  # print prompt for user to input string

  li $v0, 8                                # read string code for syscall
  la $a0, text                             # load number of allowed bytes in
  li $a1, 63                               # maximum number of characters to read 
  syscall                                  # read user input of string   

  la $a0, text                             # load input string in $a0
  jal string_length                        # input string length saved in $s2

  beq $s0, 0, skip_negation                # if encrytion command, start encryption
  subu $s1, $zero, $s1                     # otherwise negate the key

skip_negation:

  jal init_caesar                          # initialize encryption/decryption algorithm

end:                         
  li $v0, 4                                # print string code for syscall
  la $a0, str_result                       # load string to be printed
  syscall                                  # print prompt for user to input string

  li $v0, 4                                # print string code for syscall
  move $a0, $s3                            # load encrypted/decrypted string to be printed
  syscall                                  # print encrypted/decrypted string

  li $v0, 4                                # print string code for syscall
  la $a0, str_exit                         # load exit message
  syscall                                  # print exit message

  li $v0, 10                               # exit program code
  syscall                                  # exit program

####################
### Helper Functions
####################

calculate_key:
  li $t0, 26                               # load 26 (as there are 26 letters in alphabet)
  div $v0, $t0                             # divide given key by 26
  mfhi $s1                                 # $s1 is v0 % 26
  jr $ra

calculate_offset:
  addi $sp, $sp, -8                        # decryment stack pointer by 8
  sw $a0, 0($sp)                           # take the first chunk for $a0
  sw $ra, 4($sp)                           # take the second chunk for $ra
  
  jal test_case                            # $v0 is 0 if char to test is lower case, 1 if uppercase

  lw $a0, 0($sp)                           # restore $sp
  lw $ra, 4($sp)
  addi $sp, $sp, 8

  beq $v0, 0, encrypt_lower_case           # if lowercase, jump

encrypt_upper_case:
  beq $s0, 1, decrypt_upper_case           # if user specified decryption algoritim, jump
  li $v0, 65                               # return char offset of 65 (ascii 'A')
  jr $ra

decrypt_upper_case:
  li $v0, 90                               # return char offset of 90 (ascii 'Z')
  jr $ra

encrypt_lower_case:
  beq $s0, 1, decrypt_lower_case           # if user specified decryption algoritim, jump
  li $v0, 97                               # return char offset of 97 (ascii 'a')
  jr $ra

decrypt_lower_case:
  li $v0, 122                              # return char offset of 122 (ascii 'z')
  jr $ra

test_case:
  blt $a0, 97, is_upper_case               # if character to test is less than 97 (ascii 'a'), it must be uppercase
  li $v0, 0                                # otherwise, return 0 since lower case
  jr $ra

is_upper_case:
  li $v0, 1                                # return 1 since upper case
  jr $ra

test_space:
  li $t0, 32                               # load ascii 32 into $t0
  beq $a0, $t0, is_space                   # if character is equal to 32, jump
  li $v0, 0                                # otherwise return 0 for "false"
  jr $ra

is_space:
  li $v0, 1                                # return 1 for "true"
  jr $ra

string_length:
  addi $sp, $sp, -8                        # make space for 8 bytes on stack
  sw $a0, 0($sp)                           # $a0 gets first chunk
  sw $ra, 4($sp)                           # $a1 gets second chunk

  li $t0, 0                                # initialize index to 0
  li $t1, 0                                # initialize current char to 0
  move $t2, $a0                            # move user input string to $t2

string_length_loop:
  lb $t1, 0($t2)                           # load character from user input string to $t1
  beq $t1, $zero, string_length_exit       # $t1 character from user input string is 0 (ascii "\00"), exit
  beq $t1, 10, string_length_exit          # $t1 character from user input string is 10 (ascii "\n"), exit
  move $a0, $t1                            # move current char to $a0 
  addi $t2, $t2, 1                         # increment index of user input string
  addi $t0, $t0, 1                         # increment index
  j string_length_loop

string_length_exit:
  lw $a0, 0($sp)                           # restore stack
  lw $ra, 4($sp)
  addi $sp, $sp, 8

  move $s2, $t0                            # move result to $s2
  jr $ra

###########################
### Caesar Cypher algorithm
###########################

init_caesar:
  li $v0,9                                # amount code for syscall   
  move $a0, $s2                           # allocate equal space in $v0 as length of input     
  syscall
  move $s3, $v0                           # store buffer in $s3 
  move $a0, $s2                           # store string length in $a0
  li $a1, 0                               # initialize $a1 to act as index variable
  move $a2, $s3                           # move buffer to $a2
  jal caesar                              # perform caeasar algorithm

  j end                                   # begin end of program

caesar:  
  addi $sp, $sp -16                       # move stack pointer down 16 bytes to make room for 4 variables        
  sw $a0, 0($sp)                          # $a0 takes first spot of stack
  sw $a1, 4($sp)                          # $a1 takes second spot of stack
  sw $a2, 8($sp)                          # $a2 takes third spot of stack
  sw $ra, 12($sp)                         # $ra takes fourth spot so we can properly recurse 

  li $t5, 0                               # initialize $t5
  sb $t5, 0($a2)                          # store the byte value at $t5 into the first element of the buffer in $a2

  bge $a1, $a0, end_caesar                # determine whether we have reached the end of the string. if so, call end-caesar

  addi $t1, $a0, 0                        # move the string length into the $t1 register

  lb $a0, text($a1)                       # load the byte pointed to by the index at $a1 into $a0


  jal test_space                          # test if current char to test is a space
  beq $v0, 0, caesar_formula              # if false, modify character

  li $t5, 32                              # otherwise, it is a space
  sb $t5, 0($a2)                          # store space character back into computed string
  j get_next                              # recurse into next character

caesar_formula:
  jal calculate_offset                    # offset set to $v0 from this proceedure
  addi $t2, $v0, 0                        # move $t0 to $t2

  li $t4, 26                              # set $t4 to 26
  sub $t3, $a0, $t2                       # sub char by offset, set in $t3
  add $t3, $t3, $s1                       # add $s1 to $t3, set in $t3
  div $t3, $t4                            # div $t3 by $t4
  mfhi $t3                                # set previous result in $t3
  add $t3, $t3, $t2                       # add $t2 to $t3, set in $t3
  sb $t3, 0($a2)                          # store byte

get_next:
  move $a0, $t1                           # move result into $a0
  addi $a1, $a1, 1                        # increment index by 1
  addi $a2, $a2, 1                        # increment buffer by 1
  jal caesar                              # continue recursing

end_caesar:
  lw $a0, 0($sp)                          # restore stack pointer to where is was originally
  lw $a1, 4($sp)
  lw $a2, 8($sp)
  lw $ra, 12($sp)
  addi $sp, $sp, 16         
  jr $ra

.globl main
