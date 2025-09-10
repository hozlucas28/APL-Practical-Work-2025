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
    .\script.ps1 -directorio "C:\encuestas\*" -pantalla
    Procesa los archivos en el directorio y muestra el resultado en pantalla como json.
.EXAMPLE
    .\script.ps1 -directorio "C:\encuestas\*" -archivo "C:\salida.json"
    Procesa los archivos y guarda el resultado en el archivo "C:\salida.json".
#>

# Get and validate parameters
Param(
    [Parameter(Mandatory = $True, Position = 1)]
    [string]
    [ValidatePattern('\\\*$')]
    $directorio,

    [Parameter(Mandatory = $True, Position = 2, ParameterSetName = "file")]
    [string]
    [ValidatePattern('\.json$')]
    $archivo,

    [Parameter(Mandatory = $True, Position = 2, ParameterSetName = "display")]
    [switch]
    $pantalla
)

# Fill object grouping by date and channel
$obj = @{}

$filePaths = Get-ChildItem -Path "$directorio" -File -Include "*.txt" | Select-Object FullName

# On each file path
foreach ($filePath in $filePaths) {
    # On each line
    foreach ($line in Get-Content -Path "$($filePath.FullName)") {
        $fields = "$line".Split("|")
        $date = "$($fields[1])".Split(" ")[0]
        $channel = $fields[2]
        $responseTime = $fields[3]
        $score = $fields[4]

        if (-not $obj.ContainsKey("$date")) {
            $obj["$date"] = @{}
        }

        if (-not $obj["$date"].ContainsKey("$channel")) {
            $obj["$date"]["$channel"] = @{
                responseTimeAcc     = $responseTime
                responseTimeCounter = 1
                scoreAcc            = $score
                scoreCounter        = 1
            }
        }
        else {
            $obj["$date"]["$channel"].responseTimeAcc += [double]$responseTime
            $obj["$date"]["$channel"].responseTimeCounter += 1
            $obj["$date"]["$channel"].scoreAcc += [int]$score
            $obj["$date"]["$channel"].scoreCounter += 1
        }
    }
}

foreach ($date in $obj.Keys) {
    foreach ($channel in $obj["$date"].Keys) {
        $obj["$date"]["$channel"].tiempo_respuesta_promedio = $obj["$date"]["$channel"].responseTimeAcc / $obj["$date"]["$channel"].responseTimeCounter
        $obj["$date"]["$channel"].nota_satisfaccion_promedio = $obj["$date"]["$channel"].scoreAcc / $obj["$date"]["$channel"].scoreCounter

        $obj["$date"]["$channel"].Remove("responseTimeAcc")
        $obj["$date"]["$channel"].Remove("responseTimeCounter")
        $obj["$date"]["$channel"].Remove("scoreAcc")
        $obj["$date"]["$channel"].Remove("scoreCounter")
    }
}

$json = $obj | ConvertTo-Json

if ($PSCmdlet.ParameterSetName -eq "file") {
    Set-Content -Path "$archivo" -Value "$json"
}
else {
    Write-Output "$json"
}