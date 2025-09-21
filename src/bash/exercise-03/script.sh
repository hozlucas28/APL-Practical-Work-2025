#! /bin/bash

# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

show_help() {
  printf "Uso: bash $0 [OPCIONES...]\


  -d, --directorio   directorio con los archivos \`.log\`\

  -p, --palabras     lista de las palabras clave a buscar, separadas por comas (por ejemplo: usb,invalid)\

  -h, --help         muestra esta lista de ayuda\


Las opciones \`-d\` / \`--directorio\` y \`-p\` / \`--palabras\` son obligatorias.
"
}

# Parseo de parámetros
DIRECTORIO=""
PALABRAS=""

while [ $# -gt 0 ]; do
    case "$1" in
        "-d" | "--directorio")
            DIRECTORIO="$2"
            shift 2
            ;;
        "-p" | "--palabras")
            PALABRAS="$2"
            shift 2
            ;;
        "-h" | "--help")
            show_help
            exit 0
            ;;
        *)
            printf "> Parámetro desconocido \`$1\`\n\n"
            show_help
            exit 1
            ;;
    esac
done

# Validaciones
if [[ -z "$DIRECTORIO" || -z "$PALABRAS" ]]; then
    printf "> Faltan los parámetros obligatorios\n\n"
    show_help
    exit 1
fi

if [[ ! -d "$DIRECTORIO" ]]; then
    printf "> El directorio \`$DIRECTORIO\` no existe"
    exit 1
fi

# Procesamiento
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

# Imprimir por pantalla
for palabra in "${KEYS[@]}"; do
    echo "$palabra: ${conteo[$palabra]:-0}"
done
