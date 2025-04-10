.global _start

.section .data
filename_in:  .asciz "cuadrante.bin"
filename_out: .asciz "interpolado.bin"
key:          .byte 0x5A

.section .bss
buffer:         .skip 400
buffer_interp:  .skip 1521

.section .text

_start:
    // Abrir archivo de entrada
    ldr     r0, =filename_in
    mov     r1, #0  // O_RDONLY
    mov     r7, #5  // syscall: open
    svc     #0
    mov     r8, r0  // r8 = fd_in

    // Leer datos de entrada
    ldr     r1, =buffer
    mov     r2, #400
    mov     r0, r8
    mov     r7, #3  // syscall: read
    svc     #0
    mov     r6, r0

    // Cifrado XOR con la clave
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

// Interpolación bilineal (20x20 a 39x39)
interp_inicio:
    ldr r0, =buffer
    ldr r1, =buffer_interp
    mov r2, #0
interp_loop_y:
    cmp r2, #19
    bge guardar_binario
    mov r3, #0
interp_loop_x:
    cmp r3, #19
    bge fin_interp_x

    // Calcular índice base en la matriz original (20x20)
    mov r8, r2, lsl #5      // r8 = y * 32
    sub r8, r8, r2, lsl #2  // r8 = y * 28
    add r8, r8, r3          // r8 += x

    add r11, r0, r8
    ldrb r4, [r11]        // A
    ldrb r5, [r11, #1]    // B
    ldrb r6, [r11, #20]   // C
    ldrb r7, [r11, #21]   // D

    // Índice en buffer de 39x39: pos = (2*y * 39) + 2*x
    mov r9, r2
    lsl r9, r9, #1         // r9 = 2*y
    mov r10, r9
    lsl r9, r9, #5         // r9 = 2*y * 32
    add r9, r9, r10, lsl #1 // + (2*y * 2) → r9 = 2*y*36
    add r9, r9, r10, lsl #0 // + (2*y) → r9 = 2*y*37
    add r9, r9, r10        // + (2*y) → r9 = 2*y*39
    lsl r10, r3, #1        // r10 = 2*x
    add r9, r9, r10        // r9 = final index

    // A
    strb r4, [r1, r9]

    // (A + B) / 2
    add r12, r4, r5
    lsr r12, r12, #1
    add r14, r9, #1
    strb r12, [r1, r14]

    // (A + C) / 2
    add r12, r4, r6
    lsr r12, r12, #1
    add r13, r9, #39
    strb r12, [r1, r13]

    // (A + B + C + D) / 4
    add r12, r4, r5
    add r12, r12, r6
    add r12, r12, r7
    lsr r12, r12, #2
    add r14, r13, #1
    strb r12, [r1, r14]

    add r3, r3, #1
    b interp_loop_x

fin_interp_x:
    add r2, r2, #1
    b interp_loop_y

guardar_binario:
    // Abrir archivo de salida (O_WRONLY | O_CREAT | O_TRUNC)
    ldr     r0, =filename_out
    mov     r1, #0x241
    mov     r2, #0x1A4
    mov     r7, #5
    svc     #0
    mov     r8, r0  // fd_out

    // Escribir los 1521 bytes de buffer_interp al archivo
    ldr     r1, =buffer_interp
    mov     r2, #1521
    mov     r0, r8
    mov     r7, #4
    svc     #0

    // Salir
    mov     r0, #0
    mov     r7, #1
    svc     #0


