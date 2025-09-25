#!/usr/bin/env bash

# Ejercicio 5 - APL 2025 - Virtualización de Hardware
# Autores: Gonzalo Rodriguez;Lucas Hoz; Luis Choque; Maira Farias; Valentin Massa

usage() {
  cat << 'EOF'
Uso: ./ejercicio5.sh -n NOMBRE[,NOMBRE...] -t TTL [OPCIONES]

Consultar información de países usando la API REST Countries, con caché local.

Parámetros:
  -n, --nombre        Lista de paises separados por comas, mínimo tres caracteres por nombre (obligatorio)
  -t, --ttl           Tiempo de vida de la caché en segundos (>0) (obligatorio)
  -f, --force-api     Ignora la caché y consulta siempre a la API (Actualiza la cache)
  -c, --clear-cache   Eliminar toda la caché y salir (si se usa solo); si se combina con parámetros válidos, limpia y continúa
  -h, --help          Mostrar esta ayuda y salir

Ejemplos:
  ./ejercicio5.sh -n Argentina -t 5
  ./ejercicio5.sh -t 15 -n 'Uruguay,Costa Rica,France'
  ./ejercicio5.sh -n 'Brazil, Peru' -t 10 -f
  ./ejercicio5.sh -c
EOF
}

force_api=false
clear_cache=false
nombres=""
ttl=""

# Directorio de caché
if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
  BASE_CACHE="$XDG_CACHE_HOME"
elif [[ "${OSTYPE:-}" == darwin* ]]; then
  BASE_CACHE="$HOME/Library/Caches"
else
  BASE_CACHE="$HOME/.cache"
fi
CACHE_DIR="$BASE_CACHE/ej5_cache"
mkdir -p "$CACHE_DIR"

# Eliminar prefijos y sufijos de espacios
trim() { sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

# URL-encode simple (soporta espacios, tildes y símbolos comunes)
urlencode() {
  local s="$1" i c out="" hex
  LC_ALL=C
  for ((i=0; i<${#s}; i++)); do
    c="${s:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) out+="$c" ;;
      ' ') out+="%20" ;;
      *) printf -v hex '%%%02X' "'$c"; out+="$hex" ;;
    esac
  done
  printf '%s' "$out"
}

# Parámetros
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--nombre)
      if [[ $# -lt 2 || -z ${2-} ]]; then
        echo "Error: parámetro de país faltante. Utilice --help para obtener ayuda." >&2
        exit 1
      fi
      nombres="$2"
      shift 2
      ;;
    -t|--ttl)
      if [[ $# -lt 2 || -z ${2-} ]]; then
        echo "Error: parámetro de ttl faltante. Utilice --help para obtener ayuda." >&2
        exit 1
      fi
      ttl="$2"
      shift 2
      ;;
    -h|--help)
      usage; exit 0 ;;
    -f|--force-api)
      force_api=true; shift ;;
    -c|--clear-cache)
      clear_cache=true; shift ;;
    *)
      echo "Error: parámetro inválido '$1'. Utilice --help para obtener ayuda." >&2
      exit 1
      ;;
  esac
done

# SOLO clear-cache: limpia y sale
if [[ $clear_cache == true && -z "$nombres" && -z "$ttl" && $force_api == false ]]; then
  rm -rf -- "$CACHE_DIR"
  mkdir -p "$CACHE_DIR"
  echo ">>> Caché eliminada por completo en $CACHE_DIR"
  exit 0
fi

# Validaciones obligatorias
if [[ -z "$nombres" || -z "$ttl" ]]; then
  echo "Error: los parámetros -n/--nombre y -t/--ttl son obligatorios (salvo uso exclusivo de -c/--clear-cache)." >&2
  exit 1
fi
if ! [[ "$ttl" =~ ^[0-9]+$ ]] || (( ttl <= 0 )); then
  echo "Error: TTL inválido ($ttl). Debe ser un entero > 0." >&2
  exit 1
fi

# Si pidieron limpiar junto con parámetros válidos: limpiar y seguir
if [[ $clear_cache == true ]]; then
  rm -rf -- "$CACHE_DIR"
  mkdir -p "$CACHE_DIR"
  echo ">>> Caché eliminada antes de procesar en $CACHE_DIR"
fi

# Validación de nombres
validar_pais() {
  local p="$1"
  p="$(printf '%s' "$p" | trim)"
  if [[ -z "$p" ]]; then
    echo "Error: se encontró un país vacío en la lista." >&2
    return 1
  fi
  # letras (incluye acentos según locale), espacios, apóstrofes y guiones
  if ! [[ "$p" =~ ^[[:alpha:]][[:alpha:][:space:]\'-]*$ ]]; then
    echo "Error: '$p' no es un nombre válido (solo letras, espacios, apóstrofes y guiones)." >&2
    return 1
  fi
  local soloLetras
  soloLetras="$(printf '%s' "$p" | tr -cd '[:alpha:]')"
  if (( ${#soloLetras} < 3 )); then
    echo "Error: '$p' no es válido. Debe contener al menos 3 letras." >&2
    return 1
  fi
  echo "$p"
}

IFS=',' read -r -a _paises <<< "$nombres"
paises_validos=()
for p in "${_paises[@]}"; do
  if ! out="$(validar_pais "$p")"; then
    exit 2
  fi
  paises_validos+=("$out")
done

# Procesar país (caché o API)
procesar_pais() {
  local nombre="$1"
  local nombre_sanitizado="${nombre// /_}"
  local cache_json="$CACHE_DIR/${nombre_sanitizado}.json"
  local cache_meta="$CACHE_DIR/${nombre_sanitizado}.meta"
  local now exp response_json

  # caché si no es force
  if ! $force_api && [[ -f "$cache_json" && -f "$cache_meta" ]]; then
    now="$(date -u +%s)"
    exp="$(cat "$cache_meta" 2>/dev/null || echo 0)"
    if [[ "$now" =~ ^[0-9]+$ ]] && [[ "$exp" =~ ^[0-9]+$ ]] && (( now < exp )); then
      echo ">>> Usando caché para: $nombre"
      response_json="$(cat "$cache_json")"
    else
      echo ">>> Caché vencida para: $nombre"
    fi
  fi

  # API si no hay respuesta
  if [[ -z "${response_json:-}" ]]; then
    if $force_api; then
      echo ">>> Forzando consulta a la API para: $nombre"
    else
      echo ">>> Consultando API para: $nombre"
    fi
    local pais_url; pais_url="$(urlencode "$nombre")"
    if ! response_json="$(curl -fsS "https://restcountries.com/v3.1/name/$pais_url" 2>/dev/null)"; then
      echo "Error: el país '$nombre' no fue encontrado en la API"
      echo
      return 3
    fi

    printf '%s' "$response_json" > "$cache_json"
    date -u +%s | awk -v add="$ttl" '{print $1+add}' > "$cache_meta"
  fi

  # Formateo de salida
  local pais capital region poblacion moneda
  pais=$(echo "$response_json"    | grep -o '"common":"[^"]*'        | head -1 | cut -d':' -f2 | tr -d '"')
  capital=$(echo "$response_json" | grep -o '"capital":\["[^"]*'     | head -1 | cut -d'[' -f2 | tr -d '"')
  region=$(echo "$response_json"  | grep -o '"region":"[^"]*'        | head -1 | cut -d':' -f2 | tr -d '"')
  poblacion=$(echo "$response_json" | grep -o '"population":[0-9]*'  | head -1 | cut -d':' -f2)
  moneda=$(echo "$response_json"  | grep -o '"currencies":{[^}]*}'   | head -1 \
           | sed -E 's/.*"([A-Z]{3})":\{[^}]*"name":"([^"]+)".*/\2 (\1)/')

  [[ -z "${capital:-}"   ]] && capital="N/D"
  [[ -z "${region:-}"    ]] && region="N/D"
  [[ -z "${poblacion:-}" ]] && poblacion="N/D"
  [[ -z "${moneda:-}"    ]] && moneda="N/D"
  [[ -z "${pais:-}"      ]] && pais="$nombre"

  echo "País: $pais"
  echo "Capital: $capital"
  echo "Región: $region"
  echo "Población: $poblacion"
  echo "Moneda: $moneda"
  echo
}

# Si alguno falla por API, se retorna 3.
rc=0
for p in "${paises_validos[@]}"; do
  if ! procesar_pais "$p"; then
	rc=3;
  fi
done
exit "$rc"
