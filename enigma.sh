#!/bin/bash

CONFIG_FILE="./config.cfg"
FRASES_FILE="./frases.dat"

limpiar_temporales() {
    rm -f /tmp/enigma_tmp_*_* 2>/dev/null
}

trap 'limpiar_temporales; echo ""; exit 1' INT TERM

mostrar_uso() {
    echo "Error: Sintaxis de invocación incorrecta."
    echo "Sintaxis correcta: $0 [-g]"
}

mostrar_info_grupo() {
    echo "========================================================"
    echo "            INFORMACIÓN DEL GRUPO DESARROLLADOR         "
    echo "========================================================"
    echo "Integrantes del grupo:"
    echo "  - Alumno 1: [Nombre y Apellidos]"
    echo "  - Alumno 2: [Nombre y Apellidos]"
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

es_entero() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

cargar_y_validar_config() {
    if [ ! -f "$CONFIG_FILE" ] || [ ! -r "$CONFIG_FILE" ] || [ ! -w "$CONFIG_FILE" ]; then
        echo "Error crítico: El fichero $CONFIG_FILE no existe o no tiene permisos de lectura/escritura."
        exit 1
    fi

    lineas_invalidas=$(grep -E -v '^(JUGADORES|RONDAS|PVIDA|PFALLO|PRESPUESTA|CATEGORIAS|ESTRATEGIA|LOG)=[^=]+$' "$CONFIG_FILE" | wc -l)
    total_lineas=$(wc -l < "$CONFIG_FILE")

    if [ "$lineas_invalidas" -ne 0 ] || [ "$total_lineas" -ne 8 ]; then
        echo "Error crítico: El formato del fichero $CONFIG_FILE es inválido."
        exit 1
    fi

    JUGADORES=$(grep '^JUGADORES=' "$CONFIG_FILE" | cut -d'=' -f2)
    RONDAS=$(grep '^RONDAS=' "$CONFIG_FILE" | cut -d'=' -f2)
    PVIDA=$(grep '^PVIDA=' "$CONFIG_FILE" | cut -d'=' -f2)
    PFALLO=$(grep '^PFALLO=' "$CONFIG_FILE" | cut -d'=' -f2)
    PRESPUESTA=$(grep '^PRESPUESTA=' "$CONFIG_FILE" | cut -d'=' -f2)
    CATEGORIAS=$(grep '^CATEGORIAS=' "$CONFIG_FILE" | cut -d'=' -f2)
    ESTRATEGIA=$(grep '^ESTRATEGIA=' "$CONFIG_FILE" | cut -d'=' -f2)
    LOG=$(grep '^LOG=' "$CONFIG_FILE" | cut -d'=' -f2)

    if ! es_entero "$JUGADORES" || [ "$JUGADORES" -lt 2 ] || [ "$JUGADORES" -gt 4 ]; then
        echo "Error en $CONFIG_FILE: JUGADORES debe ser un entero entre 2 y 4."
        exit 1
    fi

    if ! es_entero "$RONDAS" || [ "$RONDAS" -le 0 ]; then
        echo "Error en $CONFIG_FILE: RONDAS debe ser un entero positivo (> 0)."
        exit 1
    fi

    if ! es_entero "$PVIDA" || [ "$PVIDA" -lt 50 ] || [ "$PVIDA" -gt 100 ]; then
        echo "Error en $CONFIG_FILE: PVIDA debe ser un entero entre 50 y 100."
        exit 1
    fi

    if ! es_entero "$PFALLO" || [ "$PFALLO" -lt 5 ] || [ "$PFALLO" -gt 10 ]; then
        echo "Error en $CONFIG_FILE: PFALLO debe ser un entero entre 5 y 10."
        exit 1
    fi

    if ! es_entero "$PRESPUESTA" || [ "$PRESPUESTA" -le "$PFALLO" ] || [ "$PRESPUESTA" -ge "$PVIDA" ]; then
        echo "Error en $CONFIG_FILE: PRESPUESTA debe ser un entero tal que PFALLO < PRESPUESTA < PVIDA."
        exit 1
    fi

    if ! es_entero "$CATEGORIAS" || [ "$CATEGORIAS" -lt 1 ] || [ "$CATEGORIAS" -gt 4 ]; then
        echo "Error en $CONFIG_FILE: CATEGORIAS debe ser un entero entre 1 y 4."
        exit 1
    fi

    if ! es_entero "$ESTRATEGIA" || [ "$ESTRATEGIA" -lt 0 ] || [ "$ESTRATEGIA" -gt 2 ]; then
        echo "Error en $CONFIG_FILE: ESTRATEGIA debe ser un entero entre 0 y 2."
        exit 1
    fi

    if [ -z "$LOG" ] || [ -d "$LOG" ]; then
        echo "Error en $CONFIG_FILE: LOG debe contener una ruta de fichero válida."
        exit 1
    fi
}

validar_frases_inicial() {
    if [ ! -f "$FRASES_FILE" ] || [ ! -r "$FRASES_FILE" ] || [ ! -s "$FRASES_FILE" ]; then
        echo "Error crítico: El fichero $FRASES_FILE no existe, no es legible o está vacío."
        exit 1
    fi

    lineas_erroneas=$(grep -E -v '^(REFRAN|PELICULA|MUSICA|DEPORTE):[A-Z ]+$' "$FRASES_FILE" | wc -l)
    frases_vacias=$(grep -E '^(REFRAN|PELICULA|MUSICA|DEPORTE):[ ]*$' "$FRASES_FILE" | wc -l)

    if [ "$lineas_erroneas" -ne 0 ] || [ "$frases_vacias" -ne 0 ]; then
        echo "Error crítico: El fichero $FRASES_FILE contiene líneas con formato o caracteres inválidos."
        exit 1
    fi
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

pedir_jugadores() {
    while true; do
        read -r -p "Introduzca JUGADORES (2..4) [actual: $JUGADORES]: " val
        [ -z "$val" ] && break
        if es_entero "$val" && [ "$val" -ge 2 ] && [ "$val" -le 4 ]; then
            JUGADORES="$val"
            break
        fi
        echo "Valor inválido. Debe ser un entero entre 2 y 4."
    done
}

pedir_rondas() {
    while true; do
        read -r -p "Introduzca RONDAS (entero > 0) [actual: $RONDAS]: " val
        [ -z "$val" ] && break
        if es_entero "$val" && [ "$val" -gt 0 ]; then
            RONDAS="$val"
            break
        fi
        echo "Valor inválido. Debe ser un entero positivo mayor que 0."
    done
}

pedir_pvida() {
    while true; do
        read -r -p "Introduzca PVIDA (50..100) [actual: $PVIDA]: " val
        [ -z "$val" ] && break
        if es_entero "$val" && [ "$val" -ge 50 ] && [ "$val" -le 100 ]; then
            PVIDA="$val"
            if [ "$PRESPUESTA" -ge "$PVIDA" ]; then
                echo "Aviso: PRESPUESTA ($PRESPUESTA) debe ser menor que el nuevo PVIDA ($PVIDA)."
                pedir_prespuesta_obligatorio
            fi
            break
        fi
        echo "Valor inválido. Debe ser un entero entre 50 y 100."
    done
}

pedir_pfallo() {
    while true; do
        read -r -p "Introduzca PFALLO (5..10) [actual: $PFALLO]: " val
        [ -z "$val" ] && break
        if es_entero "$val" && [ "$val" -ge 5 ] && [ "$val" -le 10 ]; then
            PFALLO="$val"
            if [ "$PRESPUESTA" -le "$PFALLO" ]; then
                echo "Aviso: PRESPUESTA ($PRESPUESTA) debe ser mayor que el nuevo PFALLO ($PFALLO)."
                pedir_prespuesta_obligatorio
            fi
            break
        fi
        echo "Valor inválido. Debe ser un entero entre 5 y 10."
    done
}

pedir_prespuesta_obligatorio() {
    min_pr=$((PFALLO + 1))
    max_pr=$((PVIDA - 1))
    while true; do
        read -r -p "Introduzca nuevo PRESPUESTA ($min_pr..$max_pr): " val
        if es_entero "$val" && [ "$val" -gt "$PFALLO" ] && [ "$val" -lt "$PVIDA" ]; then
            PRESPUESTA="$val"
            break
        fi
        echo "Valor inválido. Debe ser mayor que PFALLO ($PFALLO) y menor que PVIDA ($PVIDA)."
    done
}

pedir_prespuesta() {
    min_pr=$((PFALLO + 1))
    max_pr=$((PVIDA - 1))
    while true; do
        read -r -p "Introduzca PRESPUESTA ($min_pr..$max_pr) [actual: $PRESPUESTA]: " val
        [ -z "$val" ] && break
        if es_entero "$val" && [ "$val" -gt "$PFALLO" ] && [ "$val" -lt "$PVIDA" ]; then
            PRESPUESTA="$val"
            break
        fi
        echo "Valor inválido. Debe cumplirse PFALLO ($PFALLO) < PRESPUESTA < PVIDA ($PVIDA)."
    done
}

pedir_categorias() {
    while true; do
        echo "Niveles: 1=Refranes | 2=+Películas | 3=+Música | 4=+Deportes"
        read -r -p "Introduzca CATEGORIAS (1..4) [actual: $CATEGORIAS]: " val
        [ -z "$val" ] && break
        if es_entero "$val" && [ "$val" -ge 1 ] && [ "$val" -le 4 ]; then
            CATEGORIAS="$val"
            break
        fi
        echo "Valor inválido. Debe ser un entero entre 1 y 4."
    done
}

pedir_estrategia() {
    while true; do
        echo "Modos IA: 0=Alfabética | 1=Aleatoria | 2=Estrategia del grupo"
        read -r -p "Introduzca ESTRATEGIA (0..2) [actual: $ESTRATEGIA]: " val
        [ -z "$val" ] && break
        if es_entero "$val" && [ "$val" -ge 0 ] && [ "$val" -le 2 ]; then
            ESTRATEGIA="$val"
            break
        fi
        echo "Valor inválido. Debe ser un entero entre 0 y 2."
    done
}

pedir_log() {
    while true; do
        read -r -p "Introduzca ruta de LOG [actual: $LOG]: " val
        [ -z "$val" ] && break
        if [ -n "$val" ] && [ ! -d "$val" ]; then
            dir_log=$(dirname "$val")
            if [ -d "$dir_log" ] || mkdir -p "$dir_log" 2>/dev/null; then
                LOG="$val"
                break
            else
                echo "Error: No se puede acceder ni crear el directorio $dir_log."
            fi
        else
            echo "Valor inválido. Debe especificar una ruta de archivo válida (no un directorio)."
        fi
    done
}

opcion_configuracion() {
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
        echo "------------------------------------------"
        echo "T) Editar todos los parámetros paso a paso"
        echo "V) Volver al menú principal"
        echo "=========================================="
        read -r -p "Seleccione parámetro a modificar (1-8, T o V) >> " subop

        subop_mayus=$(echo "$subop" | tr '[:lower:]' '[:upper:]')

        case "$subop_mayus" in
            1) pedir_jugadores; guardar_config ;;
            2) pedir_rondas; guardar_config ;;
            3) pedir_pvida; guardar_config ;;
            4) pedir_pfallo; guardar_config ;;
            5) pedir_prespuesta; guardar_config ;;
            6) pedir_categorias; guardar_config ;;
            7) pedir_estrategia; guardar_config ;;
            8) pedir_log; guardar_config ;;
            T)
                echo "--- Pulse ENTER en cualquier campo para mantener su valor actual ---"
                pedir_jugadores
                pedir_rondas
                pedir_pvida
                pedir_pfallo
                pedir_prespuesta
                pedir_categorias
                pedir_estrategia
                pedir_log
                guardar_config
                echo "Configuración actualizada y guardada en $CONFIG_FILE."
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

opcion_jugar() {
    echo "Módulo JUGAR pendiente de implementación."
}

opcion_frases() {
    echo "Módulo FRASES pendiente de implementación."
}

opcion_estadisticas() {
    echo "Módulo ESTADÍSTICAS pendiente de implementación."
}

pausar() {
    echo ""
    read -n 1 -s -r -p "Pulse una tecla para continuar."
    echo ""
}

if [ $# -gt 1 ]; then
    mostrar_uso
    exit 1
elif [ $# -eq 1 ]; then
    if [ "$1" = "-g" ]; then
        mostrar_info_grupo
        exit 0
    else
        mostrar_uso
        exit 1
    fi
fi

cargar_y_validar_config
validar_frases_inicial

while true; do
    clear
    echo "JUEGO \"EL ENIGMA\""
    echo "C) CONFIGURACIÓN"
    echo "J) JUGAR"
    echo "F) FRASES"
    echo "E) ESTADÍSTICAS"
    echo "S) SALIR"
    read -r -p "Introduzca una opción >> " opcion

    opcion_mayus=$(echo "$opcion" | tr '[:lower:]' '[:upper:]')

    case "$opcion_mayus" in
        C)
            opcion_configuracion
            pausar
            ;;
        J)
            opcion_jugar
            pausar
            ;;
        F)
            opcion_frases
            pausar
            ;;
        E)
            opcion_estadisticas
            pausar
            ;;
        S)
            limpiar_temporales
            exit 0
            ;;
        *)
            echo "Opción no válida."
            pausar
            ;;
    esac
done
