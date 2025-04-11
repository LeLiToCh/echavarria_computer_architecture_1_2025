.global _start

.section .data
filename_in:    .asciz "cuadrante.bin"    @ Nombre del archivo de entrada que contiene el cuadrante encriptado
filename_out:   .asciz "interpolado.bin"  @ Nombre del archivo de salida donde se guarda la imagen interpolada
key:            .byte 0x5A                @ Clave XOR usada para desencriptar los datos
val_4900:       .word 4900                @ 70x70 = 4900: cantidad de bytes del cuadrante original
val_19321:      .word 19321               @ 139x139 = 19321: tamaño de la imagen interpolada

.section .bss
buffer:         .skip 4900         @ Espacio reservado para cargar y desencriptar el cuadrante original
buffer_interp:  .skip 19321        @ Espacio reservado para almacenar la imagen interpolada

.section .text

_start:
    @ Abrir el archivo cuadrante.bin en modo lectura
    ldr     r0, =filename_in
    mov     r1, #0              @ O_RDONLY
    mov     r7, #5              @ syscall open
    svc     #0
    mov     r8, r0              @ Guardamos el descriptor de archivo en r8

    @ Leer los datos binarios (4900 bytes) en el buffer
    ldr     r1, =buffer
    ldr     r9, =val_4900
    ldr     r2, [r9]            @ Tamaño a leer = 4900
    mov     r0, r8              @ Descriptor de archivo
    mov     r7, #3              @ syscall read
    svc     #0
    mov     r6, r0              @ r6 = cantidad de bytes leídos

    @ Desencriptar el buffer usando XOR con la clave
    ldr     r4, =buffer
    ldr     r5, =key
    ldrb    r5, [r5]            @ r5 = clave XOR
    mov     r3, #0              @ Índice

loop_dec:
    cmp     r3, r6              @ Ver si se desencripto todo el archivo
    bge     interp_inicio
    ldrb    r0, [r4, r3]        @ Leer byte encriptado
    eor     r0, r0, r5          @ Desencriptar con XOR
    strb    r0, [r4, r3]        @ Guardar el byte desencriptado
    add     r3, r3, #1
    b       loop_dec

@ INICIO INTERPOLACIÓN BILINEAL 

interp_inicio:
    ldr r0, =buffer             @ Puntero a imagen original (70x70)
    ldr r1, =buffer_interp      @ Puntero a buffer de salida (139x139)
    mov r2, #0                  @ Índice Y de la imagen original

interp_loop_y:
    cmp r2, #69
    bgt copy_edges              @ Cuando se alcanza la última fila, pasar a bordes
    mov r3, #0                  @ Índice X

interp_loop_x:
    cmp r3, #69
    bgt fin_interp_x            @ Última columna, siguiente fila

    @ Calcular posición en buffer original (A)
    mov r4, r2
    mov r5, #70
    mul r6, r4, r5
    add r6, r6, r3
    add r7, r0, r6              @ r7 apunta al byte A
    ldrb r8, [r7]               @ A
    ldrb r9, [r7, #1]           @ B = A+1
    add r10, r7, #70
    ldrb r10, [r10]            @ C = A+70
    ldrb r11, [r7, #71]         @ D = A+71

    @ Calcular posición en buffer interpolado (coordenadas * 2)
    mov r12, r2
    lsl r12, r12, #1            @ r12 = fila*2
    mov r13, #139
    mul r14, r12, r13           @ r14 = fila*2 * 139
    mov r6, r3
    lsl r6, r6, #1              @ col*2
    add r14, r14, r6
    add r7, r1, r14             @ r7 apunta a la posición en buffer interpolado

    @ Escribir píxeles interpolados en el bloque 2x2
    strb r8, [r7]               @ A (arriba izquierda)
    add r6, r8, r9
    lsr r6, r6, #1
    strb r6, [r7, #1]           @ (A+B)/2 (arriba derecha)
    add r6, r8, r10
    lsr r6, r6, #1
    strb r6, [r7, #139]         @ (A+C)/2 (abajo izquierda)
    add r6, r8, r9
    add r6, r6, r10
    add r6, r6, r11
    lsr r6, r6, #2
    strb r6, [r7, #140]         @ (A+B+C+D)/4 (abajo derecha)

    add r3, r3, #1              @ Siguiente columna
    b interp_loop_x

fin_interp_x:
    add r2, r2, #1              @ Siguiente fila
    b interp_loop_y

@ COPIAR EXTREMOS 

copy_edges:
    mov r2, #0

copy_col:
    cmp r2, #70
    bge copy_row
    mov r3, #69                @ Última columna
    mov r4, r2
    mov r5, #70
    mul r6, r4, r5
    add r6, r6, r3
    ldr r0, =buffer
    ldrb r7, [r0, r6]          @ Último píxel de cada fila

    ldr r1, =buffer_interp
    mov r4, r2
    lsl r4, r4, #1
    mov r5, #139
    mul r6, r4, r5
    add r6, r6, #138           @ Posición final en interpolada
    strb r7, [r1, r6]
    add r2, r2, #1
    b copy_col

copy_row:
    mov r3, #0

copy_row_loop:
    cmp r3, #70
    bge copy_corner
    mov r2, #69
    mov r4, #70
    mul r6, r2, r4
    add r6, r6, r3
    ldr r0, =buffer
    ldrb r7, [r0, r6]          @ Última fila

    ldr r1, =buffer_interp
    mov r4, #138
    mov r5, #139
    mul r6, r4, r5
    lsl r8, r3, #1
    add r6, r6, r8
    strb r7, [r1, r6]
    add r3, r3, #1
    b copy_row_loop

copy_corner:
    @ Último píxel de la última fila y columna
    mov r2, #69
    mov r3, #70
    mul r4, r2, r3
    add r4, r4, #69
    ldr r0, =buffer
    ldrb r5, [r0, r4]

    ldr r1, =buffer_interp
    mov r6, #138
    mov r7, #139
    mul r8, r6, r7
    add r8, r8, #138
    strb r5, [r1, r8]

@GUARDAR IMAGEN INTERPOLADA 

guardar_binario:
    ldr     r0, =filename_out
    mov     r1, #0x241        @ O_WRONLY | O_CREAT
    mov     r2, #0x1A4        @ Permisos: 0644
    mov     r7, #5            @ syscall open
    svc     #0
    mov     r8, r0            @ Descriptor de archivo de salida

    ldr     r1, =buffer_interp
    ldr     r9, =val_19321
    ldr     r2, [r9]          @ Tamaño a escribir
    mov     r0, r8
    mov     r7, #4            @ syscall write
    svc     #0

    @ Salida del programa
    mov     r0, #0
    mov     r7, #1            @ syscall exit
    svc     #0

