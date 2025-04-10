.global _start

.section .data
filename: .asciz "cuadrante.bin"
key:      .byte 0x5A
newline:  .asciz "\n"
espacio:  .asciz " "
dec_buffer: .space 4

.section .bss
buffer:         .skip 400
buffer_interp:  .skip 1521

.section .text

_start:
    ldr     r0, =filename
    mov     r1, #0
    mov     r7, #5
    svc     #0
    mov     r8, r0

    bl      abrir

    mov     r0, #0
    mov     r7, #1
    svc     #0

abrir:
    ldr     r1, =buffer
    mov     r2, #400
    mov     r0, r8
    mov     r7, #3
    svc     #0
    mov     r6, r0

    ldr     r4, =buffer
    ldr     r5, =key
    ldrb    r5, [r5]
    mov     r3, #0

loop_dec:
    cmp     r3, r6
    bge     interp_inicio
    ldrb    r0, [r4, r3]
    eor     r0, r0, r5
    strb    r0, [r4, r3]
    add     r3, r3, #1
    b       loop_dec

interp_inicio:
    ldr r0, =buffer
    ldr r1, =buffer_interp
    mov r2, #0
interp_loop_y:
    cmp r2, #19
    bge imprimir_interp
    mov r3, #0
interp_loop_x:
    cmp r3, #19
    bge fin_interp_x

    mov r8, r2, lsl #4
    add r8, r8, r2, lsl #2
    add r8, r8, r3

    add r11, r0, r8
    ldrb r4,[r11]
    ldrb r5,[r11,#1]
    ldrb r6,[r11,#20]
    ldrb r7,[r11,#21]

    mov r9, r2, lsl #6
    add r9, r9, r2, lsl #3
    add r9, r9, r2, lsl #2
    add r9, r9, r2, lsl #1
    add r9, r9, r2
    mov r9, r9, lsl #1
    add r9, r9, r3, lsl #1

    strb r4,[r1,r9]

    add r10,r4,r5
    mov r10,r10,lsr #1
    add r11,r1,r9
    add r11,r11,#1
    strb r10,[r11]

    add r12,r9,#39
    add r12,r12,r1
    add r10,r4,r6
    mov r10,r10,lsr #1
    strb r10,[r12]

    add r10,r4,r5
    add r10,r10,r6
    add r10,r10,r7
    mov r10,r10,lsr #2
    add r11,r12,#1
    strb r10,[r11]

    add r3,#1
    b interp_loop_x
fin_interp_x:
    add r2,#1
    b interp_loop_y

imprimir_interp:
    ldr r4, =buffer_interp
    mov r6, #1521
    mov r3, #0
    mov r10,#0
    mov r9, #39

print_loop:
    cmp r3, r6
    bge end_print

    ldrb r0,[r4,r3]
    push {r1-r7,lr}
    bl print_byte_decimal
    pop {r1-r7,lr}

    ldr r0,=espacio
    mov r1,r0
    mov r2,#1
    mov r7,#4
    svc #0

    add r10,r10,#1
    cmp r10,r9
    blt skip_nl

    ldr r0,=newline
    mov r1,r0
    mov r2,#1
    mov r7,#4
    svc #0
    mov r10,#0

skip_nl:
    add r3,r3,#1
    b print_loop

end_print:
    bx lr

print_byte_decimal:
    mov r1,#10
    mov r2,r0
    mov r3,#0
    ldr r4,=dec_buffer

clean_buffer:
    mov r5,#0
    str r5,[r4]

conv_loop:
    mov r0,r2
    udiv r5,r0,r1
    mls r6,r5,r1,r0
    add r6,r6,#48
    strb r6,[r4,r3]
    add r3,r3,#1
    mov r2,r5
    cmp r2,#0
    bne conv_loop

subs r3,r3,#1

print_digits:
    ldr r1,=dec_buffer
    add r1,r1,r3
    ldrb r0,[r1]
    sub sp,sp,#1
    strb r0,[sp]
    mov r0,#1
    mov r1,sp
    mov r2,#1
    mov r7,#4
    svc #0
    add sp,sp,#1
    subs r3,r3,#1
    bge print_digits
    bx lr
