.set noreorder
.set noat
.globl __start  
.section text

# 寄存器建议使用 $t0 - $t7
# 循环展开
# !! 任何跳转之后后面都要有延迟槽！！！！！！！！
# bne/beq/jr/j/...
# nop
# 错误！！！addu $t7,$t7,0x1  是【addiu】

__start:
.text

    # 假设要计算的数，存储在了 地址0x8040_0000
    lui $t7,0x8040  # 第一个要计算的数的地址
    lui $t3,0x8048  # 总数 512K t3 = 0x8048_0000，加到这个数之后，就停下来了
    lui $t4,0x8050 # 存储计算结果 0x8050_0000 -- SRAM 0x4_0000

    # addu $t3,$t3,2 # 展开1次

out_loop:
    lw $t0,0($t7)     # t0 = number
    ori $t2,$zero,0x0 # t2 = 0,save result

# #####
    # 内循环1
    ori $t6,$zero,32  # t6 = xx 循环8次，循环展开3次
    ori $t5,$zero,0   # t5 = 0
loop:
    # 1
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1
    # 2
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1
    # 3
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1
    # 4
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1

    addiu $t5,$t5,0x4    # t5 += 4
    bne  $t6,$t5,loop
    nop 

    # write to SRAM
    sw    $t2,0($t4) # save result
    addiu $t4,$t4,4    # t4 += 4
# #####

# #####
    addiu $t7,$t7,4 # t7 += 4

    lw $t0,0($t7)     # t0 = number
    ori $t2,$zero,0x0 # t2 = 0,save result

    # 内循环2
    ori $t6,$zero,32  # t6 = xx 循环8次，循环展开3次
    ori $t5,$zero,0   # t5 = 0
loop2:
    # 1
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1
    # 2
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1
    # 3
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1
    # 4
    ori  $t1,$t0,0x0     # t1 = t0
    andi $t1,$t1,0x1    # t1 &= 0x1
    addu $t2,$t2,$t1    # t2 += t1
    srl  $t0,$t0,0x1    # t0 >>= 0x1

    addiu $t5,$t5,0x4    # t5 += 4
    bne  $t6,$t5,loop2
    nop 

    # write to SRAM
    sw    $t2,0($t4) # save result
    addiu $t4,$t4,4    # t4 += 4
# #####

# #####
    addiu $t7,$t7,4 # t7 += 4
    bne   $t7,$t3,out_loop
    nop

# #########################################
# 下面的不要动
end:
    jr    $ra
    ori   $zero, $zero, 0 # nop

# .text
#     ori $t0, $zero, 0x1   # t0 = 1
#     ori $t1, $zero, 0x1   # t1 = 1
#     xor $v0, $v0,   $v0   # v0 = 0
#     ori $v1, $zero, 8     # v1 = 8
#     lui $a0, 0x8040       # a0 = 0x80400000
# 
# loop:
#     addu  $t2, $t0, $t1   # t2 = t0+t1
#     ori   $t0, $t1, 0x0   # t0 = t1
#     ori   $t1, $t2, 0x0   # t1 = t2
#     sw    $t1, 0($a0)
#     addiu $a0, $a0, 4     # a0 += 4
#     addiu $v0, $v0, 1     # v0 += 1
# 
#     bne   $v0, $v1, loop
#     ori   $zero, $zero, 0 # nop