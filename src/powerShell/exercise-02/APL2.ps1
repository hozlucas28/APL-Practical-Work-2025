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
    .\APL2.ps1 -matriz "C:\mapa_transporte.txt" -hub -separador "|"
    Analiza la matriz y muestra en el informe la estación hub de la red.
.EXAMPLE
    .\APL2.ps1 -matriz "C:\mapa_transporte.txt" -camino -separador "|"
    Analiza la matriz y muestra el camino más corto para visitar todas las estaciones desde cada punto de partida posible.
#>
Param(
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$matriz,
    
    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "Hub")]
    [switch]$hub,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "Camino")]
    [switch]$camino,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateLength(1, 1)]
    [ValidatePattern(".")]
    [string]$separador
)

# --------------FUNCIONES---------------

function Get-CaminoMasCorto {
    param (
        $matriz
    )
    $n = $matriz.Length
    
    # Inicializar matriz de distancias con Floyd-Warshall
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
    
    # Floyd-Warshall
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
    
    # Calcular para cada punto de inicio usando algoritmo voraz (más rápido)
    $resultados = @()
    
    for ($inicio = 0; $inicio -lt $n; $inicio++) {
        $visitados = @($false) * $n
        $visitados[$inicio] = $true
        $actual = $inicio
        $tiempoTotal = 0
        $ruta = @($inicio + 1)
        
        # Algoritmo voraz: siempre ir al nodo más cercano no visitado
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
            EstacionInicio = $inicio + 1
            TiempoTotal    = $tiempoTotal
            Ruta           = ($ruta -join " -> ")
        }
    }
    
    return $resultados
}

# Obtenemos la estación con más conexiones (hub)
function  Get-Hub {
    param (
        $matriz
    )
    
    $conexionesMax = -1
    $EstacionHub = -1
    $Cont = 1
    foreach ($fila in $matriz) {
        $conexiones = (($fila | Where-Object { $_ -gt 0 } ).Count)
        if ($conexiones -gt $conexionesMax) {
            $conexionesMax = $conexiones
            $EstacionHub = $Cont
        }
        $Cont++
    }
    return @{
        Estacion   = $EstacionHub
        Conexiones = $conexionesMax
    }
}

# Validamos que la matriz sea simétrica
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
    param($matriz)
    $filas = $matriz.Length
    for ($i = 0; $i -lt $filas; $i++) {
        if ($matriz[$i][$i] -ne 0) {
            return $false
        }
    }
    return $true
}

# Validamos que la matriz sea cuadrada
function Check-MatrizCuadrada {
    param (
        $matriz
    )
    write-output "DEBUG: Entrando en Test-MatrizCuadrada"
    $filas = $matriz.Length #obtenemos la cantidad de filas
    foreach ($fila in $matriz) {
        if ($fila.Length -ne $filas) {
            #chequeamos que cada fila tenga la misma cantidad de elementos que filas
            return $false
        }
    }
    return $true
}

# Obtenemos la matriz numérica desde el archivo y validamos que lso valores sean int / double
function Get-MatrizNumerica {
    param (
        $RutaMatriz,
        $delimiter
    )
    Begin {
        try {
            $Lineas = Get-Content -Path $RutaMatriz
        }
        catch {
            write-error "Error al leer el archivo: $_"
            exit 1
        }
        $matrizFinal = @()
    }
    Process {
        foreach ($linea in $Lineas) {
            $valoresFila = @()
            $valores = $linea -split [regex]::Escape($delimiter)
            foreach ($valor in $valores) {
                if ($valor -match '^\d+(\.\d+)?$') {
                    $valoresFila += [double]$valor
                }
                else {
                    write-error "Valor no numérico encontrado: $valor"
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


#Obtenemos la matriz numérica desde el archivo
$matrizNumerica = Get-MatrizNumerica -RutaMatriz $matriz -delimiter $separador

#Validamos que la matriz sea cuadrada y simétrica
$finalExec = Check-MatrizCuadrada -matriz $matrizNumerica
if (-not $finalExec) {
    Write-Error "La matriz no es cuadrada."
    exit 1
}
if (-not (Check-MatrizSimetrica -matriz $matrizNumerica)) {
    Write-Error "La matriz no es simétrica."
    exit 1
}
if (-not (Check-DiagonalConCeros -matriz $matrizNumerica)) {
    Write-Error "La diagonal principal debe contener solo ceros."
    exit 1
}

$InformeRes = "" 

# Generamos el informe según el parámetro usado

# Hub
if ($hub) {
    $hubResult = Get-Hub -matriz $matrizNumerica
    $InformeRes = "**Hub de la red:** Estación $($hubResult.Estacion) ($($hubResult.Conexiones) conexiones)"
}

# Camino
if ($camino) {
    $resultados = Get-CaminoMasCorto -matriz $matrizNumerica
    
    if ($resultados.Count -eq 0) {
        $InformeRes = "**Estado:** No es posible visitar todas las estaciones desde ningún punto de partida"
    }
    else {
        # Encontrar el tiempo mínimo global
        $tiempoMinimo = ($resultados | Measure-Object -Property TiempoTotal -Minimum).Minimum
        
        # Filtrar solo las estaciones que tengan el tiempo mínimo
        $mejoresResultados = $resultados | Where-Object { $_.TiempoTotal -eq $tiempoMinimo }
        
        if ($mejoresResultados.Count -eq 1) {
            $resultado = $mejoresResultados[0]
            $InformeRes = "**Camino más corto visitando todas las estaciones:**`n"
            $InformeRes += "**Estación de inicio:** Estación $($resultado.EstacionInicio)`n"
            $InformeRes += "**Tiempo total:** $($resultado.TiempoTotal) minutos`n"
            $InformeRes += "**Ruta completa:** $($resultado.Ruta)"
        }
        else {
            $InformeRes = "**Caminos más cortos visitando todas las estaciones (tiempo: $tiempoMinimo minutos):**`n"
            foreach ($resultado in $mejoresResultados) {
                $InformeRes += "`n**Estación de inicio:** Estación $($resultado.EstacionInicio)`n"
                $InformeRes += "**Tiempo total:** $($resultado.TiempoTotal) minutos`n"
                $InformeRes += "**Ruta completa:** $($resultado.Ruta)`n"
            }
        }
    }
}

# Generamos el texto final del informe

$textoFinal = @"
## Informe de análisis de red de transporte
$InformeRes
"@

# Generamos el archivo de informe en el mismo directorio que el archivo de matriz
$direccionFinal = (Split-Path -Path $matriz) + "/informe.nombreArchivoEntrada"
Set-Content -Path $direccionFinal -Value $textoFinal

