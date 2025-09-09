# Integrantes del grupo:
# Rodriguez Gonzalo
#

set -euo pipefail

usage() {
	cat << 'EOF'
Uso: ./ejercicio5.sh -n NOMBRE[,NOMBRE...] -t TTL [OPCIONES]

Consultar información de países usando la API REST Countries, con caché local.

Parámetros:
	-n, --nombre		Lista de paises separados por comas, mínimo tres caracteres por nombre (obligatorio)
	-t, --ttl		Tiempo de vida de la caché en segundos (>0) (obligatorio)
	-f, --force-api		Ignora la caché y consulta siempre a la API (Actualiza la cache)
	-c, --clear-cache	Eliminar toda la caché y salir
	-h, --help		Mostrar esta ayuda y salir

Ejemplos:
	./ejercicio5.sh -n Argentina -t 5
	./ejercicio5.sh -t 15 -n 'Uruguay,Costa Rica,France'
	./ejercicio5.sh -f 'Brazil, Peru' -t 10
	./ejercicio5.sh -c
EOF
}

force_api=false
clear_cache=false
nombres=""
ttl=""
CACHE_DIR="/tmp/ej5_cache"
mkdir -p "$CACHE_DIR"

while [[ $# -gt 0 ]]; do
	case "$1" in
	 -n|--nombre)
	 if [[ $# -lt 2 || -z ${2-} ]]; then
           echo "Error: parámetro de país faltante. Utilize --help para obtener ayuda." >&2
           exit 1
         fi
	   nombres="$2"
	   shift 2
	   ;;
	 -t|--ttl)
 	  if [[ $# -lt 2 || -z ${2-} ]]; then
            echo "Error: parámetro de ttl faltante Utilize --help para obtener ayuda." >&2
            exit 1
         fi
	 ttl="$2"
	   shift 2
	   ;;
	 -h|--help)
	   usage
	   exit 0
	   ;;
	 -f|--force-api)
	   force_api=true
           shift
	   ;;
	 -c|--clear-cache)
	   clear_cache=true
	   shift
	   ;;
	 *)
	   echo "Error: parámetro inválido '$1'"
	   exit 1
	   ;;
	esac
done

if [[ "$clear_cache" == true ]]; then
  rm -rf -- "$CACHE_DIR"
  mkdir -p "$CACHE_DIR"
  echo ">>> Caché eliminada por completo en $CACHE_DIR"
  exit 0
fi

# Validar parametros obligatorios
if ! [[ "$ttl" =~ ^[0-9]+$ ]] || (( ttl <= 0 )); then
  echo "Error: TTL inválido ($ttl). Debe ser un entero > 0. Utilize --help para obtener ayuda" >&2
  exit 1
fi

# Split en array
IFS=',' read -ra paises <<< "$nombres"


# Validar formato de nombre de pais
validar_pais() {
  local p="$1"

  # trim espacios extremos
  p="$(echo "$p" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  # vacío
  if [[ -z "$p" ]]; then
    echo "Error: se encontró un país vacío en la lista." >&2
    return 1
  fi

  # solo letras y espacios
  if ! [[ "$p" =~ ^[A-Za-z][A-Za-z[:space:]]*$ ]]; then
    echo "Error: '$p' no es un nombre válido (solo letras y espacios)." >&2
    return 1
  fi

  # mínimo 3 letras totales (ignorando espacios)
  local letters_only
  letters_only="$(printf '%s' "$p" | tr -cd 'A-Za-z')"
  if (( ${#letters_only} < 3 )); then
    echo "Error: '$p' no es válido (solo letras y espacios, al menos 3 letras en total)." >&2
    return 1
  fi

  echo "$p"
  return 0
}

# Validar todo el array antes de consultar a la API
paises_validos=()
for p in "${paises[@]}"; do
  if ! out="$(validar_pais "$p")"; then
    exit 1
  else
    paises_validos+=("$out")
  fi
done

procesar_pais() {
  local nombre="$1"
  local pais_url
  pais_url=$(echo "$nombre" | sed 's/ /%20/g')
  local cache_file="$CACHE_DIR/${nombre// /_}.json"
  local response

  if [[ "$force_api" == true ]]; then
    echo ">>> Forzando consulta a la API para: $nombre"
    if ! response=$(curl -fsS "https://restcountries.com/v3.1/name/$pais_url" 2>/dev/null); then
      echo "Error: el país '$nombre' no fue encontrado en la API"
      echo
      return
    fi
    echo "$response" > "$cache_file"
  else
    local cache_valida=false
    if [[ -f "$cache_file" ]]; then

      # Archivo de referencia para calcular antiguedad de cache (se fija antiguedad = ttl)
      local reference_file
      reference_file=$(mktemp)
      touch -d "$ttl seconds ago" "$reference_file"

      if [[ "$cache_file" -nt "$reference_file" ]]; then
        cache_valida=true
      fi

      rm "$reference_file"
    fi

    if [[ "$cache_valida" == true ]]; then
      echo ">>> Usando caché para: $nombre"
      response=$(cat "$cache_file")
    else
       if [[ -f "$cache_file" ]]; then
          echo ">>> Caché vencida, consultando API para: $nombre"
       else
          echo ">>> Consultando API para: $nombre"
       fi

       if ! response=$(curl -fsS "https://restcountries.com/v3.1/name/$pais_url" 2>/dev/null); then
          echo "Error: el país '$nombre' no fue encontrado en la API"
          echo
          return
       fi

       echo "$response" > "$cache_file"
    fi
  fi

  local pais capital region poblacion moneda
  pais=$(echo "$response" | grep -o '"common":"[^"]*' | head -1 | cut -d':' -f2 | tr -d '"')
  capital=$(echo "$response" | grep -o '"capital":\["[^"]*' | head -1 | cut -d'[' -f2 | tr -d '"')
  region=$(echo "$response" | grep -o '"region":"[^"]*' | head -1 | cut -d':' -f2 | tr -d '"')
  poblacion=$(echo "$response" | grep -o '"population":[0-9]*' | head -1 | cut -d':' -f2)
  moneda=$(echo "$response" | grep -o '"currencies":{[^}]*}' | head -1 \
           | sed -E 's/.*"([A-Z]{3})":\{"symbol":"[^"]*","name":"([^"]*)".*/\2 (\1)/')

  echo "País: $pais"
  echo "Capital: $capital"
  echo "Región: $region"
  echo "Población: $poblacion"
  echo "Moneda: $moneda"
  echo
}

for p in "${paises_validos[@]}"; do 
  procesar_pais "$p"
done
