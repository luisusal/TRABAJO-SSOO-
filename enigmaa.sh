#!/bin/bash
# funciona config, frases, principal
# en teoria estadisticas esta bien
# falta el juego y validar unas cosillas

#2/11, 16:40
CONFIG_FILE="./config.cfg"
FRASES_FILE="./frases.dat"         #aqui pasamos los archivos a constante
#para mejor manejo

#------------------------------------------
TMP_FILE="/tmp/enigma_temp$$" #esto nose que es


pausa() {
    read -n 1 -s -r -p "Pulse una tecla para continuar."
    echo ""
}

limpiar_temporales() {
    rm -f /tmp/enigma_temp_* 2>/dev/null    # rm borra cualqiuer archivo que empiece por 
}

# trampa para capturar salidas inesperadas
trap 'limpiar_temporales; exit 1' INT TERM
#-----------------------------------------


#------------------------------------------------------------------
#                   MOSTRAR INFPORMACION
#--------------------------------------------------------------------
mostrar_uso() {
    echo "Error: Sintaxis de invocación incorrecta."
    echo "Sintaxis correcta: $0 [-g]"
}

mostrar_info_grupo() {
    echo "========================================================"
    echo "            INFORMACIÓN DEL GRUPO DESARROLLADOR         "
    echo "========================================================"
    echo "Integrantes del grupo:"
    echo "  - Alumno 1: Luis Corrionero Iraola"
    echo "  - Alumno 2: Roc Cardona Villalonga"
    echo ""
    echo "Lógica de ESTRATEGIA-2 (Estrategia de IA propia):"
    echo "  La IA selecciona primero las vocales y posteriormente"
    echo "  las consonantes de mayor a menor frecuencia de uso en"
    echo "  el idioma español (E, A, O, S, R, N, I, D, L, C, T, U,"
    echo "  M, P, B, G, V, Y, Q, H, F, Z, J, X, W, K)."
    echo ""
    echo "Estadística de libre elección (Menú ESTADÍSTICAS):"
    echo "  Tasa de eficacia de resolución (% de frases resueltas"
    echo "  respecto al total de rondas jugadas en el histórico)."
    echo "========================================================"
}


# COMPROBACION ARGUMENTO
if [ $# -gt 1 ]; then           # si hay GreaterThan 1 arg
    mostrar_uso                 # muestra error (mostrar_uso)
    exit 1

elif [ $# -eq 1 ]; then         # si hay un argumento (-eq 1)
    if [ "$1" = "-g" ]; then    # si el arg es -g
        mostrar_info_grupo      # muestra la info
        exit 0
    else                        # si no, muestra error (mostrar_uso)
        mostrar_uso
        exit 1
    fi
fi

# VALIDAR FICHEROS
validar_ficheros_iniciales() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$FRASES_FILE" ]; then
        echo "Error: Los archivos 'config.cfg' o 'frases.dat' no existen o estan incompletos."
        return 1
    fi
    return 0
}

#--------------------------------------------
#CONFIGURACION

    # Lógica de juego: comprobar frases suficientes, validar log, desarrollo por rondas
es_entero() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

guardar_config() {
    cat <<EOF > "$CONFIG_FILE"
JUGADORES=$JUGADORES
RONDAS=$RONDAS
PVIDA=$PVIDA
PFALLO=$PFALLO
PRESPUESTA=$PRESPUESTA
CATEGORIAS=$CATEGORIAS
ESTRATEGIA=$ESTRATEGIA
LOG=$LOG
EOF
}

# Funciones de las opciones del menú
opcion_configuracion() {
    echo "=== CONFIGURACIÓN ==="
    # Lógica para leer y modificar parámetros de config.cfg de forma persistente
    JUGADORES=$(grep '^JUGADORES=' "$CONFIG_FILE" | cut -d'=' -f2)
    RONDAS=$(grep '^RONDAS=' "$CONFIG_FILE" | cut -d'=' -f2)
    PVIDA=$(grep '^PVIDA=' "$CONFIG_FILE" | cut -d'=' -f2)
    PFALLO=$(grep '^PFALLO=' "$CONFIG_FILE" | cut -d'=' -f2)
    PRESPUESTA=$(grep '^PRESPUESTA=' "$CONFIG_FILE" | cut -d'=' -f2)
    CATEGORIAS=$(grep '^CATEGORIAS=' "$CONFIG_FILE" | cut -d'=' -f2)
    ESTRATEGIA=$(grep '^ESTRATEGIA=' "$CONFIG_FILE" | cut -d'=' -f2)
    LOG=$(grep '^LOG=' "$CONFIG_FILE" | cut -d'=' -f2)

    while true; do
        clear
        echo "=========================================="
        echo "          CONFIGURACIÓN ACTUAL            "
        echo "=========================================="
        echo "1) JUGADORES  = $JUGADORES"
        echo "2) RONDAS     = $RONDAS"
        echo "3) PVIDA      = $PVIDA"
        echo "4) PFALLO     = $PFALLO"
        echo "5) PRESPUESTA = $PRESPUESTA"
        echo "6) CATEGORIAS = $CATEGORIAS"
        echo "7) ESTRATEGIA = $ESTRATEGIA"
        echo "8) LOG        = $LOG"
        echo "V) Volver al menú principal"
        echo "=========================================="
        read -r -p "Seleccione el parámetro a modificar (1-8 o V) >> " OPCIONC
        OPCIONC=${OPCIONC^^}
        #SUBOP_MAYUS=$(echo "$SUBOP" | tr '[:lower:]' '[:upper:]')

        case "$OPCIONC" in
            1)
                read -r -p "Nuevo valor para JUGADORES (2..4): " VAL
                if es_entero "$VAL" && [ "$VAL" -ge 2 ] && [ "$VAL" -le 4 ]; then
                    JUGADORES="$VAL"
                    guardar_config
                    echo "JUGADORES actualizado correctamente."
                else
                    echo "Error: JUGADORES debe ser un entero entre 2 y 4."
                fi
                sleep 1
                ;;
            2)
                read -r -p "Nuevo valor para RONDAS (entero > 0): " VAL
                if es_entero "$VAL" && [ "$VAL" -gt 0 ]; then
                    RONDAS="$VAL"
                    guardar_config
                    echo "RONDAS actualizado correctamente."
                else
                    echo "Error: RONDAS debe ser un entero positivo mayor que 0."
                fi
                sleep 1
                ;;
            3)
                read -r -p "Nuevo valor para PVIDA (50..100): " VAL
                if es_entero "$VAL" && [ "$VAL" -ge 50 ] && [ "$VAL" -le 100 ]; then
                    PVIDA="$VAL"
                    while [ "$PRESPUESTA" -ge "$PVIDA" ]; do
                        echo "Aviso: PRESPUESTA ($PRESPUESTA) debe ser menor que PVIDA ($PVIDA)."
                        read -r -p "Introduzca un nuevo PRESPUESTA ($((PFALLO + 1))..$((PVIDA - 1))): " NUEVO_PR
                        if es_entero "$NUEVO_PR" && [ "$NUEVO_PR" -gt "$PFALLO" ] && [ "$NUEVO_PR" -lt "$PVIDA" ]; then
                            PRESPUESTA="$NUEVO_PR"
                        else
                            echo "Error: PRESPUESTA debe ser mayor que PFALLO y menor que PVIDA."
                        fi
                    done
                    guardar_config
                    echo "PVIDA actualizado correctamente."
                else
                    echo "Error: PVIDA debe ser un entero entre 50 y 100."
                fi
                sleep 1
                ;;
            4)
                read -r -p "Nuevo valor para PFALLO (5..10): " VAL
                if es_entero "$VAL" && [ "$VAL" -ge 5 ] && [ "$VAL" -le 10 ]; then
                    PFALLO="$VAL"
                    while [ "$PRESPUESTA" -le "$PFALLO" ]; do
                        echo "Aviso: PRESPUESTA ($PRESPUESTA) debe ser mayor que PFALLO ($PFALLO)."
                        read -r -p "Introduzca un nuevo PRESPUESTA ($((PFALLO + 1))..$((PVIDA - 1))): " NUEVO_PR
                        if es_entero "$NUEVO_PR" && [ "$NUEVO_PR" -gt "$PFALLO" ] && [ "$NUEVO_PR" -lt "$PVIDA" ]; then
                            PRESPUESTA="$NUEVO_PR"
                        else
                            echo "Error: PRESPUESTA debe ser mayor que PFALLO y menor que PVIDA."
                        fi
                    done
                    guardar_config
                    echo "PFALLO actualizado correctamente."
                else
                    echo "Error: PFALLO debe ser un entero entre 5 y 10."
                fi
                sleep 1
                ;;
            5)
                MIN_PR=$((PFALLO + 1))
                MAX_PR=$((PVIDA - 1))
                read -r -p "Nuevo valor para PRESPUESTA ($MIN_PR..$MAX_PR): " VAL
                if es_entero "$VAL" && [ "$VAL" -gt "$PFALLO" ] && [ "$VAL" -lt "$PVIDA" ]; then
                    PRESPUESTA="$VAL"
                    guardar_config
                    echo "PRESPUESTA actualizado correctamente."
                else
                    echo "Error: PRESPUESTA debe ser mayor que PFALLO ($PFALLO) y menor que PVIDA ($PVIDA)."
                fi
                sleep 1
                ;;
            6)
                echo "Niveles: 1=Refranes | 2=+Películas | 3=+Música | 4=+Deportes"
                read -r -p "Nuevo valor para CATEGORIAS (1..4): " VAL
                if es_entero "$VAL" && [ "$VAL" -ge 1 ] && [ "$VAL" -le 4 ]; then
                    CATEGORIAS="$VAL"
                    guardar_config
                    echo "CATEGORIAS actualizado correctamente."
                else
                    echo "Error: CATEGORIAS debe ser un entero entre 1 y 4."
                fi
                sleep 1
                ;;
            7)
                echo "Modos IA: 0=Alfabética | 1=Aleatoria | 2=Propia del grupo"
                read -r -p "Nuevo valor para ESTRATEGIA (0..2): " VAL
                if es_entero "$VAL" && [ "$VAL" -ge 0 ] && [ "$VAL" -le 2 ]; then
                    ESTRATEGIA="$VAL"
                    guardar_config
                    echo "ESTRATEGIA actualizado correctamente."
                else
                    echo "Error: ESTRATEGIA debe ser un entero entre 0 y 2."
                fi
                sleep 1
                ;;
            8)
                read -r -p "Nueva ruta para LOG: " VAL
                if [ -n "$VAL" ] && [ ! -d "$VAL" ]; then
                    DIR_LOG=$(dirname "$VAL")
                    if [ -d "$DIR_LOG" ] || mkdir -p "$DIR_LOG" 2>/dev/null; then
                        LOG="$VAL"
                        guardar_config
                        echo "LOG actualizado correctamente."
                    else
                        echo "Error: No se puede crear o acceder al directorio $DIR_LOG."
                    fi
                else
                    echo "Error: Debe introducir una ruta de fichero válida."
                fi
                sleep 1
                ;;
            V)
                break
                ;;
            *)
                echo "Opción no válida."
                sleep 1
                ;;
        esac
    done
    pausa
}

#---------------------------------------

elegir_letra_ia() {
    usadas="$1"
    modo="$2"

    if [ "$modo" -eq 0 ]; then
        orden="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
        for l in $orden; do
            if ! echo "$usadas" | grep -q "$l"; then
                echo "$l"
                return
            fi
        done
    elif [ "$modo" -eq 1 ]; then
        if [ -z "$usadas" ]; then
            disp="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        else
            disp=$(echo "ABCDEFGHIJKLMNOPQRSTUVWXYZ" | tr -d "$usadas")
        fi
        lon=${#disp}
        idx=$(( RANDOM % lon ))
        echo "${disp:$idx:1}"
        return
    else
        orden="E A O S R N I D L C T U M P B G V Y Q H F Z J X W K"
        for l in $orden; do
            if ! echo "$usadas" | grep -q "$l"; then
                echo "$l"
                return
            fi
        done
    fi
}

registrar_log() {
    fecha_fin=$(date +%d%m%y)
    hora_fin=$(date +%H:%M:%S)
    duracion=$(( $(date +%s) - t_inicio ))

    if [ "$JUGADORES" -ge 3 ]; then
        rg3="${rgj[3]}"
    else
        rg3="-"
    fi

    if [ "$JUGADORES" -eq 4 ]; then
        rg4="${rgj[4]}"
    else
        rg4="-"
    fi

    if [ ! -f "$LOG" ] || [ ! -s "$LOG" ]; then
        echo "FECHA|HORA|TPO|JUGADORES|RONDAS|PVIDA|PFALLO|PRESPUESTA|CATEGORIAS|ESTRATEGIA|GANADOR|RONDAS_GANADAS_J1|RONDAS_GANADAS_J2|RONDAS_GANADAS_J3|RONDAS_GANADAS_J4|LETRAS_UTILIZADAS|FRASES_RESUELTAS" > "$LOG"
    fi

    echo "$fecha_fin|$hora_fin|$duracion|$JUGADORES|$RONDAS|$PVIDA|$PFALLO|$PRESPUESTA|$CATEGORIAS|$ESTRATEGIA|$ganador_final|${rgj[1]}|${rgj[2]}|$rg3|$rg4|$letras_totales|$frases_resueltas" >> "$LOG"
}

opcion_jugar() {
    JUGADORES=$(grep '^JUGADORES=' "./config.cfg" | cut -d'=' -f2)
    RONDAS=$(grep '^RONDAS=' "./config.cfg" | cut -d'=' -f2)
    PVIDA=$(grep '^PVIDA=' "./config.cfg" | cut -d'=' -f2)
    PFALLO=$(grep '^PFALLO=' "./config.cfg" | cut -d'=' -f2)
    PRESPUESTA=$(grep '^PRESPUESTA=' "./config.cfg" | cut -d'=' -f2)
    CATEGORIAS=$(grep '^CATEGORIAS=' "./config.cfg" | cut -d'=' -f2)
    ESTRATEGIA=$(grep '^ESTRATEGIA=' "./config.cfg" | cut -d'=' -f2)
    LOG=$(grep '^LOG=' "./config.cfg" | cut -d'=' -f2)

    dir_log=$(dirname "$LOG")
    if [ -d "$LOG" ] || { [ ! -d "$dir_log" ] && ! mkdir -p "$dir_log" 2>/dev/null; }; then
        echo "Error: No se puede garantizar el registro posterior en la ruta $LOG."
        pausa
        return
    fi
    if [ -f "$LOG" ] && [ ! -w "$LOG" ]; then
        echo "Error: No hay permisos de escritura en el archivo $LOG."
        pausa
        return
    fi

    case "$CATEGORIAS" in
        1) filtro_cat="^REFRAN:" ;;
        2) filtro_cat="^(REFRAN|PELICULA):" ;;
        3) filtro_cat="^(REFRAN|PELICULA|MUSICA):" ;;
        4) filtro_cat="^(REFRAN|PELICULA|MUSICA|DEPORTE):" ;;
    esac

    TMP_FRASES="/tmp/enigma_temp_frases_$$"
    grep -E "$filtro_cat" "./frases.dat" | sort -u > "$TMP_FRASES"
    total_frases_disp=$(wc -l < "$TMP_FRASES")

    if [ "$total_frases_disp" -lt "$RONDAS" ]; then
        echo "Error: No hay suficientes frases válidas ($total_frases_disp) para jugar $RONDAS rondas."
        rm -f "$TMP_FRASES"
        pausa
        return
    fi

    t_inicio=$(date +%s)
    letras_totales=0
    frases_resueltas=0
    for (( i=1; i<=4; i++ )); do
        rgj[$i]=0
        pvida_j[$i]=0
    done

    for (( ronda_actual=1; ronda_actual<=RONDAS; ronda_actual++ )); do
        for (( i=1; i<=JUGADORES; i++ )); do
            pvida_j[$i]=$PVIDA
        done

        num_disp=$(wc -l < "$TMP_FRASES")
        azar=$(( (RANDOM % num_disp) + 1 ))
        linea_elegida=$(head -n "$azar" "$TMP_FRASES" | tail -n 1)
        grep -F -x -v "$linea_elegida" "$TMP_FRASES" > "${TMP_FRASES}_aux"
        mv "${TMP_FRASES}_aux" "$TMP_FRASES"

        cat_actual=$(echo "$linea_elegida" | cut -d':' -f1)
        frase_actual=$(echo "$linea_elegida" | cut -d':' -f2)

        letras_ronda=""
        historico_ronda=""
        turno=1
        ronda_activa=1

        while [ "$ronda_activa" -eq 1 ]; do
            vivos=0
            for (( i=1; i<=JUGADORES; i++ )); do
                if [ "${pvida_j[$i]}" -gt 0 ]; then
                    vivos=$((vivos + 1))
                fi
            done

            if [ "$vivos" -eq 0 ]; then
                clear
                echo "=========================================="
                echo "         ¡RONDA $ronda_actual DESIERTA!          "
                echo "=========================================="
                echo "Todos los jugadores han sido eliminados en esta ronda."
                echo "La frase oculta era: $frase_actual"
                sleep 3
                ronda_activa=0
                continue
            fi

            if [ "${pvida_j[$turno]}" -le 0 ]; then
                turno=$(( (turno % JUGADORES) + 1 ))
                continue
            fi

            frase_oculta=$(echo "$frase_actual" | sed "s/[^ $letras_ronda]/_/g")

            clear
            echo "========================================================"
            echo " RONDA: $ronda_actual / $RONDAS  |  CATEGORÍA: $cat_actual"
            echo "========================================================"
            echo ""
            echo "  FRASE:  $frase_oculta"
            echo ""
            echo "--------------------------------------------------------"
            echo " PUNTOS DE VIDA:"
            for (( i=1; i<=JUGADORES; i++ )); do
                if [ "$i" -eq 1 ]; then
                    tipo="Humano"
                else
                    tipo="IA"
                fi
                echo "   Jugador $i ($tipo): ${pvida_j[$i]} PVIDA (Rondas ganadas: ${rgj[$i]})"
            done
            echo "--------------------------------------------------------"
            echo " Letras utilizadas: ${historico_ronda:-Ninguna}"
            echo " >>> TURNO ACTUAL: JUGADOR $turno <<<"
            echo "========================================================"

            if [ "$turno" -eq 1 ]; then
                echo "Acciones del turno:"
                echo "1) Solicitar letra"
                echo "2) Intentar resolver la frase"
                read -r -p "Seleccione una acción (1 o 2) >> " accion

                if [ "$accion" = "1" ]; then
                    while true; do
                        read -r -p "Introduzca una letra (A-Z): " letra_in
                        letra=$(echo "$letra_in" | tr '[:lower:]' '[:upper:]')

                        if [ -z "$letra" ] || [ "${#letra}" -ne 1 ] || echo "$letra" | grep -E -q '[^A-Z]'; then
                            echo "Entrada inválida. Debe introducir una única letra de la A a la Z."
                        elif [ -n "$letras_ronda" ] && echo "$letras_ronda" | grep -q "$letra"; then
                            echo "Aviso: La letra '$letra' ya ha sido utilizada en esta ronda. Pruebe con otra."
                        else
                            break
                        fi
                    done
                elif [ "$accion" = "2" ]; then
                    read -r -p "Introduzca la frase completa: " resp_in
                    resp_mayus=$(echo "$resp_in" | tr '[:lower:]' '[:upper:]')

                    if [ "$resp_mayus" = "$frase_actual" ]; then
                        echo "¡CORRECTO! El Jugador 1 resuelve la frase y gana la ronda."
                        rgj[1]=$(( rgj[1] + 1 ))
                        frases_resueltas=$(( frases_resueltas + 1 ))
                        ronda_activa=0
                        sleep 2
                    else
                        echo "¡INCORRECTO! Pierdes $PRESPUESTA PVIDA."
                        pvida_j[1]=$(( pvida_j[1] - PRESPUESTA ))
                        if [ "${pvida_j[1]}" -le 0 ]; then
                            pvida_j[1]=0
                            echo "El Jugador 1 ha quedado con 0 PVIDA y es eliminado de esta ronda."
                        fi
                        turno=$(( (turno % JUGADORES) + 1 ))
                        sleep 2
                    fi
                    continue
                else
                    echo "Opción no válida. Debe elegir 1 o 2."
                    sleep 1
                    continue
                fi
            else
                sleep 1
                letra=$(elegir_letra_ia "$letras_ronda" "$ESTRATEGIA")
                echo "El Jugador $turno (IA) solicita la letra: $letra"
                sleep 1
            fi

            letras_ronda="${letras_ronda}${letra}"
            historico_ronda="${historico_ronda}${letra} "
            letras_totales=$(( letras_totales + 1 ))

            if echo "$frase_actual" | grep -q "$letra"; then
                echo "¡Acierto! La letra '$letra' está en la frase."
                nueva_oculta=$(echo "$frase_actual" | sed "s/[^ $letras_ronda]/_/g")
                if [ "$nueva_oculta" = "$frase_actual" ]; then
                    echo "¡Se han revelado todas las letras! El Jugador $turno gana la ronda."
                    rgj[$turno]=$(( rgj[$turno] + 1 ))
                    frases_resueltas=$(( frases_resueltas + 1 ))
                    ronda_activa=0
                else
                    echo "El Jugador $turno mantiene el turno."
                fi
                sleep 2
            else
                echo "¡Fallo! La letra '$letra' no está. Pierde $PFALLO PVIDA."
                pvida_j[$turno]=$(( pvida_j[$turno] - PFALLO ))
                if [ "${pvida_j[$turno]}" -le 0 ]; then
                    pvida_j[$turno]=0
                    echo "El Jugador $turno ha quedado con 0 PVIDA y es eliminado de esta ronda."
                fi
                turno=$(( (turno % JUGADORES) + 1 ))
                sleep 2
            fi
        done
    done

    rm -f "$TMP_FRASES" "${TMP_FRASES}_aux" 2>/dev/null

    if [ "$frases_resueltas" -eq 0 ]; then
        ganador_final=0
    else
        ganador_final=1
        max_rondas=${rgj[1]}
        max_vida=${pvida_j[1]}

        for (( i=2; i<=JUGADORES; i++ )); do
            if [ "${rgj[$i]}" -gt "$max_rondas" ]; then
                ganador_final=$i
                max_rondas=${rgj[$i]}
                max_vida=${pvida_j[$i]}
            elif [ "${rgj[$i]}" -eq "$max_rondas" ]; then
                if [ "${pvida_j[$i]}" -gt "$max_vida" ]; then
                    ganador_final=$i
                    max_vida=${pvida_j[$i]}
                fi
            fi
        done
    fi

    registrar_log

    clear
    echo "========================================================"
    echo "                    FIN DE LA PARTIDA                   "
    echo "========================================================"
    for (( i=1; i<=JUGADORES; i++ )); do
        echo " Jugador $i -> Rondas ganadas: ${rgj[$i]} | PVIDA final: ${pvida_j[$i]}"
    done
    echo "--------------------------------------------------------"
    if [ "$ganador_final" -eq 0 ]; then
        echo " RESULTADO: Partida sin ganador (todas las rondas desiertas)."
    else
        echo " ¡GANADOR DE LA PARTIDA: JUGADOR $ganador_final!"
    fi
    echo " Datos registrados correctamente en: $LOG"
    echo "========================================================"

    pausa
}


opcion_frases() {
    while true; do
        clear
        echo "=========================================="
        echo "           GESTIÓN DE FRASES              "
        echo "=========================================="
        echo "1) Listar frases existentes"
        echo "2) Añadir una nueva frase"
        echo "V) Volver al menú principal"
        echo "=========================================="
        read -r -p "Seleccione una opción >> " SUBOP

        SUBOP=${SUBOP^^}

        case "$SUBOP" in
            1)
                clear       # listar frases
                echo "--- LISTADO DE FRASES EN $FRASES_FILE ---"
                if [ -f "$FRASES_FILE" ]; then
                    cat -n "$FRASES_FILE"           # imprime el contenido del fichero
                else
                    echo "El fichero no existe."
                fi
                echo ""
                ;;
            2)
                clear           # añadir frase
                echo "--- AÑADIR NUEVA FRASE ---"
                echo "Categorías válidas: REFRAN, PELICULA, MUSICA, DEPORTE"
                read -r -p "Introduzca la categoría: " CAT_INPUT
                CAT_MAYUS=${CAT_INPUT^^}
                #comprobacion categoria valida
                if [ "$CAT_MAYUS" != "REFRAN" ] && [ "$CAT_MAYUS" != "PELICULA" ] && [ "$CAT_MAYUS" != "MUSICA" ] && [ "$CAT_MAYUS" != "DEPORTE" ]; then
                    echo "Error: Categoría no válida."
                    sleep 2
                    continue
                fi

                read -r -p "Introduzca la frase (sin tildes): " FRASE_INPUT
                # Convertir a mayúsculas automáticamente
                FRASE_MAYUS=${FRASE_INPUT^^}

                # Validar que la frase no esté vacía y solo contenga letras mayúsculas y espacios
                if [ -z "$FRASE_MAYUS" ] || echo "$FRASE_MAYUS" | grep -E -q '[^A-Z ]'; then
                    echo "Error: La frase contiene caracteres no permitidos (tildes, símbolos o números) o está vacía."
                    sleep 2
                    continue
                fi

                # Guardar de forma persistente en frases.dat
                echo "$CAT_MAYUS:$FRASE_MAYUS" >> "$FRASES_FILE"
                echo "¡Frase añadida con éxito a $FRASES_FILE!"
                sleep 2
                ;;
            V)
                break
                ;;
            *)
                echo "Opción no válida."
                sleep 1
                ;;
        esac
        pausa
    done
}




opcion_estadisticas() {
    # Lógica para procesar el archivo de log y mostrar métricas
	LOG=$(grep '^LOG=' "$CONFIG_FILE" | cut -d'=' -f2) 
	#obtiene la ruta dellog desde config_file y lo guarda en la variable LOG

	if [ -z "$LOG" ]; then
		echo "Error: no se ha definido la ruta del LOG en config.cfg"
		pausa
		return
	fi			#comprueba que la variable LOG esta vacioa (-z)

	if [ ! -f "$LOG" ] || [ ! -r "$LOG" ] || [ ! -s "$LOG" ]; then
		echo "Error: El fichero de registro ($LOG) no existe, está vacío o no se puede leer."
		pausa
		return		#si el archivo no existe (-f), o no se puede leer(-r) o esta 				#vacio(-s)  ==> error
	fi

	PARTIDAS_JUGADAS=0		#inicializacion de contadores/variables
	SUMA_TPO=0
	MIN_TPO=-1
	MAX_TPO=-1
	FECHA_MIN=""
	HORA_MIN=""
	FECHA_MAX=""
	HORA_MAX=""
	SUMA_RONDAS=0
	SUMA_LETRAS=0
	SUMA_FRASES=0

	for (( I=1; I<=4; I++ )); do	#inicializa arrays para participaciones y victorias
		PART_J[$I]=0			# de cada jugador
		GANADAS_J[$I]=0
	done

	for (( I=0; I<=2; I++ )); do
		CONT_EST[$I]=0
	done

	for (( I=1; I<=4; I++ )); do
		CONT_CAT[$I]=0
	done

	while IFS= read -r REGISTRO || [ -n "$REGISTRO" ]; do
		# LEE EL ARCHIVO LOG LINEA A LINEA, separándolas por |

		if [ -z "$REGISTRO" ]; then
			continue
		fi

		if [ "$REGISTRO" = "FECHA|HORA|TPO|JUGADORES|RONDAS|PVIDA|PFALLO|PRESPUESTA|CATEGORIAS|ESTRATEGIA|GANADOR|RONDAS_GANADAS_J1|RONDAS_GANADAS_J2|RONDAS_GANADAS_J3|RONDAS_GANADAS_J4|LETRAS_UTILIZADAS|FRASES_RESUELTAS" ]; then
			continue	# para que no lea la cabecera
		fi

		if [ "$(printf '%s' "$REGISTRO" | tr -cd '|' | wc -c)" -ne 16 ]; then
			echo "Aviso: Registro incompleto o con campos adicionales. Se ignorará."
			continue
		fi

		IFS='|' read -r F_FECHA F_HORA F_TPO F_JUG F_RONDAS F_PVIDA F_PFALLO F_PRESP F_CAT F_EST F_GAN F_RG1 F_RG2 F_RG3 F_RG4 F_LETRAS F_FRASES <<< "$REGISTRO"

		if [[ ! "$F_TPO" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_JUG" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_RONDAS" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_PVIDA" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_PFALLO" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_PRESP" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_LETRAS" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_FRASES" =~ ^[0-9]+$ ]]; then
			echo "Aviso: Se ha encontrado un registro con datos numéricos incorrectos. Se ignorará."
			continue
		fi
		# validamos que sean números validos

		if [ "$F_JUG" -lt 2 ] || [ "$F_JUG" -gt 4 ] || \
			[[ ! "$F_CAT" =~ ^[1-4]$ ]] || \
			[[ ! "$F_EST" =~ ^[0-2]$ ]] || \
			[[ ! "$F_GAN" =~ ^[0-4]$ ]]; then
			echo "Aviso: Se ha encontrado un registro con valores fuera de rango. Se ignorará."
			continue
		fi

		if [[ ! "$F_RG1" =~ ^[0-9]+$ ]] || \
			[[ ! "$F_RG2" =~ ^[0-9]+$ ]] || \
			{ [[ "$F_RG3" != "-" ]] && [[ ! "$F_RG3" =~ ^[0-9]+$ ]]; } || \
			{ [[ "$F_RG4" != "-" ]] && [[ ! "$F_RG4" =~ ^[0-9]+$ ]]; }; then
			echo "Aviso: Se ha encontrado un registro con datos de participación incorrectos. Se ignorará."
			continue
		fi

		if { [ "$F_JUG" -eq 2 ] && { [ "$F_RG3" != "-" ] || [ "$F_RG4" != "-" ]; }; } || \
			{ [ "$F_JUG" -eq 3 ] && [ "$F_RG3" = "-" ]; } || \
			{ [ "$F_JUG" -eq 4 ] && { [ "$F_RG3" = "-" ] || [ "$F_RG4" = "-" ]; }; }; then
			echo "Aviso: El número de jugadores no coincide con sus participaciones. Se ignorará."
			continue
		fi

		if [ "$F_GAN" -ge 1 ] && [ "$F_GAN" -le 4 ]; then
			if [ "$F_GAN" -eq 3 ] && [ "$F_RG3" = "-" ] || \
				[ "$F_GAN" -eq 4 ] && [ "$F_RG4" = "-" ]; then
				echo "Aviso: El ganador no coincide con los jugadores participantes. Se ignorará."
				continue
			fi
		fi

		PARTIDAS_JUGADAS=$(( PARTIDAS_JUGADAS + 1 ))
		SUMA_TPO=$(( SUMA_TPO + F_TPO ))
		SUMA_RONDAS=$(( SUMA_RONDAS + F_RONDAS ))
		SUMA_LETRAS=$(( SUMA_LETRAS + F_LETRAS ))
		SUMA_FRASES=$(( SUMA_FRASES + F_FRASES ))
		# actualiza las stats con las de la partida actual

		if [ "$MIN_TPO" -eq -1 ] || [ "$F_TPO" -lt "$MIN_TPO" ]; then
			MIN_TPO=$F_TPO
			FECHA_MIN=$F_FECHA
			HORA_MIN=$F_HORA
		fi	# encontrar la partida mas corta

		if [ "$MAX_TPO" -eq -1 ] || [ "$F_TPO" -gt "$MAX_TPO" ]; then
			MAX_TPO=$F_TPO
			FECHA_MAX=$F_FECHA
			HORA_MAX=$F_HORA
		fi	# encontrar la partida mas larga

		PART_J[1]=$(( PART_J[1] + 1 ))
		PART_J[2]=$(( PART_J[2] + 1 ))

		if [ "$F_RG3" != "-" ]; then
			PART_J[3]=$(( PART_J[3] + 1 ))
		fi

		if [ "$F_RG4" != "-" ]; then
			PART_J[4]=$(( PART_J[4] + 1 ))
		fi	#cuantas partidas ha jugado cada jugador y comprobar si han jugado j3 y j4

		if [[ "$F_GAN" =~ ^[1-4]$ ]]; then
			GANADAS_J[$F_GAN]=$(( GANADAS_J[$F_GAN] + 1 ))
		fi	#cuantas partidas ha ganado cada jugador 

		CONT_EST[$F_EST]=$(( CONT_EST[$F_EST] + 1 )) #actualiza +1 con la estrategia usada
		CONT_CAT[$F_CAT]=$(( CONT_CAT[$F_CAT] + 1 )) #actualiza +1 con la categoría usada

	done < "$LOG"

	if [ "$PARTIDAS_JUGADAS" -eq 0 ]; then
		echo "No hay partidas registradas todavía en el fichero $LOG."
		pausa
		return
	fi	# si hay partidas registradas en log

	TIEMPO_MEDIO=$(( SUMA_TPO / PARTIDAS_JUGADAS ))
	PROMEDIO_RONDAS=$(( SUMA_RONDAS / PARTIDAS_JUGADAS ))
	PROMEDIO_LETRAS=$(( SUMA_LETRAS / PARTIDAS_JUGADAS ))	#calcular promedios

	if [ "$SUMA_RONDAS" -gt 0 ]; then
		TASA_RESOLUCION=$(( (SUMA_FRASES * 100) / SUMA_RONDAS ))
	else
		TASA_RESOLUCION=0
	fi	# calculo tasa resolucion

	MAX_USO_EST=-1
	for (( I=0; I<=2; I++ )); do
		if [ "${CONT_EST[$I]}" -gt "$MAX_USO_EST" ]; then
			MAX_USO_EST=${CONT_EST[$I]}
		fi
	done

	EST_EMPATADAS=""	# si hay estraegas que se han usado igual de veces
	for (( I=0; I<=2; I++ )); do
		if [ "${CONT_EST[$I]}" -eq "$MAX_USO_EST" ]; then
			EST_EMPATADAS="${EST_EMPATADAS}Estrategia-$I (${CONT_EST[$I]} partidas) "
		fi
	done

	MAX_USO_CAT=-1
	for (( I=1; I<=4; I++ )); do
		if [ "${CONT_CAT[$I]}" -gt "$MAX_USO_CAT" ]; then
			MAX_USO_CAT=${CONT_CAT[$I]}
		fi
	done

	CAT_EMPATADAS=""	# si hay categorías que se hn usado igual de veces
	for (( I=1; I<=4; I++ )); do
		if [ "${CONT_CAT[$I]}" -eq "$MAX_USO_CAT" ]; then
			CAT_EMPATADAS="${CAT_EMPATADAS}Nivel-$I (${CONT_CAT[$I]} partidas) "
		fi
	done

	clear
	echo "========================================================"
	echo "                ESTADÍSTICAS DEL JUEGO                  "
	echo "========================================================"
	echo "- Partidas jugadas: $PARTIDAS_JUGADAS"
	echo "- Tiempo medio de partida: $TIEMPO_MEDIO segundos"
	echo "- Partida más corta: Fecha $FECHA_MIN a las $HORA_MIN ($MIN_TPO segundos)"
	echo "- Partida más larga: Fecha $FECHA_MAX a las $HORA_MAX ($MAX_TPO segundos)"
	echo "--------------------------------------------------------"
	echo "RENDIMIENTO POR JUGADOR:"
	for (( I=1; I<=4; I++ )); do
		if [ "${PART_J[$I]}" -gt 0 ]; then
			PORC_VIC=$(( (GANADAS_J[$I] * 100) / PART_J[$I] ))
			echo "  * Jugador $I: ${GANADAS_J[$I]} victorias en ${PART_J[$I]} partidas jugadas ($PORC_VIC%)"
		else
			echo "  * Jugador $I: Sin participaciones registradas (0%)"
		fi
	done
	echo "--------------------------------------------------------"
	echo "- Promedio de rondas por partida: $PROMEDIO_RONDAS"
	echo "- Estrategia de IA más utilizada: $EST_EMPATADAS"
	echo "- Nivel de categoría más utilizado: $CAT_EMPATADAS"
	echo "- Promedio de letras utilizadas por partida: $PROMEDIO_LETRAS"
	echo "- Estadística libre (Eficacia de resolución): $TASA_RESOLUCION% ($SUMA_FRASES frases resueltas de $SUMA_RONDAS rondas)"
	echo "========================================================"
    pausa
}

opcion_salir() {
    limpiar_temporales
    echo "Saliendo del juego..."
    exit 0
}


#------------------------------------------------------------------
#                               M    E    N    U
#------------------------------------------------------------------


# Ejecución principal
if ! validar_ficheros_iniciales; then
    exit 1
fi

while true; do
    clear
    echo "===================================="
    echo "         JUEGO \"EL ENIGMA\"          "
    echo "===================================="
    echo "C) CONFIGURACIÓN"
    echo "J) JUGAR"
    echo "F) FRASES"
    echo "E) ESTADÍSTICAS"
    echo "S) SALIR"
    echo "===================================="
    read -r -p "Introduzca una opción >> " OPCION
    OPCION=${OPCION^^}
    # Conversión a mayúscula de la opción elegida
    #OPCION=$(echo "$OPCION" | tr '[:lower:]' '[:upper:]')
    case "$OPCION" in
        C) opcion_configuracion ;;
        J) opcion_jugar ;;
        F) opcion_frases ;;
        E) opcion_estadisticas ;;
        S) opcion_salir ;;
        *)
            echo "Opción no válida."
            pausa
            ;;
    esac

done