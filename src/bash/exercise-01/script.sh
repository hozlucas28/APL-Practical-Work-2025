#! /bin/bash

# Configurations variables
pDirShortName="d"
pFileShortName="a"
pDisplayShortName="p"

pDirLongName="directorio"
pFileLongName="archivo"
pDisplayLongName="pantalla"

fieldSep="|"

fResponseTimeAVG="tiempo_respuesta_promedio"
fScoreAVG="nota_satisfaccion_promedio"

# Parse parameters
parameters=$(getopt -o "h$pDirShortName:$pFileShortName:$pDisplayShortName" --long "help,$pDirLongName:,$pFileLongName:,$pDisplayLongName" -- "$@")

if [ $? -ne 0 ]; then
  echo "> No se pudieron analizar las opciones" >&2
  exit 1
fi

eval set -- "$parameters"

while true; do
    case "$1" in
      "-h" | "--help")
        help=true
        shift 1
        break
        ;;
      "-$pDirShortName" | "--$pDirLongName")
        directory="$2"
        shift 2
        ;;
      "-$pFileShortName" | "--$pFileLongName")
        file="$2"
        shift 2
        ;;
      "-$pDisplayShortName" | "--$pDisplayLongName")
        display=true
        shift 1
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

# Print help
if [ -n "$help" ]; then
  printf "Uso: bash script.sh [OPTION...]\


  -d, --directorio  directorio que contiene los archivos de la encuesta a procesar\

  -a, --archivo     ruta al archivo JSON de salida\

  -p, --pantalla    muestra la salida en la pantalla\

  -h, --help        muestra esta lista de ayuda\


Las opciones \`-a\` / \`--archivo\` y \`-p\` / \`--pantalla\` no deben declararse juntas.
"
  exit 0
fi

# Verify `directory` parameter
if [ -z "$directory" ]; then
  echo "> La opción \`-$pDirShortName\` / \`--$pDirLongName\` es requerida" >&2
  exit 1
fi

if [ ! -d "$directory" ]; then
  echo "> La opción \`-$pDirShortName\` / \`--$pDirLongName\` debe ser un directorio válido" >&2
  exit 1
fi

# Verify `file` and `display` parameters
if [ -z "$file" ] && [ -z "$display" ]; then
  echo "> Las opciones \`-$pFileShortName\` / \`--$pFileLongName\` ó \`-$pDisplayShortName\` / \`--$pDisplayLongName\` son requeridas" >&2
  exit 1
fi

if [ -n "$file" ] && [ -n "$display" ]; then
  echo "> \`-$pFileShortName\` / \`--$pFileLongName\` y \`-$pDisplayShortName\` / \`--$pDisplayLongName\` no deben declararse juntas" >&2
  exit 1
fi

# Verify `file` parameter extension
if [ -n "$file" ]; then
  case "$file" in
    *.json)
      ;;
    *)
      echo "> La opción \`-$pFileShortName\` / \`--$pFileLongName\` debe ser un archivo \`.json\`" >&2
      exit 1
      ;;
  esac
else
  file="/tmp/satisfaction-survey-averages-$$.tmp.json"
fi

# Concat all `directory` files within a temporal file
tempFile="/tmp/satisfaction-surveys-$$.tmp.txt"
> "$tempFile"

for innerFile in "$directory"/*; do
  while IFS= read -r line; do
    line=$(echo "$line" | tr -d '\r\n')
    echo "$line" >> "$tempFile"
  done < "$innerFile"
done

# Sort concated temporal file by date and channel
sortedTempFile="/tmp/satisfaction-surveys-sorted-$$.tmp.txt"
sort -t "$fieldSep" -k2.1,2.10 -k3,3 "$tempFile" > "$sortedTempFile"

rm "$tempFile"

# Calculate satisfaction survey averages
lastDate=""
lastChannel=""
responseTimeAcc="0"
responseTimeCounter="0"
scoreAcc="0"
scoreCounter="0"

echo "{" > "$file"

while IFS="$fieldSep" read -r id date channel responseTime score; do
  date=$(echo "$date" | cut -d' ' -f1)

  if [ "$date" != "$lastDate" ]; then
    if [ "$lastDate" != "" ]; then
      responseTimeAVG=$(awk "BEGIN {print $responseTimeAcc / $responseTimeCounter}")
      scoreAVG=$(awk "BEGIN {print $scoreAcc / $scoreCounter}")

      printf "\
        \"%s\": {
            \"%s\": %g,\n\
            \"%s\": %g\n\
        }\n\
    },\n" "$lastChannel" "$fResponseTimeAVG" "$responseTimeAVG" "$fScoreAVG" "$scoreAVG" >> "$file"

    lastChannelRemaining=true
    fi

    printf "\
    \"%s\": {\
    \n" "$date" >> "$file"

    lastDate="$date"
    lastChannel="$channel"
    responseTimeAcc="$responseTime"
    responseTimeCounter="1"
    scoreAcc="$score"
    scoreCounter="1"
  else
    if [ "$channel" != "$lastChannel" ]; then
      responseTimeAVG=$(awk "BEGIN {print $responseTimeAcc / $responseTimeCounter}")
      scoreAVG=$(awk "BEGIN {print $scoreAcc / $scoreCounter}")

      printf "\
        \"%s\": {
            \"%s\": %g,\n\
            \"%s\": %g\n\
        },\n" "$lastChannel" "$fResponseTimeAVG" "$responseTimeAVG" "$fScoreAVG" "$scoreAVG" >> "$file"

      lastChannel="$channel"
      responseTimeAcc="$responseTime"
      responseTimeCounter="1"
      scoreAcc="$score"
      scoreCounter="1"
    else
      responseTimeAcc=$(awk "BEGIN {print $responseTime + $responseTimeAcc}")
      responseTimeCounter=$(awk "BEGIN {print 1 + $responseTimeCounter}")

      scoreAcc=$(awk "BEGIN {print $score + $scoreAcc}")
      scoreCounter=$(awk "BEGIN {print 1 + $scoreCounter}")
    fi
  fi
done < "$sortedTempFile"

# Print last channel of the last date
if [ ! -z "$lastChannelRemaining" ]; then
  responseTimeAVG=$(awk "BEGIN {print $responseTimeAcc / $responseTimeCounter}")
  scoreAVG=$(awk "BEGIN {print $scoreAcc / $scoreCounter}")

  printf "\
        \"%s\": {
            \"%s\": %g,\n\
            \"%s\": %g\n\
        }\n\
    }\n" "$lastChannel" "$fResponseTimeAVG" "$responseTimeAVG" "$fScoreAVG" "$scoreAVG" >> "$file"
fi

echo "}" >> "$file"

rm "$sortedTempFile"

# Display satisfaction survey averages if `display` parameter is set
if [ -n "$display" ]; then
  printf "$(cat "$file")"
  rm "$file"
fi

exit 0
