# Análisis de seguridad de código en repositorios Git

> Objetivos de aprendizaje: procesos demonios, manejo de archivos de configuración, búsqueda y reemplazo de texto.

[(solución en Bash)](../../../../src/bash/exercise-04/) [(solución en PowerShell)](../../../../src/powerShell/exercise-04/) [(versión en inglés)](../../../../src/bash/exercise-04/README.md)

Se necesita un script demonio para monitorear un repositorio [Git](https://git-scm.com/) y detectar credenciales o datos sensibles que se hayan subido por error. El demonio debe leer un archivo de configuración que contiene una lista de palabras clave o [patrones regex](https://developer.mozilla.org/es/docs/Web/JavaScript/Guide/Regular_expressions) a buscar (por ejemplo, `password`, `API_KEY`, `API_KEY = `). Cada vez que se detecte una nueva modificación en la rama principal del repositorio, el demonio debe escanear los archivos modificados. Si encuentra alguna coincidencia, debe registrar una alerta en un archivo de log con el nombre del archivo, el patrón encontrado y la fecha. El script debe ejecutarse en segundo plano, liberando la terminal.

## Ejemplo de entrada del demonio

```plaintext
$ ./audit.sh -r /home/user/myrepo -c ./patrones.conf -a 10
> ./audit.ps1 -repo /home/user/myrepo -configuracion ./patrones.conf -alerta 10
```

## Ejemplo de archivo de configuración (`patrones.conf`)

```plaintext
password
API_KEY
secret
regex:^.*API_KEY\s*=\s*['"].*['"].*$
```

## Ejemplo de salida en el archivo de log

```plaintext
[2025-08-23 11:30:00] Alerta: patrón 'API_KEY' encontrado en el archivo 'config.js'.
```

## Parámetros

| Parámetro bash           | Parámetro PowerShell | Descripción                                                                                                           |
| :----------------------- | :------------------- | :-------------------------------------------------------------------------------------------------------------------- |
| `-r` / `--repo`          | `-repo`              | Ruta del repositorio Git a monitorear.                                                                                |
| `-c` / `--configuracion` | `-configuracion`     | Ruta del archivo de configuración que contiene la lista de patrones a buscar.                                         |
| `-l` / `--log`           | `-log`               | Ruta del archivo de logs que contiene la lista de eventos identificados.                                              |
| `-k` / `--kill`          | `-kill`              | Flag para detener el demonio. Solo se usa junto con `-r` / `-repo` y debe validar que exista un demonio en ejecución. |

## Consideraciones

1. La solución debe ser un único script que pueda ser ejecutado y detenido posteriormente.
2. No se puede ejecutar más de un proceso demonio para el mismo repositorio.
3. El monitoreo debe ser activado por los cambios identificados en los archivos del directorio.
4. La lista de patrones a buscar debe ser configurable en un archivo externo.
5. El script debe poder ser detenido con un flag.
