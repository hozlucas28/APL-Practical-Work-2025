
# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

<#
.SYNOPSIS
Demonio para auditar un repositorio Git en busca de patrones sensibles.

.PARAMETER repo
Ruta del repositorio Git a monitorear (relativa o absoluta).

.PARAMETER conf
Archivo de configuración con patrones a buscar.

.PARAMETER log
Archivo donde se registran las alertas. Por defecto: ./alertas.log

.PARAMETER alerta
Intervalo de escaneo en segundos. Por defecto: 10

.PARAMETER kill
Detiene el demonio en ejecución.
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$repo,

    [Parameter(Mandatory=$false)]
    [string]$conf,

    [string]$log = "./alertas.log",
    [int]$alerta = 10,
    [switch]$kill
)

# Funciones 
function Limpiar-Temporales {
    param($pidFile)
    if (Test-Path $pidFile) { Remove-Item $pidFile -ErrorAction SilentlyContinue }
}

function Mostrar-Error {
    param($mensaje, $pidFile)
    Write-Host "ERROR: $mensaje" -ForegroundColor Red
    Limpiar-Temporales $pidFile
    exit 1
}

# Validacion para kill
if ($kill -and -not $repo) {
    $repo = "."  # Default repo para kill si no se pasa
}

# Generar nombre de Job y archivo PID únicos por repo
try {
    $repoPath = Resolve-Path $repo
} catch {
    Mostrar-Error "La ruta de repo '$repo' no existe"
}

$jobName = "auditJob_$($repoPath.Path.GetHashCode())"
$pidFile = "$env:TEMP\audit_$($jobName).pid"

# Kill
if ($kill) {
    $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
    if ($job) {
        Stop-Job -Job $job
        Remove-Job -Job $job
        Limpiar-Temporales $pidFile
        Write-Host "Demonio detenido correctamente"
    } else {
        Write-Host "No hay demonio en ejecución para este repositorio."
    }
    exit 0
}

# Validaciones restantes entrada
if (-not $repo) { Mostrar-Error "Debe especificar el parámetro -repo." $pidFile }
if (-not $conf) { Mostrar-Error "Debe especificar el parámetro -conf." $pidFile }

try {
    $confPath = Resolve-Path $conf
} catch {
    Mostrar-Error "El archivo de configuración '$conf' no existe." $pidFile
}

# Manejo de log
if (-not [System.IO.Path]::IsPathRooted($log)) {
    $log = Join-Path $repoPath $log
}

if (-not (Test-Path $log)) {
    New-Item -ItemType File -Path $log -Force | Out-Null
}

$logPath = Resolve-Path $log

# Revisar si ya hay un Job corriendo
if (Get-Job -Name $jobName -ErrorAction SilentlyContinue) {
    Mostrar-Error "Ya hay un demonio en ejecución para este repositorio." $pidFile
}

# SCRIPT DEL DEMONIO 
$ScriptBlock = {
    param($repoPath, $confPath, $logPath, $interval)

    $excluir = @((Split-Path $logPath -Leaf))
    $lastCommit = git -C $repoPath rev-parse HEAD

    while ($true) {
        try {
            $newCommit = git -C $repoPath rev-parse HEAD
            if ($newCommit -ne $lastCommit) {
                $files = git -C $repoPath diff --name-only $lastCommit $newCommit
                $lastCommit = $newCommit

                $patterns = Get-Content $confPath
                foreach ($file in $files) {
                    if ($excluir -contains (Split-Path $file -Leaf)) { continue }
                    $filePath = Join-Path $repoPath $file
                    if (-not (Test-Path $filePath)) { continue }

                    foreach ($pattern in $patterns) {
                        if (Select-String -Path $filePath -Pattern $pattern -SimpleMatch -Quiet) {
                            $mensaje = "{0} ALERTA: Patrón '$pattern' encontrado en '$filePath'" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                            Add-Content -Path $logPath -Value $mensaje
                        }
                    }
                }
            }
        } catch {
            $errorMsg = "{0} ERROR al escanear repositorio: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $_.Exception.Message
            Add-Content -Path $logPath -Value $errorMsg
        }
        Start-Sleep -Seconds $interval
    }
}

# INICIAR JOB 
$job = Start-Job -Name $jobName -ScriptBlock $ScriptBlock -ArgumentList $repoPath, $confPath, $logPath, $alerta
Set-Content -Path $pidFile -Value $job.Id
Write-Host "Demonio iniciado en segundo plano (JobId $($job.Id))."
