# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

<#
.SYNOPSIS
    Script para consultar información de países utilizando una API pública.

.DESCRIPTION
    Este script permite buscar información de países por nombre utilizando la API de REST Countries.
    Los resultados obtenidos se guardan en un archivo de Cache para evitar consultas repetidas a la API.

.INPUTS
    -nombre: Array con los nombres de los países a buscar.
    -ttl: Tiempo en segundos para mantener los resultados en Cache.

.OUTPUTS
    Información detallada de cada país encontrado:

    - País
    - Capital
    - Región
    - Población
    - Moneda

.NOTES
    - La API utilizada es REST Countries: https://restcountries.com/.

.EXAMPLE
    ./script.ps1 -nombre "Spain", "France" -ttl 3600
    Consulta información de los países "Spain" y "France", almacenando los resultados en Cache por 3600 segundos.
#>

param(
    [Parameter(Mandatory = $True, Position = 1)]
    [string[]]
    $nombre,

    [Parameter(Mandatory = $True, Position = 2)]
    [int]
    $ttl
)

function Get-CacheDir {
    if ($env:XDG_CACHE_HOME) {
        return $env:XDG_CACHE_HOME
    }
    elseif ($IsMacOS) {
        return (Join-Path $HOME "Library/Caches")
    }
    elseif ($IsWindows) {
        return (Join-Path $env:LOCALAPPDATA "Cache")
    }

    return (Join-Path $HOME ".cache")
}

# Crear/Obtener directorio de caches
$baseCache = Get-CacheDir
$cacheDir = Join-Path $baseCache "hv-exercise-05"

if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir | Out-Null
}

function Get-Country {
    param(
        [string]
        $nombre,

        [string]
        $cacheDir
    )

    $data = @{}

    $nombreSan = ($nombre -replace '\s', '_')
    $cacheFile = Join-Path $cacheDir ("{0}.json" -f $nombreSan)
    $expirationFile = Join-Path $cacheDir ("{0}.exp" -f $nombreSan)

    # Si existe una cache para el país, obtener los datos guardados
    if ((Test-Path $cacheFile) -and (Test-Path $expirationFile)) {
        $now = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
        $exp = [int64](Get-Content $expirationFile -Raw)

        if ($now -lt $exp) {
            $data = Get-Content $cacheFile -Raw | ConvertFrom-Json
        }
    }

    # Si no existe una cache para el país ó ha expirado, consultar la API
    if ($data.Count -eq 0) {
        try {
            $paisEscaped = [uri]::EscapeDataString($nombre)
            $apiEndpoint = "https://restcountries.com/v3.1/name/$paisEscaped`?fullText=true&fields=name,currencies,capital,region,population"
            $response = Invoke-RestMethod -Uri "$apiEndpoint" -ErrorAction Stop

            # Guardar datos
            $data["name"] = $response[0].name.official
            $data["capital"] = $response[0].capital
            $data["region"] = $response[0].region
            $data["population"] = $response[0].population

            $data["currency"] = @()
            foreach ($currencyAcronym in $response[0].currencies.PSObject.Properties.Name) {
                $currencyName = $response[0].currencies.$currencyAcronym.name
                $data["currency"] += "$currencyName ($currencyAcronym)"
            }

            $data | ConvertTo-Json | Out-File -FilePath $cacheFile -Encoding UTF8

            # Guardar la expiración de los datos
            $expEpoch = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) + $ttl
            $expEpoch | Out-File -FilePath $expirationFile -Encoding ASCII
        }
        catch {
        }
    }

    return $data
}

# Obtener los datos de cada país
foreach ($pais in $nombre) {
    $data = Get-Country "$pais" "$cacheDir"

    Write-Output ""

    if ($data.Count -ne 0) {
        Write-Output "Pais: $($data.name)"
        Write-Output "Capital: $($data.capital -join ", ")"
        Write-Output "Region: $($data.region)"
        Write-Output "Poblacion: $($data.population)"
        Write-Output "Moneda: $($data.currency -join ", ")"
    }
    else {
        Write-Error "No se ha podido consultar el pais ``$pais`` a la API"
    }
}
