#!/bin/bash
# esta version ya tiene config hecha por luis.
# compila
#al mostrar el menu pulso una tecla y
#sale un mensaje 0.1 s que dice algo de tecla incorrecta
# (no da tiempo a leerlo) y vuelve a pedir otra tecla
#30/10, 17:49
CONFIG_FILE="config.cfg"
FRASES_FILE="frases.dat"         #aqui pasamos los archivos a constante
#para mejor manejo

#------------------------------------------
TMP_FILE="/tmp/enigma_temp$$" #esto nose que es


limpiar_temporales() {
    rm -f /tmp/enigma_temp_* 2>/dev/null
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
    cat <<EOF > "./config.cfg"
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
    JUGADORES=$(grep '^JUGADORES=' "./config.cfg" | cut -d'=' -f2)
    RONDAS=$(grep '^RONDAS=' "./config.cfg" | cut -d'=' -f2)
    PVIDA=$(grep '^PVIDA=' "./config.cfg" | cut -d'=' -f2)
    PFALLO=$(grep '^PFALLO=' "./config.cfg" | cut -d'=' -f2)
    PRESPUESTA=$(grep '^PRESPUESTA=' "./config.cfg" | cut -d'=' -f2)
    CATEGORIAS=$(grep '^CATEGORIAS=' "./config.cfg" | cut -d'=' -f2)
    ESTRATEGIA=$(grep '^ESTRATEGIA=' "./config.cfg" | cut -d'=' -f2)
    LOG=$(grep '^LOG=' "./config.cfg" | cut -d'=' -f2)

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
        read -r -p "Seleccione el parámetro a modificar (1-8 o V) >> " SUBOP

        SUBOP_MAYUS=$(echo "$SUBOP" | tr '[:lower:]' '[:upper:]')

        case "$SUBOP_MAYUS" in
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

opcion_jugar() {
    echo "=== INICIANDO PARTIDA ==="
    # Lógica de juego: comprobar frases suficientes, validar log, desarrollo por rondas
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

        SUBOP_MAYUS=$(echo "$SUBOP" | tr '[:lower:]' '[:upper:]')

        case "$SUBOP_MAYUS" in
            1)
                clear       # listar frases
                echo "--- LISTADO DE FRASES EN $FRASES_FILE ---"
                if [ -f "$FRASES_FILE" ]; then
                    cat -n "$FRASES_FILE"           # imprime el contenido del fichero
                else
                    echo "El fichero no existe."
                fi
                echo ""
                read -n 1 -s -r -p "Pulse una tecla para continuar."
                ;;
            2)
                clear           # añadir frase
                echo "--- AÑADIR NUEVA FRASE ---"
                echo "Categorías válidas: REFRAN, PELICULA, MUSICA, DEPORTE"
                read -r -p "Introduzca la categoría: " CAT_INPUT
                CAT_MAYUS=$(echo "$CAT_INPUT" | tr '[:lower:]' '[:upper:]')
                #comprobacion categoria valida
                if [ "$CAT_MAYUS" != "REFRAN" ] && [ "$CAT_MAYUS" != "PELICULA" ] && [ "$CAT_MAYUS" != "MUSICA" ] && [ "$CAT_MAYUS" != "DEPORTE" ]; then
                    echo "Error: Categoría no válida."
                    sleep 2
                    continue
                fi

                read -r -p "Introduzca la frase (sin tildes): " FRASE_INPUT
                # Convertir a mayúsculas automáticamente
                FRASE_MAYUS=$(echo "$FRASE_INPUT" | tr '[:lower:]' '[:upper:]')

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
        pause
    done
}




opcion_estadisticas() {
    echo "=== ESTADÍSTICAS DEL JUEGO ==="
    # Lógica para procesar el archivo de log y mostrar métricas
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
validar_ficheros_iniciales

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
    read -p "Introduzca una opción >> " OPCION

    # Conversión a mayúscula de la opción elegida
    OPCION=$(echo "$OPCION" | tr '[:lower:]' '[:upper:]')

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