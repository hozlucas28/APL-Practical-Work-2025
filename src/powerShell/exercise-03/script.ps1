# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

<#
.SYNOPSIS
    Cuenta ocurrencias de palabras clave en archivos `.log` dentro de un directorio.

.DESCRIPTION
    Analiza todos los archivos con extensión `.log` en un directorio especificado y cuenta cuántas veces aparecen las palabras clave indicadas, sin distinguir mayúsculas/minúsculas.

.FUNCTIONALITY
    - Busca archivos `.log` en el directorio dado.
    - Cuenta ocurrencias de cada palabra clave en todos los archivos.
    - Muestra el resultado por palabra clave.

.INPUTS
    -directorio: Ruta del directorio de logs a analizar.
    -palabras: Array de palabras clave a contabilizar.

.OUTPUTS
    Muestra por consola la cantidad de ocurrencias de cada palabra clave.

.NOTES
    Las búsquedas son case-insensitive. Las palabras clave se pasan como array.

.EXAMPLE
    .\script.ps1 -directorio "C:\logs" -palabras "USB","Invalid"
    USB : 2
    Invalid : 2
#>

param(
    [Parameter(Mandatory=$true, Position = 1)]
    [string]
    $directorio,

    [Parameter(Mandatory=$true, Position = 2)]
    [string[]]
    $palabras
)

# Validaciones
if (-not (Test-Path $directorio)) {
    Write-Error "> El directorio ``$directorio`` no existe."
    exit 1
}

# Inicializar contador
$conteo = @{}
foreach ($k in $palabras) {
    $conteo[$k] = 0
}

# Procesar archivos .log
Get-ChildItem -Path $directorio -Filter *.log | ForEach-Object {
    $archivo = $_.FullName
    $lineas = Get-Content $archivo

    foreach ($linea in $lineas) {
        foreach ($k in $palabras) {
            $matches = [regex]::Matches($linea, $k, "IgnoreCase")
            $conteo[$k] += $matches.Count
        }
    }
}

# Imprimir resultados por pantalla
foreach ($k in $palabras) {
    $valor = $conteo[$k]
    Write-Output "$k : $valor"
}
