<#
.SYNOPSIS
    Ejercicio 5 (PowerShell) — Buscador de información de países.
    Autores: Gonzalo Rodriguez;Lucas Hoz; Luis Choque; Maira Farias; Valentin Massa

.DESCRIPTION
    Consulta REST Countries con caché local por país. TTL por ítem (archivo .meta).
    Permite limpiar la caché y forzar actualización.

.PARAMETER nombre
    Uno o varios países (array) o separados por comas. Cada nombre: solo letras, espacios, apóstrofes y guiones; mínimo 3 letras efectivas.
    Obligatorio salvo uso exclusivo de -clearCache.

.PARAMETER ttl
    TTL de la caché por país en segundos (>0). Obligatorio salvo uso exclusivo de -clearCache.

.PARAMETER forceApi
    Ignora la caché y consulta siempre a la API (actualiza la caché).

.PARAMETER clearCache
    Si se usa solo: limpia la caché y termina.
    Si se usa con parámetros válidos: limpia primero y luego procesa.

.EXAMPLE
    ./ejercicio5.ps1 -n Argentina -t 5
    ./ejercicio5.ps1 -t 15 -n "Uruguay","Costa Rica","France"
    ./ejercicio5.ps1 -n "Brazil","Peru" -t 10 -f
    ./ejercicio5.ps1 -c

.NOTES
    APL 2025 - Virtualización de Hardware
#>

[CmdletBinding()]
param(
    [Alias('n')]
    [Parameter(Mandatory = $false)]
    [string[]]$nombre,

    [Alias('t')]
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$ttl,

    [Alias('f')]
    [Parameter(Mandatory = $false)]
    [switch]$forceApi,

    [Alias('c')]
    [Parameter(Mandatory = $false)]
    [switch]$clearCache
)

# Directorio de caché
function Get-UserCacheDir {
    if ($env:XDG_CACHE_HOME) {
        return $env:XDG_CACHE_HOME 
    }
    if ($IsMacOS) {
        return (Join-Path $HOME "Library/Caches") 
    }
    if ($IsWindows) {
        return (Join-Path $env:LOCALAPPDATA "Cache") 
    }
    return (Join-Path $HOME ".cache")
}

$BaseCache = Get-UserCacheDir
$CacheDir = Join-Path $BaseCache "ej5_cache"
if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir | Out-Null 
}

# Solo -clearCache (limpia y sale) ===
if ($clearCache -and -not $PSBoundParameters.ContainsKey('nombre') -and -not $PSBoundParameters.ContainsKey('ttl') -and -not $forceApi) {
    if (Test-Path $CacheDir) { Remove-Item -Path $CacheDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $CacheDir | Out-Null
    Write-Host ">>> Caché eliminada por completo en $CacheDir"
    exit 0
}

# Validación de obligatorios si no es limpieza exclusiva
if (-not $nombre -or -not $ttl) {
    Write-Host "Error: los parámetros -nombre/-n y -ttl/-t son obligatorios (salvo uso exclusivo de -clearCache/-c)." -ForegroundColor Red
    exit 1
}

# Si clearCache vino con parámetros válidos: limpiar y seguir
if ($clearCache) {
    if (Test-Path $CacheDir) { Remove-Item -Path $CacheDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $CacheDir | Out-Null
    Write-Host ">>> Caché eliminada antes de procesar en $CacheDir"
}

# Validación de países previo a consultar a la API/caché
function Test-PaisValido {
    param([string]$Pais)
    $p = $Pais
    if ($null -ne $p) { $p = $p.Trim() }
    if ([string]::IsNullOrWhiteSpace($p)) {
        Write-Host "Error: se encontró un país vacío en la lista." -ForegroundColor Red
        exit 2
    }
    # Letras unicode + espacios/apóstrofes/guiones
    if ($p -notmatch "^[\p{L}\s'-]+$") {
        Write-Host "Error: '$p' no es un nombre válido (solo letras, espacios, apóstrofes y guiones)." -ForegroundColor Red
        exit 2
    }
    $soloLetras = [regex]::Replace($p, "[^\p{L}]", "")
    if ($soloLetras.Length -lt 3) {
        Write-Host "Error: '$p' no es válido. Debe contener al menos 3 letras." -ForegroundColor Red
        exit 2
    }
    return $p
}

# Validar todos los países y armar lista limpia
$paisesValidos = @()
foreach ($pais in $nombre) {
    $paisesValidos += (Test-PaisValido -Pais $pais)
}

# Lógica por país (caché .json + .meta en epoch)
function Procesar-Pais {
    param([string]$Nombre)

    $nombreSan = ($Nombre -replace '\s', '_')
    $cacheFile = Join-Path $CacheDir ("{0}.json" -f $nombreSan)
    $metaFile = "$cacheFile.meta"

    $response = $null

    if (-not $forceApi -and (Test-Path $cacheFile) -and (Test-Path $metaFile)) {
        try {
            $now = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
            $exp = Get-Content $metaFile -Raw
            if ([int64]::TryParse($exp, [ref]([int64]0))) {
                if ($now -lt [int64]$exp) {
                    Write-Host ">>> Usando caché para: $Nombre"
                    $response = Get-Content $cacheFile -Raw | ConvertFrom-Json
                }
                else {
                    Write-Host ">>> Caché vencida para: $Nombre"
                }
            }
            else {
                Write-Host ">>> Caché inválida para: $Nombre (meta corrupto)."
            }
        }
        catch {
            Write-Host ">>> Caché inválida/corrupta para: $Nombre. Reconsultando API..."
        }
    }

    if ($null -eq $response) {
        if ($forceApi) { Write-Host ">>> Forzando consulta a la API para: $Nombre" }
        else { Write-Host ">>> Consultando API para: $Nombre" }

        try {
            $paisUrl = [uri]::EscapeDataString($Nombre)
            $response = Invoke-RestMethod -Uri "https://restcountries.com/v3.1/name/$paisUrl" -ErrorAction Stop

            # Guardar JSON y meta (epoch)
            ($response | ConvertTo-Json -Depth 5) | Out-File -FilePath $cacheFile -Encoding UTF8
            $expEpoch = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) + $ttl
            $expEpoch | Out-File -FilePath $metaFile -Encoding ASCII
        }
        catch {
            Write-Warning "Error: el país '$Nombre' no fue encontrado en la API."
            return $false
        }
    }

    if (-not $response) { return $false }

    # Salida formateada
    $data = $response[0]
    $pais = $data.name.common
    $capital = $data.capital -join ", "
    $region = $data.region
    $poblacion = $data.population
    $monedas = $data.currencies.PSObject.Properties | ForEach-Object {
        "$($_.Value.name) ($($_.Name))"
    }

    Write-Host ("País: ") $pais
    Write-Host ("Capital: ") $capital
    Write-Host ("Región: ") $region
    Write-Host ("Población: ") $poblacion
    Write-Host ("Moneda: ") ($monedas -join ', ')
    Write-Host ""
    return $true
}

# === Ejecutar y propagar código de salida como en bash ===
$rc = 0
foreach ($p in $paisesValidos) {
    $ok = Procesar-Pais -Nombre $p
    if (-not $ok) { $rc = 3 }
}
exit $rc
