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
  echo "> Failed to parse options" >&2
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
        echo "> An error occurred while parsing options" >&2
        exit 1
        ;;
    esac
done

# Print help
if [ -n "$help" ]; then
  printf "Usage: bash script.sh [OPTION...]\


  -d, --directorio  directory containing the survey files to process\

  -a, --archivo     path to the output JSON file\

  -p, --pantalla    displays the output on screen\

  -h, --help        give this help list\


\`-a\` / \`--archivo\` and \`-p\` / \`--pantalla\` options must not be declarer together.
"
  exit 0
fi

# Verify `directory` parameter
if [ -z "$directory" ]; then
  echo "> \`-$pDirShortName\` / \`--$pDirLongName\` option required" >&2
  exit 1
fi

if [ ! -d "$directory" ]; then
  echo "> \`-$pDirShortName\` / \`--$pDirLongName\` option must be a valid directory" >&2
  exit 1
fi

# Verify `file` and `display` parameters
if [ -z "$file" ] && [ -z "$display" ]; then
  echo "> \`-$pFileShortName\` / \`--$pFileLongName\`, xor \`-$pDisplayShortName\` / \`--$pDisplayLongName\` options required" >&2
  exit 1
fi

if [ -n "$file" ] && [ -n "$display" ]; then
  echo "> \`-$pFileShortName\` / \`--$pFileLongName\`, and \`-$pDisplayShortName\` / \`--$pDisplayLongName\` must not be declarer together" >&2
  exit 1
fi

# Verify `file` parameter extension
if [ -n "$file" ]; then
  case "$file" in
    *.json)
      ;;
    *)
      echo "> \`-$pFileShortName\` / \`--$pFileLongName\` option must be a \`.json\` file" >&2
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
      responseTimeAVG=$(bc -l <<< "$responseTimeAcc / $responseTimeCounter")
      scoreAVG=$(bc -l <<< "$scoreAcc / $scoreCounter")

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
      responseTimeAVG=$(bc -l <<< "$responseTimeAcc / $responseTimeCounter")
      scoreAVG=$(bc -l <<< "$scoreAcc / $scoreCounter")

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
      responseTimeAcc=$(bc -l <<< "$responseTime + $responseTimeAcc")
      responseTimeCounter=$(bc -l <<< "1 + $responseTimeCounter")

      scoreAcc=$(bc -l <<< "$score + $scoreAcc")
      scoreCounter=$(bc -l <<< "1 + $scoreCounter")
    fi
  fi
done < "$sortedTempFile"

# Print last channel of the last date
if [ ! -z "$lastChannelRemaining" ]; then
  responseTimeAVG=$(bc -l <<< "$responseTimeAcc / $responseTimeCounter" )
  scoreAVG=$(bc -l <<< "$scoreAcc / $scoreCounter" )

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
