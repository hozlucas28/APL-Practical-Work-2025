#! /bin/bash

# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

show_help() {
  printf "Uso: bash $0 [OPCIONES...]\


    -n, --nombre        nombres de los países a buscar, separados por comas (por ejemplo: \"argentina,panama,south africa\")\

    -t, --ttl           Tiempo en segundos para mantener los resultados en Cache\

    -h, --help          muestra esta lista de ayuda\


Las opciones \`-n\` / \`--nombre\` y \`-t\` / \`--ttl\` son obligatorias.
"
}

# URL Encode (soporta espacios, tildes y símbolos comunes)
urlEncode() {
  local s="$1"
  local i
  local c
  local out=""
  local hex

  LC_ALL=C

  for (( i=0; i < ${#s}; i++ )); do
    c="${s:i:1}"

    case "$c" in
      [a-zA-Z0-9.~_-])
        out+="$c"
        ;;
      ' ')
        out+="%20"
        ;;
      *)
        printf -v hex '%%%02X' "'$c"
        out+="$hex"
        ;;
    esac
  done

  printf '%s' "$out"

  return 0
}

# Parseo de parámetros
while [ $# -gt 0 ]; do
  case "$1" in
    "-n" | "--nombre")
      nombre="$2"
      shift 2
      ;;
    "-t" | "--ttl")
      ttl="$2"
      shift 2
      ;;
    "-h" | "--help")
      show_help;
      exit 0
      ;;
    "--")
      shift
      break
      ;;
    *)
      echo "> Se produjo un error al analizar las opciones" >&2
      exit 1
      ;;
  esac
done

# Verificar parámetros `-n` / `--nombre` y `-t` / `--ttl`
if [[ -z "$nombre" || -z "$ttl" ]]; then
  echo "> Las opciones \`-n\` / \`--nombre\` y \`-t\` / \`--ttl\` son requeridos" >&2
  exit 1
fi

# Verificar parámetro `-t` / `--ttl`
if ! [[ "$ttl" =~ ^[0-9]+$ ]] || (( ttl <= 0 )); then
  echo "> La opción \`-t\` / \`--ttl\` es inválida" >&2
  exit 1
fi

# Crear/Obtener directorio de caches
if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
  cacheBase="$XDG_CACHE_HOME"
elif [[ "${OSTYPE:-}" == darwin* ]]; then
  cacheBase="$HOME/Library/Caches"
else
  cacheBase="$HOME/.cacheFile"
fi

cacheDir="$cacheBase/hv-exercise-05"
mkdir -p "$cacheDir"

obtener_pais() {
  local pais="$1"
  local cacheDir="$2"

  local paisSan="${pais// /_}"

  local cacheFile="$cacheDir/${paisSan}.json"
  local expirationFile="$cacheDir/${paisSan}.exp"

  local now
  local exp
  local data

  # Si existe una cache para el país, obtener los datos guardados
  if [[ -f "$cacheFile" && -f "$expirationFile" ]]; then
    now="$(date -u +%s)"
    exp="$(cat "$expirationFile" 2>/dev/null)"

    if [[ now -lt exp ]] ; then
      data="$(cat "$cacheFile")"
    fi
  fi

  local paisEncoded
  local apiEndpoint

  # Si no existe una cache para el país ó ha expirado, consultar la API
  if [[ -z "$data" ]]; then
    paisEncoded="$(urlEncode "$pais")"
    apiEndpoint="https://restcountries.com/v3.1/name/$paisEncoded?fullText=true&fields=name,currencies,capital,region,population"

    if data="$(curl -fsS "$apiEndpoint" 2>/dev/null)"; then
      # Guardar datos
      printf '%s' "$data" > "$cacheFile"

      # Guardar la expiración de los datos
      date -u +%s | awk -v add="$ttl" '{print $1+add}' > "$expirationFile"
    fi
  fi

  if [[ "$data" == "" ]]; then
    return 1
  else
    echo "$data"
    return 0
  fi
}

# Obtener los datos de cada país
IFS=',' read -ra nombre <<< "$nombre"

for pais in "${nombre[@]}"; do
  data=$(obtener_pais "$pais" "$cacheDir")

  if [[ $? -eq 0 ]]; then
    paisNombre=$(echo "$data"    | grep -o '"common":"[^"]*'      | head -1 | cut -d ':' -f2 | tr -d '":'                        )
    paisCapital=$(echo "$data"   | grep -o '"capital":\[".*"\]'             | cut -d ':' -f2 | tr -d '["]' | sed 's/,/, /g'      )
    paisRegion=$(echo "$data"    | grep -o '"region":"[^"]*'      | head -1 | cut -d ':' -f2 | tr -d ':"'                        )
    paisPoblacion=$(echo "$data" | grep -o '"population":[0-9]*'  | head -1 | cut -d ':' -f2 | tr -d ':'                         )
    paisMoneda=$(echo "$data"    | grep -o '"currencies":{.*}}'   | sed -E 's/"([^"]+)":\{"name":"([^"]+)"[^}]*\}/\2 (\1)/g' | sed -E 's/"currencies":\{(.*)\}/\1/g' | sed 's/,/, /g')

    printf "\nPaís: $paisNombre\n"
    printf "Capital: $paisCapital\n"
    printf "Región: $paisRegion\n"
    printf "Población: $paisPoblacion\n"
    printf "Moneda: $paisMoneda\n"
  else
    printf "\n> No se ha podido consultar el pais \`$pais\` a la API.\n" >&2
  fi
done
