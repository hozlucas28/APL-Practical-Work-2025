<#
.SYNOPSIS
    Analiza archivos de encuestas de satisfacción de clientes y genera estadísticas por canal y día.
.DESCRIPTION
    Procesa todos los archivos de encuestas en un directorio, calcula el tiempo de respuesta promedio y la nota de satisfacción promedio por canal de atención y por día. El resultado puede imprimirse en pantalla o guardarse en un archivo JSON.
.FUNCTIONALITY
    Manejo de archivos de texto, procesamiento de datos tabulares, manejo de parámetros y salida por pantalla o archivo.
.INPUTS
    Archivos de texto con encuestas, cada línea con formato: ID_ENCUESTA|FECHA|CANAL|TIEMPO_RESPUESTA|NOTA_SATISFACCIÓN
.OUTPUTS
    Archivo JSON o impresión en pantalla con estadísticas agrupadas por día y canal.
.NOTES
    Los registros pueden tener fechas distintas al nombre del archivo. No se puede usar simultáneamente la salida por pantalla y por archivo.
.EXAMPLE
    .\script.ps1 -directorio "C:\encuestas" -pantalla
    Procesa los archivos en el directorio y muestra el resultado en pantalla como json.
.EXAMPLE
    .\script.ps1 -directorio "C:\encuestas" -archivo "C:\salida.json"
    Procesa los archivos y guarda el resultado en el archivo "C:\salida.json".
#>

Param(
  [Parameter(Mandatory = $true, Position = 1)]
  [string]
  $directorio,  
  
  [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "Window")]
  [switch]
  $pantalla,

  [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "File")]
  [ValidatePattern('.json$')]
  [String]
  $archivo
)

$headers = @("ID_ENCUESTA", "FECHA", "CANAL", "TIEMPO_RESPUESTA", "NOTA_SATISFACCION")

$csvAgrup = Get-Content $directorio\*.txt | ConvertFrom-Csv -Delimiter "|" -Header $headers 

$grouped = $csvAgrup | Group-Object -Property { ($_.FECHA).Substring(0, 10) }

$jsonresultado = @{}

foreach ( $date in $grouped) {
  $jsonresultado[$date.Name] = @{}

  $canales = $date.Group | Group-Object -Property CANAL
  foreach ( $canal in $canales) {
    $TiemportaProm = ($canal.Group | Measure-Object -Property TIEMPO_RESPUESTA -Average).Average
    $NotaSatis = ($canal.Group | Measure-Object -Property NOTA_SATISFACCION -Average).Average

    $jsonresultado[$date.Name][$canal.Name] = @{
      tiempo_respuesta_promedio  = [math]::Round($TiemportaProm, 2)
      nota_satisfaccion_promedio = [math]::Round($NotaSatis, 2)
    }
  }
}

if ($archivo) {
  $jsonresultado | ConvertTo-Json | Set-Content $archivo
}
else {
  $jsonresultado | ConvertTo-Json | Write-Output 
}
