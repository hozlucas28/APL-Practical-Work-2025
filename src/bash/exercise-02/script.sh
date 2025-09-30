#! /bin/bash

# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

es_menor() {
    awk -v a="$1" -v b="$2" 'BEGIN {exit !(a < b)}'
}

es_mayor_a_cero() {
    awk -v a="$1" 'BEGIN {exit !(a > 0)}'
}

es_igual() {
    awk -v a="$1" -v b="$2" 'BEGIN {exit !(a == b)}'
}

es_numero() {
    local valor="$1"
    [[ "$valor" =~ ^([0-9]+)(\.[0-9]+)?$ ]]
}

es_matriz_cuadrada() {
    local filas="$1"
    local columnas="$2"

    [ "$filas" -eq "$columnas" ]
}

es_matriz_simetrica() {
    local array_name="$1"
    local dimension="$2"
    local -n matriz_ref="$array_name"

    for ((i=0; i<dimension; i++)); do
        for ((j=i; j<dimension; j++)); do
            local a="${matriz_ref[$i,$j]}"
            local b="${matriz_ref[$j,$i]}"

            if ! es_igual "$a" "$b"; then
                return 1
            fi
        done
    done

    return 0
}

tiene_diagonal_con_ceros() {
    local array_name="$1"
    local dimension="$2"
    local -n matriz_ref="$array_name"

    for ((i=0; i<dimension; i++)); do
        local valor="${matriz_ref[$i,$i]}"

        if ! es_igual "$valor" 0; then
            return 1
        fi
    done

    return 0
}

sumar() {
    awk -v a="$1" -v b="$2" 'BEGIN {print a + b}'
}

formatear_numero() {
    local valor="$1"

    if [[ "$valor" == *.* ]]; then
        valor=$(echo "$valor" | sed 's/\.$//')
        valor=$(echo "$valor" | sed 's/\(\.[0-9]*[1-9]\)0*$/\1/')
        valor=$(echo "$valor" | sed 's/\.0*$//')
        valor=$(echo "$valor" | sed 's/^\./0./')
    fi

    echo "$valor"
}

leer_matriz_numerica() {
    local archivo="$1"
    local separador_local="$2"
    local -n matriz_ref=$3
    local -n filas_ref=$4
    local -n columnas_ref=$5

    filas_ref=0
    columnas_ref=0

    while IFS= read -r linea; do
        linea=${linea%$'\r'}
        [[ -z "$linea" ]] && continue

        IFS="$separador_local" read -r -a valores <<< "$linea"

        if [ ${#valores[@]} -eq 0 ]; then
            echo "> Se encontró una fila sin valores" >&2
            return 1
        fi

        if [ "$columnas_ref" -eq 0 ]; then
            columnas_ref=${#valores[@]}
        elif [ ${#valores[@]} -ne "$columnas_ref" ]; then
            echo "> Todas las filas deben tener la misma cantidad de columnas" >&2
            return 1
        fi

        for indice in "${!valores[@]}"; do
            local valor="${valores[$indice]}"

            if ! es_numero "$valor"; then
                echo "> El \`$valor\` presente en la posición [${filas_ref}, ${indice}] no es un número válido" >&2
                return 1
            fi

            matriz_ref[${filas_ref},${indice}]="$valor"
        done

        ((filas_ref++))
    done < "$archivo"

    if [ "$filas_ref" -eq 0 ]; then
        echo "> El archivo de matriz esta vacío" >&2
        return 1
    fi

    return 0
}

dijkstra() {
    local array_name="$1"
    local dimension="$2"
    local -n dist_ref="$3"
    local -n matriz_ref="$array_name"

    for ((i=0; i<dimension; i++)); do
        for ((j=0; j<dimension; j++)); do
            if [ $i -eq $j ]; then
                dist_ref[$i,$j]=0
            elif es_mayor_a_cero "${matriz_ref[$i,$j]}"; then
                dist_ref[$i,$j]="${matriz_ref[$i,$j]}"
            else
                dist_ref[$i,$j]="$INF"
            fi
        done
    done

    for ((k=0; k<dimension; k++)); do
        for ((i=0; i<dimension; i++)); do
            for ((j=0; j<dimension; j++)); do
                local dist_ik="${dist_ref[$i,$k]}"
                local dist_kj="${dist_ref[$k,$j]}"
                local dist_ij="${dist_ref[$i,$j]}"

                if [ "$dist_ik" != "$INF" ] && [ "$dist_kj" != "$INF" ]; then
                    local nueva_dist

                    nueva_dist=$(sumar "$dist_ik" "$dist_kj")

                    if es_menor "$nueva_dist" "$dist_ij"; then
                        dist_ref[$i,$j]="$nueva_dist"
                    fi
                fi
            done
        done
    done
}

contar_conexiones() {
    local array_name="$1"
    local dimension="$2"
    local fila="$3"
    local -n matriz_ref="$array_name"
    local conexiones=0

    for ((j=0; j<dimension; j++)); do
        local valor="${matriz_ref[$fila,$j]:-0}"

        if es_mayor_a_cero "$valor"; then
            ((conexiones++))
        fi
    done

    echo "$conexiones"
}

obtener_hub() {
    local array_name="$1"
    local dimension="$2"
    local -n matriz_ref="$array_name"

    local mejor_estacion=-1
    local max_conexiones=-1

    for ((fila=0; fila<dimension; fila++)); do
        local conexiones
        conexiones=$(contar_conexiones "$array_name" "$dimension" "$fila")
        if [ "$conexiones" -gt "$max_conexiones" ]; then
            max_conexiones=$conexiones
            mejor_estacion=$fila
        fi
    done

    echo "$((mejor_estacion + 1)) $max_conexiones"
}

calcular_tsp() {
    local array_name="$1"
    local dimension="$2"
    local -n dist_ref="$3"
    local -n inicios_ref="$4"
    local -n tiempos_ref="$5"
    local -n rutas_ref="$6"

    declare -A distancias
    dijkstra "$array_name" "$dimension" distancias

    for ((inicio=0; inicio<dimension; inicio++)); do
        declare -a visitados
        local actual=$inicio
        local tiempo_total=0
        local ruta="$((inicio + 1))"

        for ((v=0; v<dimension; v++)); do
            visitados[$v]=false
        done
        visitados[$inicio]=true

        for ((paso=1; paso<dimension; paso++)); do
            local menor_distancia="$INF"
            local siguiente_nodo=-1

            for ((j=0; j<dimension; j++)); do
                if [ "${visitados[$j]}" = false ]; then
                    local dist_actual="${distancias[$actual,$j]}"

                    if es_menor "$dist_actual" "$menor_distancia"; then
                        menor_distancia="$dist_actual"
                        siguiente_nodo=$j
                    fi
                fi
            done

            if [ $siguiente_nodo -eq -1 ]; then
                tiempo_total="$INF"
                break
            fi

            tiempo_total=$(sumar "$tiempo_total" "$menor_distancia")
            visitados[$siguiente_nodo]=true
            ruta="$ruta -> $((siguiente_nodo + 1))"
            actual=$siguiente_nodo
        done

        inicios_ref+=($((inicio + 1)))
        tiempos_ref+=("$tiempo_total")
        rutas_ref+=("$ruta")
    done
}

# Parseo de parámetros
parametros=$(getopt -o "m:ucs:h" --long "matriz:,hub,camino,separador:,help" -- "$@")

if [ $? -ne 0 ]; then
  echo "> No se pudieron analizar las opciones" >&2
  exit 1
fi

eval set -- "$parametros"

while true; do
    case "$1" in
        "-m" | "--matriz")
            matriz="$2"
            shift 2
            ;;
        "-u" | "--hub")
            hub=true
            shift
            ;;
        "-c" | "--camino")
            camino=true
            shift
            ;;
        "-s" | "--separador")
            separador="$2"
            shift 2
            ;;
        "-h" | "--help")
            help=true
            shift 1
            break
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

# Mostrar ayuda
if [ -n "$help" ]; then
  printf "Uso: bash $0 [OPCIONES...]\


  -m, --matriz     ruta al archivo con la matriz de adyacencia\

  -u, --hub        calcula la estación hub de la red\

  -c, --camino     calcula el camino más corto entre estaciones\

  -s, --separador  carácter separador de columnas de la matriz\

  -h, --help       muestra esta lista de ayuda\


Las opciones \`-m\` / \`--matriz\`, \`-u\` / \`--hub\` ó \`-c\` / \`--camino\` y \`-s\` / \`--separador\` son obligatorias.
Las opciones \`-u\` / \`--hub\` y \`-c\` / \`--camino\` no deben declararse juntas.
"
  exit 0
fi

# Validar el parámetro `matriz`
if [ -z "$matriz" ]; then
    echo "> La opción \`-m\` / \`--matriz\` es requerida" >&2
    exit 1
fi

if [ ! -f "$matriz" ]; then
    echo "> La opción \`-m\` / \`--matriz\` debe ser un archivo válido" >&2
    exit 1
fi

# Validar el parámetro `hub` y `camino`
if [ -z "$hub" ] && [ -z "$camino" ]; then
  echo "> Las opciones \`-u\` / \`--hub\` ó \`-c\` / \`--camino\` son requeridas" >&2
  exit 1
fi

if [ -n "$hub" ] && [ -n "$camino" ]; then
  echo "> \`-u\` / \`--hub\` y \`-c\` / \`--camino\` no deben declararse juntas" >&2
  exit 1
fi

# Validar el parámetro `separador`
if [ -z "$separador" ]; then
    echo "> La opción \`-s\` / \`--separador\` es requerida" >&2
    exit 1
fi

if [ ${#separador} -ne 1 ]; then
    echo "> La opción \`-s\` / \`--separador\` debe ser un único carácter" >&2
    exit 1
fi

INF=999999

declare -A matriz_Mapa

filas=0
columnas=0

if ! leer_matriz_numerica "$matriz" "$separador" matriz_Mapa filas columnas; then
    exit 1
fi

if ! es_matriz_cuadrada "$filas" "$columnas"; then
    echo "> La matriz debe ser cuadrada" >&2
    exit 1
fi

if ! tiene_diagonal_con_ceros "matriz_Mapa" "$filas"; then
    echo "> La diagonal principal de la matriz debe contener únicamente ceros" >&2
    exit 1
fi

if ! es_matriz_simetrica "matriz_Mapa" "$filas"; then
    echo "> La matriz debe ser simétrica" >&2
    exit 1
fi

informe_contenido=""

if [ "$hub" = true ]; then
    read -r estacion_hub conexiones_hub <<< "$(obtener_hub "matriz_Mapa" "$filas")"
    informe_contenido="**Hub de la red:** Estación $estacion_hub ($conexiones_hub conexiones)\n"
fi

if [ "$camino" = true ]; then
    declare -a inicios tiempos rutas

    calcular_tsp "matriz_Mapa" "$filas" distancias inicios tiempos rutas

    if [ ${#tiempos[@]} -eq 0 ]; then
        informe_contenido="**Estado:** No es posible visitar todas las estaciones desde ningún punto de partida"
    else
        local_min="${tiempos[0]}"
        for tiempo in "${tiempos[@]}"; do
            if es_menor "$tiempo" "$local_min"; then
                local_min="$tiempo"
            fi
        done

        if [ "$local_min" = "$INF" ]; then
            informe_contenido="**Estado:** No es posible visitar todas las estaciones desde ningún punto de partida"
        else
            local_min_formateado=$(formatear_numero "$local_min")

            declare -a indices_minimos

            for indice in "${!tiempos[@]}"; do
                if es_igual "${tiempos[$indice]}" "$local_min"; then
                    indices_minimos+=("$indice")
                fi
            done

            informe_contenido="**Caminos más cortos visitando todas las estaciones (tiempo: $local_min_formateado minutos):**"
            for idx in "${indices_minimos[@]}"; do
                informe_contenido+=$'\n\n'
                informe_contenido+="**Estación de inicio:** Estación ${inicios[$idx]}"
                informe_contenido+=$'\n'
                informe_contenido+="**Tiempo total:** $local_min_formateado minutos"
                informe_contenido+=$'\n'
                informe_contenido+="**Ruta completa:** ${rutas[$idx]}"
            done
        fi
    fi
fi

# Generar informe
directorio_matriz=$(dirname "$matriz")
nombre_archivo=$(basename "$matriz")
informe="$directorio_matriz/informe.$nombre_archivo"

printf '## Informe de análisis de red de transporte\n\n%s\n' "$informe_contenido" > "$informe"
