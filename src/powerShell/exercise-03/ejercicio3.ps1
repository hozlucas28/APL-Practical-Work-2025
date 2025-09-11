<#
.Autores
 Gonzalo Rodriguez;Lucas Hoz; Luis Choque; Maira Farias; Valentin Massa
.SYNOPSIS
  Script para contar ocurrencias de palabras clave en archivos .log
.DESCRIPTION
  Analiza todos los archivos con extensión .log en un directorio
  y cuenta cuántas veces aparecen las palabras clave (case-insensitive).
.PARAMETER directorio
  Ruta del directorio con archivos .log
.PARAMETER palabras
  Array de palabras clave a buscar (ej: "usb","invalid")
.EXAMPLE
  ./ejercicio3.ps1 -directorio "./logs" -palabras "usb","invalid"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$directorio,

    [Parameter(Mandatory=$true)]
    [string[]]$palabras
)

# Validaciones
if (-not (Test-Path $directorio)) {
    Write-Error "El directorio '$directorio' no existe."
    exit 1
}

# Inicializar contador
$conteo = @{}
foreach ($p in $palabras) {
    $conteo[$p] = 0
}

# Procesar archivos .log
Get-ChildItem -Path $directorio -Filter *.log | ForEach-Object {
    $archivo = $_.FullName
    $lineas = Get-Content $archivo

    foreach ($linea in $lineas) {
        foreach ($p in $palabras) {
            $matches = [regex]::Matches($linea, $p, "IgnoreCase")
            $conteo[$p] += $matches.Count
        }
    }
}

# Mostrar resultados
foreach ($p in $palabras) {
    $valor = $conteo[$p]
    Write-Output "$p : $valor"
}
