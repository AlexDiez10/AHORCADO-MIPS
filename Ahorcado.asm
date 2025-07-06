.data
# =================================================================================================
# SECCIÓN DE DATOS
# =================================================================================================

# Lista de palabras para el juego con sus offsets
palabras:       .asciiz "ALEJANDRO", "ISSAC", "PROYECTO", "PROGRAMACION", "ORGANIZACION", "COMPUTADOR", "ALEXANDRA", "MIPS", "MARS", "APROBADO"
offsets:        .word 0, 10, 16, 25, 38, 51, 62, 72, 77, 82  # Offsets para acceder a cada palabra

# Mensajes de prueba y estado del juego
msg3:            .asciiz "Se encontro un total de: "

# Variables del juego
palabra_aleatoria: .space 32   # Almacena la palabra seleccionada aleatoriamente
palabra_oculta:    .space 32   # Almacena la palabra con letras ocultas (X)
respuesta:         .space 3    # Buffer para la respuesta de reinicio (S/N)
vidas: .word 3                 # Contador de vidas (inicia en 3)
ronda: .word 0                 # Contador de rondas (inicia en 0)

# Mensajes del juego
Presentación:   .asciiz "\nBienvenido al juego del Ahorcado"
inicio:         .asciiz "\n\nInicia partida\n"
mensaje_rondas: .asciiz "\nRonda actual: "
mensaje_vidas:  .asciiz "\nVidas restantes: "
mensaje_palabra_oculta: .asciiz "\nPalabra oculta: "
mensaje_reinicio:       .asciiz "\n¿Quieres jugar otra vez? (Si/No): "
pista:          .asciiz "\nAyuda: "
pista_fin:      .asciiz " está en la palabra.\n"
mensaje:        .asciiz "\nEscriba una letra: "
gano:           .asciiz "\n¡Felicitaciones! Descubrió la palabra oculta: "
perdio:         .asciiz "\n¡Perdiste! La palabra era: "
space :         .asciiz "\n"
delimitador:    .asciiz "\n-------------------------------"

.text
# =================================================================================================
# PROGRAMA PRINCIPAL
# =================================================================================================
main:
    # Mostrar mensaje de bienvenida
    li $v0, 4
    la $a0, Presentación
    syscall
    
    loop_partida:
        # Generar nueva palabra aleatoria y su versión oculta
        jal Generar_palabra
    
        # Indicar inicio de partida
        li $v0, 4
        la $a0, inicio
        syscall
    
    loop_juego:
        # Mostrar estado actual de la ronda
        jal Imprimir_contenido_ronda

        # Solicitar letra al jugador
        jal Solicitar_letra
        move $a0, $v0
        
        # Buscar la letra en la palabra
        jal Buscar_letra_en_palabra

        # Si la letra no está (retorno 0), restar vida
        beqz $v0, llamar_restar_vidas  # Saltar a helper
            j continuar_flujo

        llamar_restar_vidas:
        jal Restar_vidas  # Llamada correcta con jal

        continuar_flujo:
        # Separador visual
        li $v0, 4
        la $a0, delimitador
        syscall 
    
        # Verificar si el jugador ganó
        j verificar_si_gano

    verificar_si_gano:
        # Comprobar si se adivinó toda la palabra
        jal verificar_victoria
        beqz $v0, verificar_si_perdio  # Si no ganó, verificar vidas
        j fin_ganador

    verificar_si_perdio:
        # Comprobar si se acabaron las vidas
        lw $t0, vidas
        beqz $t0, fin_perdio
        j loop_juego  # Continuar juego

    fin_ganador:
        # Mostrar mensaje de victoria
        li $v0, 4
        la $a0, gano
        syscall
        la $a0, palabra_oculta
        syscall
        
        # Preguntar si quiere jugar otra partida
        jal Preguntar_reinicio
        
        # Si quiere reiniciar, comenzar nueva partida
        bnez $v0, loop_partida
        
        # Salir del juego
        li $v0, 10
        syscall

    fin_perdio:
        # Mostrar mensaje de derrota
        li $v0, 4
        la $a0, perdio
        syscall
        la $a0, palabra_aleatoria
        syscall
        
        # Preguntar si quiere jugar otra partida
        jal Preguntar_reinicio
        
        # Si quiere reiniciar, comenzar nueva partida
        bnez $v0, loop_partida
        
        # Salir del juego
        li $v0, 10
        syscall


# =================================================================================================
# FUNCIÓN: Generar_palabra
# Propósito: Selecciona una palabra aleatoria del diccionario y genera su versión oculta (con X)
# =================================================================================================
Generar_palabra:
    # Guardar dirección de retorno
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Generar índice aleatorio (0-9 para 10 palabras)
    li $v0, 42
    li $a1, 10
    syscall
    move $t0, $a0

    # Calcular dirección del offset correspondiente
    la $t1, offsets
    sll $t0, $t0, 2        # Multiplicar índice por 4 (tamaño de word)
    add $t1, $t1, $t0
    lw $t2, 0($t1)         # Cargar offset de la palabra
    
    # Obtener dirección de la palabra
    la $t3, palabras
    add $a1, $t3, $t2      # Dirección de la palabra aleatoria

    # Copiar palabra a buffer palabra_aleatoria
    la $a0, palabra_aleatoria
    jal Guardar_palabra
    
    # Generar versión oculta (XXXX...)
    la $a0, palabra_oculta
    jal Generar_Xs

    # Restaurar y retornar
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# =================================================================================================
# FUNCIÓN: Guardar_palabra
# Propósito: Copia una cadena de origen a destino
# Entrada: $a0 = destino, $a1 = origen
# =================================================================================================
Guardar_palabra:
    # Guardar dirección de origen
    addi $sp, $sp, -4
    sw $a1, 0($sp)
	
    loop_copia:
        # Cargar y guardar byte por byte
        lb $t0, 0($a1)         # Cargar byte de origen
        sb $t0, 0($a0)         # Guardar byte en destino
        beqz $t0, fin_copia    # Terminar si es null
        addi $a1, $a1, 1       # Siguiente byte (origen)
        addi $a0, $a0, 1       # Siguiente byte (destino)
        j loop_copia

fin_copia:
    # Restaurar y retornar
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# =================================================================================================
# FUNCIÓN: Generar_Xs
# Propósito: Genera una cadena de 'X' con la misma longitud que la palabra original
# Entrada: $a1 = dirección de la palabra original
# Salida: $a0 = dirección de la palabra oculta (llena de X)
# =================================================================================================
Generar_Xs:
    # Calcular longitud de la palabra original
    move $t1, $a1           # Copiar dirección de la palabra
    li $t2, 0               # Inicializar contador de longitud

    loop_calcular_longitud:
        lb $t0, 0($t1)      # Leer carácter
        beqz $t0, fin_calcular_longitud  # Terminar en null
        addi $t2, $t2, 1    # Incrementar contador
        addi $t1, $t1, 1    # Siguiente carácter
        j loop_calcular_longitud

    fin_calcular_longitud:
    # Limpiar buffer de palabra_oculta
    la $t3, palabra_oculta
    li $t4, 0
    li $t5, 32              # Tamaño máximo del buffer

    loop_limpiar:
        sb $zero, 0($t3)    # Escribir null
        addi $t3, $t3, 1
        addi $t4, $t4, 1
        blt $t4, $t5, loop_limpiar

    # Generar cadena de 'X'
    la $a0, palabra_oculta
    li $t0, 'X'             # Carácter a escribir

    loop_generar_x:
        beqz $t2, fin_generar_x  # Terminar cuando contador sea 0
        sb $t0, 0($a0)           # Escribir 'X'
        addi $a0, $a0, 1         # Siguiente posición
        addi $t2, $t2, -1        # Decrementar contador
        j loop_generar_x

    fin_generar_x:
        sb $zero, 0($a0)         # Terminar con null
        jr $ra

# =================================================================================================
# FUNCIÓN: Solicitar_letra
# Propósito: Solicita una letra al jugador y la retorna en mayúsculas
# Salida: $v0 = letra ingresada (en mayúscula)
# =================================================================================================
Solicitar_letra:
    # Mostrar mensaje
    li $v0, 4
    la $a0, mensaje
    syscall
    
    # Leer carácter 
    li $v0, 12
    syscall
    
    # Convertir a mayúscula si es necesario
    convertir_a_mayus:
        blt $v0, 'a', no_convertir_sol
        bgt $v0, 'z', no_convertir_sol
        addi $v0, $v0, -32
    no_convertir_sol:
    
    jr $ra

# =================================================================================================
# FUNCIÓN: Buscar_letra_en_palabra
# Propósito: Busca una letra en la palabra y actualiza la versión oculta
# Entrada: $a0 = letra a buscar
# Salida: $v0 = 1 si se encontró, 0 si no
# =================================================================================================
Buscar_letra_en_palabra:
    # Cargar direcciones de las palabras
    la $t0, palabra_aleatoria
    la $t1, palabra_oculta
    li $t2, 0                   # Contador de ocurrencias
    
    move $t3, $a0               # Letra a buscar (ya en mayúscula)
    
    loop_buscar:
        lb $t4, 0($t0)          # Leer carácter de palabra real
        beqz $t4, fin_buscar     # Terminar si es null
        
        # Comprobar coincidencia
        bne $t4, $t3, siguiente  # Saltar si no coincide
        
        # Letra encontrada: actualizar contador y palabra oculta
        addi $t2, $t2, 1
        sb $t3, 0($t1)          # Revelar letra en posición actual

    siguiente:
        # Avanzar a siguiente carácter
        addi $t0, $t0, 1
        addi $t1, $t1, 1
        j loop_buscar
    
    fin_buscar:
        # Mostrar resultados
        li $v0, 4
        la $a0, space
        syscall
        la $a0, msg3
        syscall
        li $v0, 1
        move $a0, $t2
        syscall
        
        # Determinar valor de retorno
        beqz $t2, no_encontrada
        li $v0, 1
        jr $ra
        
    no_encontrada:
        li $v0, 0
        jr $ra

# =================================================================================================
# FUNCIÓN: verificar_victoria
# Propósito: Comprueba si la palabra oculta coincide con la palabra real
# Salida: $v0 = 1 si son iguales (victoria), 0 si no
# =================================================================================================
verificar_victoria:
    # Cargar direcciones de las palabras
    la $t0, palabra_aleatoria
    la $t1, palabra_oculta
    
    loop_comparacion:
    	# Comparar carácter por carácter
    	lb $t2, 0($t0)     # Carácter palabra real
    	lb $t3, 0($t1)     # Carácter palabra oculta
    	beqz $t2, victoria # Si llegó al final, victoria
    	
    	# Si los caracteres difieren, continuar juego
    	bne $t2, $t3, continua
    	
    	# Avanzar a siguiente carácter
    	addi $t0, $t0, 1
    	addi $t1, $t1, 1 
    	j loop_comparacion
    		
    continua:
        # Palabra no descubierta completamente
    	li $v0, 0
    	jr $ra
    	
    victoria:
    	li $v0, 1
    	jr $ra
    	
# =================================================================================================
# FUNCIÓN: Restar_vidas
# Propósito: Reduce las vidas y da pista si solo queda 1 vida
# =================================================================================================
Restar_vidas:
    # Guardar dirección de retorno
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Restar una vida
    lw $t0, vidas
    addi $t0, $t0, -1
    sw $t0, vidas
    
    # Comprobar si queda solo 1 vida
    li $t1, 1
    bne $t0, $t1, fin_restar
    
    # Dar pista si queda 1 vida
    jal Dar_pista
    
    fin_restar:
        # Restaurar y retornar
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
# =================================================================================================
# FUNCIÓN: Dar_pista
# Propósito: Revela aleatoriamente una letra oculta
# =================================================================================================
Dar_pista:
    # Guardar dirección de retorno
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Inicializar contadores
    la $t0, palabra_aleatoria
    la $t1, palabra_oculta
    li $t2, 0               # Contador de posición
    li $t6, 0               # Contador de letras ocultas

    loop_contar:
        # Leer caracteres
        lb $t3, 0($t0)      # Carácter palabra real
        lb $t4, 0($t1)      # Carácter palabra oculta
        beqz $t3, fin_contar # Terminar al final
        
        # Verificar si la letra está oculta
        li $t5, 'X'
        beq $t4, $t5, oculta
        li $t5, '_'
        bne $t4, $t5, no_oculta

    oculta:
        # Guardar posición en pila
        addi $sp, $sp, -4
        sw $t2, 0($sp)
        addi $t6, $t6, 1    # Incrementar contador de ocultas

    no_oculta:
        # Avanzar a siguiente carácter
        addi $t0, $t0, 1
        addi $t1, $t1, 1
        addi $t2, $t2, 1
        j loop_contar

    fin_contar:
        # Si no hay letras ocultas, terminar
        beqz $t6, fin_pista

        # Elegir posición aleatoria
        li $v0, 42
        move $a1, $t6       # Límite = cantidad de ocultas
        syscall             # $a0 = índice aleatorio

        # Calcular posición en pila
        sll $a0, $a0, 2     # Multiplicar por 4
        add $sp, $sp, $a0   # Mover puntero de pila
        lw $t2, 0($sp)      # Obtener posición
        sub $sp, $sp, $a0   # Restaurar puntero

        # Revelar letra seleccionada
        la $t0, palabra_aleatoria
        add $t0, $t0, $t2   # Posición en palabra real
        lb $t3, 0($t0)      # Letra a revelar

        la $t1, palabra_oculta
        add $t1, $t1, $t2   # Posición en palabra oculta
        sb $t3, 0($t1)      # Revelar letra

        # Mostrar mensaje de pista
        li $v0, 4
        la $a0, pista
        syscall
        li $v0, 11
        move $a0, $t3
        syscall
        li $v0, 4
        la $a0, pista_fin
        syscall

        # Liberar espacio de pila
        sll $t7, $t6, 2     # t7 = t6 * 4
        add $sp, $sp, $t7

    fin_pista:
        # Restaurar y retornar
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

# =================================================================================================
# FUNCIÓN: Imprimir_contenido_ronda
# Propósito: Muestra el estado actual del juego (ronda, vidas, palabra oculta)
# =================================================================================================
Imprimir_contenido_ronda:
    # Separador visual
    li $v0, 4
    la $a0, delimitador
    syscall 

    # Mostrar número de ronda
    li $v0, 4
    la $a0, mensaje_rondas
    syscall 

    # Incrementar y mostrar ronda actual
    lw $t0, ronda
    addi $t0, $t0, 1
    sw $t0, ronda
    li $v0, 1
    lw $a0, ronda
    syscall
    
    # Mostrar vidas restantes
    li $v0, 4
    la $a0, mensaje_vidas
    syscall
    li $v0, 1
    lw $a0, vidas
    syscall
    
    #Espaciado
    li $v0, 4
    la $a0, space
    syscall
    
    # Mostrar palabra oculta
    li $v0, 4
    la $a0, mensaje_palabra_oculta
    syscall
    li $v0, 4
    la $a0, palabra_oculta
    syscall
    
    jr $ra
    
# =================================================================================================
# FUNCIÓN: Preguntar_reinicio
# Propósito: Pregunta al jugador si quiere jugar otra partida
# Salida: $v0 = 1 si sí, 0 si no
# =================================================================================================
Preguntar_reinicio:
    # Guardar dirección de retorno
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Mostrar mensaje
    li $v0, 4
    la $a0, space
    syscall
    la $a0, mensaje_reinicio
    syscall
    
    # Leer respuesta del usuario
    li $v0, 8
    la $a0, respuesta
    li $a1, 3
    syscall
    
    # Convertir a mayúscula
    lb $t0, respuesta
    convertir_resp:
        blt $t0, 'a', no_conv_resp
        bgt $t0, 'z', no_conv_resp
        addi $t0, $t0, -32
    no_conv_resp:
    
    # Comprobar respuesta
    li $v0, 0             # Por defecto: no reiniciar
    li $t1, 'S'
    beq $t0, $t1, reiniciar_si
    
    # Si no es 'S', comprobar 'N'
    li $t1, 'N'
    beq $t0, $t1, reiniciar_no
    
    # Respuesta inválida: asumir no
    j reiniciar_no
    
    reiniciar_si:
        # Reiniciar contadores
        li $t0, 0
        sw $t0, ronda
        li $t0, 3
        sw $t0, vidas
        li $v0, 1         # Retornar sí
    
    reiniciar_no:
        # Restaurar y retornar
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
