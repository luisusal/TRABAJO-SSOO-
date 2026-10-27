#!/bin/bash

limpiar_temporales() {
    rm -f /tmp/enigma_tmp_* 2>/dev/null
}

trap 'limpiar_temporales; exit 1' INT TERM

mostrar_info() {
    echo "=================================================="
    echo "        MODO INFORMACIÓN (-g) - EL ENIGMA         "
    echo "=================================================="
    echo "Integrantes del grupo: Roc Cardona y Luis Corrionero"
    echo ""
    echo "Lógica de Estrategia Propia (ESTRATEGIA=2):"
    echo "  - Analiza la frecuencia de aparición de letras en castellano"
    echo "    dando prioridad a las vocales no probadas y a consonantes"
    echo "    de alta frecuencia (E, A, O, L, S, N, R, D, T)."
    echo ""
    echo "Estadística de Libre Elección (Opción E):"
    echo "  - Porcentaje global de aciertos en intentos de resolución"
    echo "    directa de frases respecto al total de intentos."
    echo "=================================================="
}

validar_ficheros_iniciales() {
    if [ ! -f "config.cfg" ] || [ ! -s "config.cfg" ]; then
        echo "Error: El fichero de configuración 'config.cfg' no existe o está
vacío."