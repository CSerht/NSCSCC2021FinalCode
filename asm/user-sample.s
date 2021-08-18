.set noreorder
.set noat
.globl __start  
.section text

# 可用寄存器 $2 - $23，其他未测试
# 寄存器建议使用 $t0 - $t7 , $s0 - $s7
# 循环展开，特值带入
# !! 任何跳转之后后面都要有延迟槽！！！！！！！！
# bne/beq/jr/j/...
# nop
# 区分 addu addiu

__start:
.text
    lui $t0,0x8040 # 数组char a起始地址  0x8040_0000 
    li $2,80      # i * 10 * 8
    li $3,8       # j * 8

    lui $t1,0x8060 # 数组int  b起始地址  0x8060_0000
    li $4,4       # i * 4


# for(i=0; i<3000; i++) {
    li $t2,0    # i = 0
    li $t3,2999 # i [0,3000)  [0,2999]
    
loop1:
    li $t4,0    # sum = 0

    # for(j=0; j<10; j++) {
    li $t5,0   # j = 0
    li $t6,9  # j [0,10)  [0,9]
    li $t7,0   # ave = 0

loop2:
    # get a[i][j][k]
    # addr =  0x80400000+i*80+j*8+k
    mul $t8,$t2,$2  # $t8 = i * 80
    addu $t9,$t0,$t8 # $t9 = 0x8040_0000 + i*80
    mul $t8,$t5,$3   # $t8 = j * 8
    addu $t9,$t9,$t8 # $t9 = (0x8040_0000 + i*80) + j*8

    # a[i][j][0] = mem[0($t9)]
    # ###########
    # get ave

# //排序后array[0]里是最大数,n = 8  
# //该宏会修改s0-s7寄存器
# bubble_sort_char(array, n) 
    ori   $s6, $zero, 0           # t6 =  i         
    ori   $s7, $zero, 7         # t7 =  n-1         
# for(i=0; i <n; i++)                     
too1: 
    ori   $s5, $zero, 0       # t5 =  j       
    addiu $s0, $zero, -1          #  -1               
    xor   $s0, $s6, $s0            #  -i               
    addiu $s0, $s0,    1          #  -i+1 = -i        
    addu  $s4, $s7, $s0            # t4 =  n-1-i       
# for(j=0; j <n-i; j++)                   
too2: # array = addr(a[i][j]) = t9
    addu  $s3, $t9, $s5     # *a[j]  // 【a[i][j]】[j]
    lb    $s1, 0($s3)             # t1 =  a[j]        
    lb    $s2, 1($s3)             # t2 =  a[j+1]    
    
    # ###################
    # swap_if_lt(t1, t2)          # if (t1 < t2) swap 

    # //swap a and b if a<b
    # //该宏会修改$7寄存器
    # swap_if_lt(a,b) 
    sltu $7, $s1,$s2   # if a < b, $7 = 1，无符号比较
    
    beq  $7, $zero, too3
    nop                  
    xor  $s2, $s2,$s1     
    xor  $s1, $s1,$s2     
    xor  $s2, $s2,$s1     
    too3: 

    # ###################

    sb    $s1, 0($s3)             # a[j]   = t1       
    sb    $s2, 1($s3)             # a[j+1] = t2       
    addiu $s5, $s5, 1                           
    bne   $s5, $s4, too2                         
    nop                                       
    addiu $s6, $s6, 1                           
    bne   $s6, $s7, too1                         
    nop 

    # 计算ave $t7，a[i][j][0] MAX; a[i][j][7] MIN
    
    # sw $t9,0($t9) # 测试

    li $t7,0
    lb $s0,2($t9) 
    addu $t7,$t7,$s0
    lb $s1,3($t9)  
    addu $t7,$t7,$s1
    lb $s2,4($t9)  
    addu $t7,$t7,$s2
    lb $s3,5($t9)  
    addu $t7,$t7,$s3 # ave = a[i][j][2,3,4,5]

    srl $t7,$t7,2 # get ave final

    # sw $t7,0($t9) # 测试

    # ###########
    addu $t4,$t4,$t7    # sum += ave

    bne $t5,$t6,loop2
    addiu $t5,$t5,1 # t5 += 1
    # }


    # b[i] addr = 0x8060_0000 + i * 4
    # b[i] = sum
    mul   $5,$t2,$4  # $5 = i * 4
    addu $6,$t1,$5  # $t6 = 0x8060_0000 + i * 4
    sw    $t4,0($6)  # b[i] = sum


    bne $t2,$t3,loop1
    addiu $t2,$t2,1
# }

 
 # #########################################
 # 单独对int的排序没问题
 # #########################################
    # //排序后array[0]里是最大数
    # //该宏会修改t0-t7寄存器
    # bubble_sort_int(array, n) 
        ori   $s6, $zero, 0           # t6 =  i           
        ori   $s7, $zero, 2999         # t7 =  n-1         
    # for(i=0; i <n-1; i++)                   
    too4: 
        ori   $s5, $zero, 0       # t5 =  j      
        addiu $s0, $zero, -1          #  -1               
        xor   $s0, $s6, $s0            #  -i               
        addiu $s0, $s0, 1          #  -i+1 = -i        
        addu  $s4, $s7, $s0            # t4 =  n-1-i       
    # for(j=0; j <n-1-i; j++)                 
    too5: # $t1 b addr
        ori   $s0, $zero,  2                    
        sllv   $s0, $s5, $s0            #       4*j         
        addu  $s3, $t1, $s0         #      *a[j]        
        lw    $s1, 0($s3)             # t1 =  a[j]        
        lw    $s2, 4($s3)             # t2 =  a[j+1]   

        # ###################
        # swap_if_lt(t1, t2)          # if (t1 < t2) swap 

        # //swap a and b if a<b
        # //该宏会修改$7寄存器
        # swap_if_lt(a,b) 
        sltu $7, $s1,$s2   # if a < b, $7 = 1，无符号比较
        
        beq  $7, $zero, too6
        nop                  
        xor  $s2, $s2,$s1     
        xor  $s1, $s1,$s2     
        xor  $s2, $s2,$s1     
        too6: 

        # ###################

        sw    $s1, 0($s3)             # a[j]   = t1       
        sw    $s2, 4($s3)             # a[j+1] = t2       
        addiu $s5, $s5, 1                           
        bne   $s5, $s4, too5                         
        nop                                       
        addiu $s6, $s6, 1                           
        bne   $s6, $s7, too4                         
        nop                                       
# #########################################


# #########################################
# 固定结尾，不要动
end:
    jr    $ra
    ori   $zero, $zero, 0 # nop

