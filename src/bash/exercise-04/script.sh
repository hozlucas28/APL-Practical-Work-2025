#! /bin/bash

# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

show_help() {
    printf "Uso: bash $0 [OPCIONES...]\


    -r, --repo           ruta del repositorio a monitorear\

    -c, --configuracion  archivo con lista de patrones a buscar\

    -l, --log            archivo donde registraran las coincidencias\

    -k, --kill           detener el demonio, si y solo si, está corriendo\

    -h, --help           muestra esta lista de ayuda\


Las opciones \`-r\` / \`--repo\`, \`-c\` / \`--configuracion\` y \`-l\` / \`--log\` son obligatorias.
Si se define la opción \`-k\` / \`--kill\`, únicamente la opción \`-r\` / \`--repo\` es obligatoria.
"
}

detener_demonio() {
    local PID_FILE="$1"

    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)

        if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm -f "$PID_FILE"
            echo "> Demonio detenido (PID $PID)"
        else
            echo "> No hay ningún demonio en ejecución con PID $PID"
            rm -f "$PID_FILE" 2>/dev/null || true
        fi
    else
        echo "> No existe el archivo $PID_FILE, por lo que no hay un demonio para detener"
    fi
}

iniciar_demonio() {
    local REPO="$1"
    local CONFIG="$2"
    local LOG="$3"
    local PID_FILE="$4"
    local COMMIT_FILE="$5"

    BRANCH=$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null)

    echo "> Monitoreando repositorio \`$REPO\` ($BRANCH)"
    echo "> Demonio corriendo en segundo plano con PID $$"
    echo "> Terminal liberada"

    # Si existe, leer el último commit
    if [[ -f "$COMMIT_FILE" ]]; then
        last_commit=$(cat "$COMMIT_FILE")
    else
        last_commit=$(git -C "$REPO" rev-parse HEAD)
        echo "$last_commit" > "$COMMIT_FILE"
    fi

    while true; do
        new_commit=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)

        if [ "$new_commit" != "$last_commit" ]; then
            archivos=$(git -C "$REPO" diff --name-only "$last_commit" "$new_commit")

            for archivo in $archivos; do
                [[ ! -f "$REPO/$archivo" ]] && continue
                [[ "$REPO/$archivo" == "$CONFIG" ]] && continue

                # Leer patrones (línea por línea)
                while IFS= read -r raw_patron || [[ -n "$raw_patron" ]]; do
                    # Eliminar espacios
                    patron="$(printf '%s' "$raw_patron" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                    [[ -z "$patron" ]] && continue

                    # Eliminar el prefijo 'regex:'
                    patron="${patron#regex:}"

                    if grep -E "$patron" "$REPO/$archivo" >/dev/null 2>&1; then
                        mensaje="Alerta: patrón '$patron' encontrado en el archivo '$(realpath "$archivo")'."

                        if ! grep -F -q "$mensaje" "$LOG" 2>/dev/null; then
                            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $mensaje" | tee -a "$LOG" >/dev/null
                        fi
                    fi
                done < "$CONFIG"
            done

            last_commit=$new_commit
            echo "$new_commit" > "$COMMIT_FILE"
        fi

        sleep 1
    done
}

# Parseo de parámetros
while [ $# -gt 0 ]; do
    case "$1" in
        "-r" | "--repo")
            REPO=$(realpath "$2")
            shift 2
            ;;
        "-c" | "--configuracion")
            CONFIG=$(realpath "$2")
            shift 2
            ;;
        "-l" | "--log")
            LOG="$2"
            shift 2
            ;;
        "-k" | "--kill")
            KILL=true
            shift
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

# Generar archivos por repositorio para PID y último commit
REPO_HASH=$(printf "%s" "$REPO" | md5sum | awk '{print $1}')
PID_FILE="/tmp/audit_${REPO_HASH}.pid"
COMMIT_FILE="/tmp/last_commit_${REPO_HASH}.txt"

# Si se envía el parámetro `--kill`, detener el demonio y finalizar el script
if [[ -n "$KILL" ]]; then
    if [[ -z "$REPO" ]]; then
        printf "> La opción \`-r\` / \`--repo\` es obligatoria\n\n"
        show_help
        exit 1
    fi

    detener_demonio "$PID_FILE"
    exit 0
fi

# Validación de parámetros
if [[ -z "$REPO" || -z "$CONFIG" || -z "$LOG" ]]; then
    printf "> Las opciones \`-r\` / \`--repo\`, \`-c\` / \`--configuracion\` y \`-l\` / \`--log\` son obligatorias\n\n"
    show_help
    exit 1
fi

if ! git -C "$REPO" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "> El repositorio \`$REPO\` no es un repositorio de Git válido"
    exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "> No se ha encontrado el archivo de configuración \`$CONFIG\`"
    exit 1
fi

# Evitar múltiples demonios para el mismo repo
if [[ -f "$PID_FILE" ]]; then
    EXISTING_PID=$(cat "$PID_FILE" 2>/dev/null || echo "")

    if [[ -n "$EXISTING_PID" ]] && kill -0 "$EXISTING_PID" 2>/dev/null; then
        echo "> Ya existe un demonio en ejecución para el repositorio (PID $EXISTING_PID). No se iniciará otro."
        exit 1
    else
        rm -f "$PID_FILE" 2>/dev/null || true
    fi
fi

# Ejecutar demonio en background y guardar su PID
iniciar_demonio "$REPO" "$CONFIG" "$LOG" "$PID_FILE" "$COMMIT_FILE" &
echo $! > "$PID_FILE"
