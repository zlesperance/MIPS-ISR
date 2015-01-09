# Zach Lesperance

# c0$13 = 32768 ( 1000 0000 0000 0000 ) timer
#       =  2048 ( 0000 1000 0000 0000 ) key hit
#       = 34816 ( 1000 1000 0000 0000 ) timer & keyhit

	.kdata

	# Allocate space for registers. Trying this with the stack first
	tempt0: .space 4 # $t0
	tempa0: .space 4 # $a0
	tempv0: .space 4 # $v0

	.ktext 0x80000180 # ISR Starting Address

	# Save Registers
	
	la $k0, tempt0
	sw $t0, 0($k0)
	
	la $k0, tempa0
	sw $a0, 0($k0)
	
	la $k0, tempv0
	sw $v0, 0($k0)

	mfc0 $t0, $12 # read status register
	mfc0 $k0, $13 # read cause register
	add $a0, $k0, $0 # copy cause register to $a0
	mfc0 $v0, $9 #read counter register

	beq $a0, 2048, kb # does the cause register equal the value for keyboard
	beq $a0, 34816, kb
	beq $a0, 32768, timer0
	j no_int

timer0:
	mtc0 $0, $9
	li $k1, 't'	
	la $k0, charbuffer
	sw $k1, 0($k0)
	
	j no_int
	
kb:
	lui $t0, 0xFFFF
	add $v0, $0, $0
	
kbwait:
	# only wait 10 times
	lw $k0, 0($t0)
	andi $k0, $k0, 0x01
	addi $v0, $v0, 1
	beq $v0, 10, kbnowait
	beq $k0, $0, kbwait
	lw $k1, 4($t0)
	la $k0, charbuffer
	sw $k1, 0($k0)
	
kbnowait:
	j no_int
	
no_int:
	srl $a0 $k0 2 # Extract ExcCode Field from Cause Register
	andi $a0 $a0 0xf
	bne $a0 0 ret # 0 means exception was an interrupt

	j no_ext_int
	
ret:

# (non-external-interrupt) exception. Skip offending instruction
# to avoid infinite loop

	mfc0 $k0 $14	# Bump EPC Register
	addiu $k0 $k0 4 # Skip faulting instruction
					# (Need to handle delayed branch case here)
	mtc0 $k0 $14

no_ext_int:

# processor state restore
	mtc0 $0 $13	# Clear Cause Register
	mfc0 $k0, $12
	andi $k0, 0xfffd	# Preserve all bits except Exception level = 0
	ori  $k0, 0x1		# Set interrupt enable.
	mtc0 $k0, $12
	
# Restore Registers

	la $k0, tempt0
	lw $t0, 0($k0)
	
	la $k0, tempa0
	lw $a0, 0($k0)
	
	la $k0, tempv0
	lw $v0, 0($k0)
	
	eret
	
# Jump Start Main

.text
.globl __start
.globl main

__start:
	jal main
	nop
	li $v0 10
	syscall		# syscall 10 == exit

main:

	mfc0 $t0, $12
	
	lui $s0, 0xFFFF
	li	$t0, 0x02
	sw	$t0, 0($s0)
	li	$t0, 0x00
	sw	$t0, 8($s0)
	
	li $t0, 30	# Every 30 ticks
	mtc0 $t0, $11	# if $9 == $11, timer interrupt
	mtc0 $0, $9		# timer counter reset
	
	mfc0 $t0, $12
	lui $t0, 0x3000
	# ori $t0, 0x8011	# enabling only timer (mask)
	ori $t0, 0x0811	# enabling only keyboard (mask)
	mtc0 $t0, $12
	
	li $t0, 8
	sw $t0, flag
	
	lui $s0, 0xFFFF # base address for display
	
print_ch:
	la $t2, charbuffer
	lw $t0, 0($t2)
	beq $t0, $0, print_ch
	
wait0:
	
	lw $t1, 8($s0)
	andi $t1, $t1, 0x01
 	beq $t1, $0, wait0
	sw  $t0, 12($s0)   # send char to a display
	sw  $0, 0($t2)
	
j print_ch

.data
.globl flag
flag: .word 0
acs: .asciiz "99\n"
charbuffer: .data 4 # 1 character buffer
