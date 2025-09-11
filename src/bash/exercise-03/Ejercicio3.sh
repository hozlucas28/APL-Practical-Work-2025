#!/usr/bin/env bash

# ejercicio3.sh

# Autores: Gonzalo Rodriguez;Lucas Hoz; Luis Choque; Maira Farias; Valentin Massa

# APL 2025 - Virtualización de Hardware

show_help() {
    echo "Uso: $0 -d <directorio> -p <palabras>"
    echo "Parámetros:"
    echo "  -d, --directorio   Directorio con archivos .log"
    echo "  -p, --palabras     Lista de palabras clave separadas por comas (ej: usb,invalid)"
    echo "  -h, --help         Mostrar ayuda"
}

# ------------------ PARSEO DE PARÁMETROS ------------------
DIRECTORIO=""
PALABRAS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directorio)
            DIRECTORIO="$2"
            shift 2
            ;;
        -p|--palabras)
            PALABRAS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: parámetro desconocido $1"
            show_help
            exit 1
            ;;
    esac
done

# Validaciones
if [[ -z "$DIRECTORIO" || -z "$PALABRAS" ]]; then
    echo "Error: faltan parámetros obligatorios"
    show_help
    exit 1
fi

if [[ ! -d "$DIRECTORIO" ]]; then
    echo "Error: el directorio '$DIRECTORIO' no existe"
    exit 1
fi

# ------------------ PROCESAMIENTO ------------------
IFS=',' read -ra KEYS <<< "$PALABRAS"

declare -A conteo

shopt -s nullglob
for archivo in "$DIRECTORIO"/*.log; do
    for palabra in "${KEYS[@]}"; do
        count=$(awk -v kw="$palabra" '
            BEGIN{IGNORECASE=1}
            {
                n = gsub(kw, "", $0); 
                c += n
            }
            END{print c+0}
        ' "$archivo")
        conteo["$palabra"]=$(( ${conteo[$palabra]:-0} + count ))
    done
done

# ------------------ SALIDA ------------------
for palabra in "${KEYS[@]}"; do
    echo "$palabra: ${conteo[$palabra]:-0}"
done

