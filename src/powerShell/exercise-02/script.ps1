# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

<#
.SYNOPSIS
    Analiza una matriz de adyacencia de una red de transporte público y genera un informe sobre los hubs y los caminos más cortos entre estaciones.
.DESCRIPTION
    Procesa un archivo de matriz de adyacencia, valida su formato y permite determinar la estación con más conexiones ("hub") o calcular el camino más corto para visitar todas las estaciones desde cada punto de partida posible (Problema del Viajante - TSP). Utiliza Floyd-Warshall para calcular distancias mínimas y muestra la(s) ruta(s) óptima(s). El informe se guarda en un archivo en el mismo directorio que el archivo de entrada.
.FUNCTIONALITY
    Validación de matriz cuadrada y simétrica, manejo de parámetros, cálculo de hubs, cálculo de caminos más cortos, generación de informes.
.INPUTS
    Archivo de texto con la matriz de adyacencia, cada fila separada por un carácter configurable (por defecto "|").
.OUTPUTS
    Archivo de informe en formato texto con el análisis solicitado (hub o camino más corto).
.NOTES
    La matriz debe ser cuadrada y simétrica, con valores numéricos (enteros o decimales). No se puede usar simultáneamente la opción de hub y de camino.
.EXAMPLE
    .\script.ps1 -matriz "C:\mapa_transporte.txt" -hub -separador "|"
    Analiza la matriz y muestra en el informe la estación hub de la red.
.EXAMPLE
    .\script.ps1 -matriz "C:\mapa_transporte.txt" -camino -separador "|"
    Analiza la matriz y muestra el camino más corto para visitar todas las estaciones desde cada punto de partida posible.
#>

Param(
    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $matriz,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "Hub")]
    [switch]
    $hub,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "Camino")]
    [switch]
    $camino,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidatePattern("^.{1}$")]
    [string]
    $separador
)

function Get-CaminoMasCorto {
    param (
        $matriz
    )

    $n = $matriz.Length

    # Inicializar la matriz de distancias con Floyd-Warshall
    $distancias = New-Object 'double[,]' $n, $n

    for ($i = 0; $i -lt $n; $i++) {
        for ($j = 0; $j -lt $n; $j++) {
            if ($i -eq $j) {
                $distancias[$i, $j] = 0
            }
            elseif ($matriz[$i][$j] -gt 0) {
                $distancias[$i, $j] = $matriz[$i][$j]
            }
            else {
                $distancias[$i, $j] = [double]::MaxValue
            }
        }
    }

    # Realizar algoritmo de Floyd-Warshall
    for ($k = 0; $k -lt $n; $k++) {
        for ($i = 0; $i -lt $n; $i++) {
            for ($j = 0; $j -lt $n; $j++) {
                if ($distancias[$i, $k] -ne [double]::MaxValue -and
                    $distancias[$k, $j] -ne [double]::MaxValue -and
                    $distancias[$i, $k] + $distancias[$k, $j] -lt $distancias[$i, $j]) {
                    $distancias[$i, $j] = $distancias[$i, $k] + $distancias[$k, $j]
                }
            }
        }
    }

    # Por cada punto de inicio, calcular el camino más corto utilizando el algoritmo voraz
    $resultados = @()

    for ($inicio = 0; $inicio -lt $n; $inicio++) {
        $visitados = @($false) * $n
        $visitados[$inicio] = $true
        $actual = $inicio
        $tiempoTotal = 0
        $ruta = @($inicio + 1)

        # Algoritmo voraz: "Siempre ir al nodo más cercano no visitado"
        for ($paso = 1; $paso -lt $n; $paso++) {
            $menorDistancia = [double]::MaxValue
            $siguienteNodo = -1

            # Buscar el nodo más cercano no visitado
            for ($j = 0; $j -lt $n; $j++) {
                if (-not $visitados[$j] -and $distancias[$actual, $j] -lt $menorDistancia) {
                    $menorDistancia = $distancias[$actual, $j]
                    $siguienteNodo = $j
                }
            }

            # Si no hay nodo alcanzable, marcar como infinito
            if ($siguienteNodo -eq -1) {
                $tiempoTotal = [double]::MaxValue
                break
            }

            # Moverse al siguiente nodo
            $tiempoTotal += $menorDistancia
            $visitados[$siguienteNodo] = $true
            $ruta += ($siguienteNodo + 1)
            $actual = $siguienteNodo
        }

        # Guardar resultado para este punto de inicio
        $resultados += [PSCustomObject]@{
            estacionInicio = $inicio + 1
            tiempoTotal    = $tiempoTotal
            ruta           = ($ruta -join " -> ")
        }
    }

    return $resultados
}

# Obtiene la estación con más conexiones (Hub)
function Get-Hub {
    param (
        $matriz
    )

    $conexionesMax = -1
    $estacionHub = -1
    $cont = 1

    foreach ($fila in $matriz) {
        $conexiones = (($fila | Where-Object { $_ -gt 0 } ).Count)

        if ($conexiones -gt $conexionesMax) {
            $conexionesMax = $conexiones
            $estacionHub = $cont
        }

        $cont++
    }

    return @{
        estacion   = $estacionHub
        conexiones = $conexionesMax
    }
}

function Check-MatrizSimetrica {
    param (
        $matriz
    )

    $filas = $matriz.Length

    for ($i = 0; $i -lt $filas; $i++) {
        for ($j = 0; $j -lt $filas; $j++) {
            if ($matriz[$i][$j] -ne $matriz[$j][$i]) {
                return $false
            }
        }
    }

    return $true
}

function Check-DiagonalConCeros {
    param(
        $matriz
    )

    $filas = $matriz.Length

    for ($i = 0; $i -lt $filas; $i++) {
        if ($matriz[$i][$i] -ne 0) {
            return $false
        }
    }

    return $true
}

function Check-MatrizCuadrada {
    param (
        $matriz
    )

    $filas = $matriz.Length

    foreach ($fila in $matriz) {
        # Si la fila no tiene la misma cantidad de elementos que el numero de filas. no es cuadrada
        if ($fila.Length -ne $filas) {
            return $false
        }
    }

    return $true
}

# Obtiene la matriz desde el archivo y valida que sus elementos sean `integers` ó `doubles`
function Get-MatrizNumerica {
    param (
        $rutaMatriz,
        $delimiter
    )

    Begin {
        try {
            $lineas = Get-Content -Path $rutaMatriz
        }
        catch {
            Write-error "> Ocurrió un error al leer el archivo ``$rutaMatriz``"
            exit 1
        }

        $matrizFinal = @()
    }

    Process {
        foreach ($linea in $lineas) {
            $valoresFila = @()
            $valores = $linea -split [regex]::Escape($delimiter)

            foreach ($valor in $valores) {
                if ($valor -match '^\d+(\.\d+)?$') {
                    $valoresFila += [double]$valor
                }
                else {
                    Write-error "> El valor numérico ``$valor`` no se ha encontrado"
                    exit 1
                }
            }

            $matrizFinal += , $valoresFila
        }
    }

    End {
        return $matrizFinal
    }
}

# Obtener la matriz
$matrizNumerica = Get-MatrizNumerica -RutaMatriz $matriz -delimiter $separador

# Validar la matriz
if (-not (Check-MatrizCuadrada -matriz $matrizNumerica)) {
    Write-Error "> La matriz no es cuadrada"
    exit 1
}

if (-not (Check-MatrizSimetrica -matriz $matrizNumerica)) {
    Write-Error "> La matriz no es simétrica"
    exit 1
}

if (-not (Check-DiagonalConCeros -matriz $matrizNumerica)) {
    Write-Error "> La diagonal principal debe contener solo ceros"
    exit 1
}

$informeContenido = ""

# Generar informe

# Hub
if ($hub) {
    $hubResult = Get-Hub -matriz $matrizNumerica
    $informeContenido = "**Hub de la red:** Estación $($hubResult.estacion) ($($hubResult.conexiones) conexiones)"
}

# Camino
if ($camino) {
    $resultados = Get-CaminoMasCorto -matriz $matrizNumerica

    if ($resultados.Count -eq 0) {
        $informeContenido = "**Estado:** No es posible visitar todas las estaciones desde ningún punto de partida"
    }
    else {
        # Encontrar el menor tiempo
        $tiempoMinimo = ($resultados | Measure-Object -Property tiempoTotal -Minimum).Minimum

        # Filtrar solo las estaciones que tengan el menor tiempo
        $mejoresResultados = $resultados | Where-Object { $_.tiempoTotal -eq $tiempoMinimo }

        if ($mejoresResultados.Count -eq 1) {
            $informeContenido = "**Camino más corto visitando todas las estaciones:**`n"
        }
        else {
            $informeContenido = "**Caminos más cortos visitando todas las estaciones (tiempo: $tiempoMinimo minutos):**`n"
        }

        foreach ($resultado in $mejoresResultados) {
            $informeContenido += "`n**Estación de inicio:** Estación $($resultado.estacionInicio)`n"
            $informeContenido += "**Tiempo total:** $($resultado.tiempoTotal) minutos`n"
            $informeContenido += "**ruta completa:** $($resultado.ruta)`n"
        }
    }
}

$textoFinal = @"
## Informe de análisis de red de transporte

$informeContenido
"@

$nombreArchivoMatriz = [System.IO.Path]::GetFileNameWithoutExtension($matriz)
$informe = (Split-Path -Path $matriz) + "/informe.$nombreArchivoMatriz.txt"

Set-Content -Path $informe -Value $textoFinal

