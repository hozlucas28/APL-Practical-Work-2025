#!/bin/bash

# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.
# Script demonio para auditar repositorios Git en busca de patrones sensibles

PID_FILE="/tmp/audit.pid"
COMMIT_FILE="/tmp/last_commit.txt"

# Función de ayuda
usage() {
    echo "Uso: $0 -r <repo> -c <config> -l <log> [-k] [-h]"
    echo ""
    echo "Parámetros:"
    echo "  -r | --repo           Ruta del repositorio Git a monitorear"
    echo "  -c | --configuracion  Archivo con lista de patrones a buscar"
    echo "  -l | --log            Archivo de log donde registrar coincidencias"
    echo "  -k | --kill           Detener el demonio si está corriendo"
    echo "  -h | --help           Mostrar ayuda"
    exit 1
}

# Manejo de parámetros
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo) REPO="$2"; shift 2 ;;
        -c|--configuracion) CONFIG="$2"; shift 2 ;;
        -l|--log) LOG="$2"; shift 2 ;;
        -k|--kill) KILL=1; shift ;;
        -h|--help) usage ;;
        *) echo "Parámetro inválido: $1"; usage ;;
    esac
done

# Función para detener el demonio
detener_demonio() {
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm -f "$PID_FILE"
            echo "Demonio detenido (PID $PID)"
            exit 0
        else
            echo "No hay ningún demonio en ejecución con PID $PID"
            rm -f "$PID_FILE"
            exit 1
        fi
    else
        echo "No existe archivo $PID_FILE, no hay demonio que detener"
        exit 1
    fi
}

# Si se pasa -k, detener demonio y salir
if [[ "$KILL" == "1" ]]; then
    detener_demonio
fi

# Validaciones
if [[ -z "$REPO" || -z "$CONFIG" || -z "$LOG" ]]; then
    echo "ERROR: faltan parámetros obligatorios"
    usage
fi

if ! git -C "$REPO" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "ERROR: '$REPO' no es un repositorio Git válido"
    exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: archivo de configuración '$CONFIG' no encontrado"
    exit 1
fi

# Función para limpiar al salir
limpiar() {
    rm -f "$PID_FILE"
    echo "Limpieza realizada, demonio detenido"
    exit 0
}
trap limpiar SIGINT SIGTERM EXIT

# Inicio del demonio
iniciar_demonio() {
    BRANCH=$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null)
    echo "Monitoreando repositorio: $REPO (rama: $BRANCH)"

    # Leer el último commit desde archivo si existe
    if [[ -f "$COMMIT_FILE" ]]; then
        last_commit=$(cat "$COMMIT_FILE")
    else
        last_commit=$(git -C "$REPO" rev-parse HEAD)
        echo "$last_commit" > "$COMMIT_FILE"
    fi

    while true; do
        new_commit=$(git -C "$REPO" rev-parse HEAD)
        if [ "$new_commit" != "$last_commit" ]; then
            echo "Nuevo commit detectado: $new_commit"

            archivos=$(git -C "$REPO" diff --name-only "$last_commit" "$new_commit")
            for archivo in $archivos; do
                if [[ -f "$REPO/$archivo" ]]; then
                    while read -r patron; do
                        if grep -q "$patron" "$REPO/$archivo" 2>/dev/null; then
                            mensaje="ALERTA: Patrón '$patron' encontrado en '$archivo'"
                            if ! grep -q "$mensaje" "$LOG" 2>/dev/null; then
                                echo "$(date '+%Y-%m-%d %H:%M:%S') $mensaje" | tee -a "$LOG"
                            fi
                        fi
                    done < "$CONFIG"
                fi
            done
            last_commit=$new_commit
            echo "$new_commit" > "$COMMIT_FILE"
        fi
        sleep 10
    done
}

# Lanzar demonio en background
iniciar_demonio &
echo $! > "$PID_FILE"
echo "Demonio corriendo en segundo plano con PID $(cat "$PID_FILE")"
wait

