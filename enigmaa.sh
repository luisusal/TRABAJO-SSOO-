#!/bin/bash

FICHERO_CONFIG="config.cfg"
FICHERO_FRASES="frases.dat"         #aqui pasamos los archivos a constante para mejor manejo

#------------------------------------------
TMP_FILE="/tmp/enigma_temp$$" #esto nose que es


limpiar_temporales() {
    rm -f /tmp/enigma_temp_* 2>/dev/null
}

# trampa para capturar salidas inesperadas
trap 'limpiar_temporales; exit 1' INT TERM
#-----------------------------------------


#------------------------------------------------------------------
#                       MOSTRAR INFPORMACION
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
    if [ ! -f "$FICHERO_CONFIG" ] || [ ! -f "$FICHERO_FRASES" ]; then
        echo "Error: Los archivos 'config.cfg' o 'frases.dat' no existen o estan incompletos."
}


#------------------------------------------------------------------------
#                             M  E  N  U
#--------------------------------------------------------------------


# Ejecución principal
validar_prerrequisitos

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
    read -p "Introduzca una opción >> " opcion

    # Conversión a mayúscula de la opción elegida
    opcion=$(echo "$opcion" | tr '[:lower:]' '[:upper:]')

    case "$opcion" in
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

# FUNCIONES

pausa() {
    echo ""
    read -n 1 -s -r -p "Pulse una tecla para continuar..."
    echo ""
}

# Funciones de las opciones del menú
opcion_configuracion() {
    echo "=== CONFIGURACIÓN ==="
    # Lógica para leer y modificar parámetros de config.cfg de forma persistente
    pausa
}

opcion_jugar() {
    echo "=== INICIANDO PARTIDA ==="
    # Lógica de juego: comprobar frases suficientes, validar log, desarrollo por rondas
    pausa
}

opcion_frases() {
    echo "=== GESTIÓN DE FRASES ==="
    # Lógica para ver y añadir frases en frases.dat
    pausa
}

# FRASES---------------------------------------------------
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
        read -r -p "Seleccione una opción >> " subop

        subop_mayus=$(echo "$subop" | tr '[:lower:]' '[:upper:]')

        case "$subop_mayus" in
            1)
                clear
                echo "--- LISTADO DE FRASES EN $FRASES_FILE ---"
                if [ -f "$FRASES_FILE" ]; then
                    cat -n "$FRASES_FILE"
                else
                    echo "El fichero no existe."
                fi
                echo ""
                read -n 1 -s -r -p "Pulse una tecla para continuar."
                ;;
            2)
                clear
                echo "--- AÑADIR NUEVA FRASE ---"
                echo "Categorías válidas: REFRAN, PELICULA, MUSICA, DEPORTE"
                read -r -p "Introduzca la categoría: " cat_input
                cat_mayus=$(echo "$cat_input" | tr '[:lower:]' '[:upper:]')

                if [ "$cat_mayus" != "REFRAN" ] && [ "$cat_mayus" != "PELICULA" ] && [ "$cat_mayus" != "MUSICA" ] && [ "$cat_mayus" != "DEPORTE" ]; then
                    echo "Error: Categoría no válida."
                    sleep 2
                    continue
                fi

                read -r -p "Introduzca la frase (en mayúsculas, sin tildes): " frase_input
                # Convertir a mayúsculas automáticamente
                frase_mayus=$(echo "$frase_input" | tr '[:lower:]' '[:upper:]')

                # Validar que la frase no esté vacía y solo contenga letras mayúsculas y espacios
                if [ -z "$frase_mayus" ] || echo "$frase_mayus" | grep -E -q '[^A-Z ]'; then
                    echo "Error: La frase contiene caracteres no permitidos (tildes, símbolos o números) o está vacía."
                    sleep 2
                    continue
                fi

                # Guardar de forma persistente en frases.dat
                echo "$cat_mayus:$frase_mayus" >> "$FRASES_FILE"
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
    done
}
# SESARF------------------------------------



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