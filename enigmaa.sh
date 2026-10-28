#!/bin/bash

CONFIG_FILE="config.cfg"
FRASES_FILE="frases.dat"         #aqui pasamos los archivos a constante para mejor manejo

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
