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
    bgt copy_edges
    mov r3, #0
interp_loop_x:
    cmp r3, #19
    bgt fin_interp_x

    // Índice en 20x20: y * 20 + x
    mov r4, r2
    mov r5, #20
    mul r6, r4, r5
    add r6, r6, r3

    add r7, r0, r6
    ldrb r8, [r7]      // A
    ldrb r9, [r7, #1]   // B
    ldrb r10, [r7, #20] // C
    ldrb r11, [r7, #21] // D

    // Índice en 39x39: (2*y)*39 + 2*x
    mov r12, r2
    lsl r12, r12, #1          // 2*y
    mov r13, #39
    mul r14, r12, r13         // r14 = 2*y*39
    mov r6, r3
    lsl r6, r6, #1            // 2*x
    add r14, r14, r6          // r14 = final index

    add r7, r1, r14           // r7 apunta a buffer_interp[pos]

    // A
    strb r8, [r7]

    // (A + B) / 2
    add r6, r8, r9
    lsr r6, r6, #1
    strb r6, [r7, #1]

    // (A + C) / 2
    add r6, r8, r10
    lsr r6, r6, #1
    strb r6, [r7, #39]

    // (A + B + C + D) / 4
    add r6, r8, r9
    add r6, r6, r10
    add r6, r6, r11
    lsr r6, r6, #2
    strb r6, [r7, #40]

    add r3, r3, #1
    b interp_loop_x

fin_interp_x:
    add r2, r2, #1
    b interp_loop_y

// Copiar última fila y columna
copy_edges:
    // Copiar columna 38 desde original[x][19]
    mov r2, #0
copy_col:
    cmp r2, #20
    bge copy_row
    mov r3, #19
    mov r4, r2
    mov r5, #20
    mul r6, r4, r5
    add r6, r6, r3
    ldr r0, =buffer
    ldrb r7, [r0, r6]

    ldr r1, =buffer_interp
    mov r4, r2
    lsl r4, r4, #1
    mov r5, #39
    mul r6, r4, r5
    add r6, r6, #38
    strb r7, [r1, r6]
    add r2, r2, #1
    b copy_col

copy_row:
    // Copiar fila 38 desde original[19][x]
    mov r3, #0
copy_row_loop:
    cmp r3, #20
    bge copy_corner
    mov r2, #19
    mov r4, #20
    mul r6, r2, r4
    add r6, r6, r3
    ldr r0, =buffer
    ldrb r7, [r0, r6]

    ldr r1, =buffer_interp
    mov r4, #38
    mov r5, #39
    mul r6, r4, r5
    lsl r8, r3, #1
    add r6, r6, r8
    strb r7, [r1, r6]
    add r3, r3, #1
    b copy_row_loop

copy_corner:
    // Copiar [19][19] → [38][38]
    mov r2, #19
    mov r3, #20
    mul r4, r2, r3
    add r4, r4, #19
    ldr r0, =buffer
    ldrb r5, [r0, r4]
    ldr r1, =buffer_interp
    mov r6, #38
    mov r7, #39
    mul r8, r6, r7
    add r8, r8, #38
    strb r5, [r1, r8]

// Guardar resultado
guardar_binario:
    ldr     r0, =filename_out
    mov     r1, #0x241
    mov     r2, #0x1A4
    mov     r7, #5
    svc     #0
    mov     r8, r0

    ldr     r1, =buffer_interp
    mov     r2, #1521
    mov     r0, r8
    mov     r7, #4
    svc     #0

    mov     r0, #0
    mov     r7, #1
    svc     #0


