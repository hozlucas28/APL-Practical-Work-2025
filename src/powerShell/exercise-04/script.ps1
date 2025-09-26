# Autores: Choque Luis, Farias Maira Soledad, Hoz Lucas, Massa Valentin y Rodriguez Gonzalo Leonel.

<#
.SYNOPSIS
    Script demonio para monitorear repositorios Git y detectar patrones sensibles en archivos modificados.

.DESCRIPTION
    Este script se ejecuta como un proceso demonio en segundo plano para monitorear un repositorio Git.
    Detecta credenciales o datos sensibles subidos por error al repositorio, basándose en patrones
    definidos en un archivo de configuración. Registra alertas en un archivo de log cuando se encuentran coincidencias.

.FUNCTIONALITY
    - Monitorea cambios en la rama principal de un repositorio Git.
    - Escanea archivos modificados en busca de patrones sensibles.
    - Registra alertas en un archivo de log con detalles del patrón y archivo afectados.
    - Permite detener el demonio con un flag.

.INPUTS
    -repo: Ruta del repositorio Git a monitorear.
    -configuracion: Ruta del archivo de configuración que contiene la lista de patrones a buscar.
    -log: Ruta del archivo de logs donde se registrarán las alertas.
    -kill: Flag para detener el demonio en ejecución para el repositorio especificado.

.OUTPUTS
    Archivo de log con las alertas generadas.

.NOTES
    - Solo se permite un demonio en ejecución por repositorio.
    - Asegúrese de que el repositorio Git y el archivo de configuración existan antes de ejecutar el script.
    - Las opciones `-r` / `--repo`, `-c` / `--configuracion` y `-l` / `--log` son obligatorias. Si se define la opción `-k` / `--kill`, únicamente la opción `-r` / `--repo` es obligatoria.

.EXAMPLE
    ./script.ps1 -repo /home/user/myrepo -configuracion ./patrones.conf
    Inicia el demonio para monitorear el repositorio `/home/user/myrepo` con los patrones definidos en `./patrones.conf`.

.EXAMPLE
    ./script.ps1 -repo /home/user/myrepo -kill
    Detiene el demonio en ejecución para el repositorio `/home/user/myrepo`.
#>

param (
    [Parameter(Mandatory = $True, Position = 1)]
    [string]
    $repo,

    [Parameter(Mandatory = $True, Position = 2, ParameterSetName = "Create daemon process")]
    [ValidatePattern('.conf$')]
    [string]
    $configuracion,

    [Parameter(Mandatory = $True, Position = 3, ParameterSetName = "Create daemon process")]
    [string]
    $log,

    [Parameter(Mandatory = $True, Position = 2, ParameterSetName = "Kill daemon process")]
    [switch]
    $kill
)

function limpiarArchivosTemporales {
    param(
        [string]
        $jobIDFile
    )

    if (Test-Path $jobIDFile) {
        Remove-Item $jobIDFile -ErrorAction SilentlyContinue
    }
}

function imprimirError {
    param(
        [string]
        $mensaje,

        [string]
        $jobIDFile
    )

    Write-Output "$mensaje" -ForegroundColor Red
    limpiarArchivosTemporales $jobIDFile

    exit 1
}

# Generar el nombre del Job y archivo Job ID únicos por repositorio
try {
    $repoPath = Resolve-Path $repo

    $jobName = "auditJob_$($repoPath.Path.GetHashCode())"
    $jobIDFile = "$env:TEMP\audit_$($jobName).jobid"
}
catch {
    imprimirError "> La ruta al repositorio ``$repoPath`` no existe"
}

# Eliminar proceso demonio del repositorio
if ($kill) {
    $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue

    if ($job) {
        Stop-Job -Job $job
        Remove-Job -Job $job
        limpiarArchivosTemporales $jobIDFile

        Write-Output "> Proceso demonio detenido (Job ID $($job.Id))"
    }
    else {
        Write-Output "> No hay un proceso demonio ejecutandose en el repositorio ``$repoPath``"
    }

    exit 0
}

# Revisar si ya hay un Job ejecutándose en el repositorio
if (Get-Job -Name $jobName -ErrorAction SilentlyContinue) {
    imprimirError "> Ya hay un proceso demonio ejecutandose en el repositorio ``$repoPath``" $jobIDFile
}

# Obtener ruta del archivo de configuración
try {
    $confPath = Resolve-Path $configuracion
}
catch {
    imprimirError "> El archivo de configuracion ``$configuracion`` no existe" $jobIDFile
}

# Crear y obtener la ruta al archivo de logs
if (-not (Test-Path $log)) {
    New-Item -ItemType File -Path $log -Force | Out-Null
}

$logPath = Resolve-Path $log

# Script para ejecutar un proceso demonio en el repositorio
$ScriptBlock = {
    param($repoPath, $confPath, $logPath)

    $excluir = @((Split-Path $logPath -Leaf))
    $lastCommit = git -C $repoPath rev-parse HEAD

    while ($true) {
        try {
            $newCommit = git -C $repoPath rev-parse HEAD

            if ($newCommit -ne $lastCommit) {
                $files = git -C $repoPath diff --name-only $lastCommit $newCommit
                $patterns = Get-Content $confPath
                $lastCommit = $newCommit

                foreach ($file in $files) {
                    if ($excluir -contains (Split-Path $file -Leaf)) {
                        continue
                    }

                    $filePath = Join-Path $repoPath $file

                    foreach ($pattern in $patterns) {
                        # Eliminar el prefijo 'regex:'
                        $pattern = $pattern -replace '^regex:', ''

                        if (Select-String -Path $filePath -Pattern $pattern -Quiet) {
                            $mensaje = "{0} Alerta: patrón '$pattern' encontrado en el archivo '$filePath'." -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                            Add-Content -Path $logPath -Value $mensaje
                        }
                    }
                }
            }
        }
        catch {
            $errorMsg = "{0} Error (escaneo del repositorio): {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $_.Exception.Message
            Add-Content -Path $logPath -Value $errorMsg
        }

        Start-Sleep -Seconds 1
    }
}

# Ejecutar proceso demonio en background y guardar su Job ID
$job = Start-Job -Name $jobName -ScriptBlock $ScriptBlock -ArgumentList $repoPath, $confPath, $logPath

Set-Content -Path $jobIDFile -Value $job.Id
Write-Output "> Proceso demonio ejecutandose en segundo plano (Job ID $($job.Id))"
