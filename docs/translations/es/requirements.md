# Requisitos del trabajo práctico

## Condiciones de entrega

-   Se debe entregar por plataforma MIeL un archivo con formato `.zip` o `.tar` (no se aceptan `.rar` u otros formatos de compresión/empaquetamiento de archivos), conteniendo la caratula que se publica en MIeL junto con los archivos de la resolución del trabajo.
-   Se debe entregar el código fuente de cada uno de los ejercicios resueltos tanto en Bash como en Powershell. Si un ejercicio se resuelve en un único lenguaje se lo considerará incompleto y, por lo tanto, desaprobado.
-   Se deben entregar lotes de prueba válidos para los ejercicios que reciban archivos o directorios como parámetro.
-   Los archivos de código deben tener un encabezado en el que se listen los integrantes del grupo.
-   Los archivos con el código de cada ejercicio y sus lotes de prueba se deben ubicar en un directorio con la siguiente estructura:
    -   APL/
        -   bash/
            -   ejercicio1
            -   ejercicio2
            -   ejercicio3
            -   ejercicio4
            -   ejercicio5
        -   powershell/
            -   ejercicio1
            -   ejercicio2
            -   ejercicio3
            -   ejercicio4
            -   ejercicio5

## Criterios de corrección y evaluación generales para todos los ejercicios

-   Los scripts de Bash muestran una ayuda con los parámetros `-h` y `--help`. Deben permitir el ingreso de parámetros en cualquier orden, y no por un orden fijo.
-   Los scripts de Powershell deben mostrar una ayuda con el comando `Get-Help`. Ej: `Get-Help ./ejercicio1.ps1`. Deben realizar la validación de parámetros en la sección params utilizando la funcionalidad nativa de Powershell.
-   Cuando haya parámetros que reciban rutas de directorios o archivos se deben aceptar tanto rutas relativas como absolutas o que contengan espacios.
-   No se debe permitir la ejecución del script si al menos un parámetro obligatorio no está presente.
-   Si algún comando utilizado en el script da error, este se debe manejar correctamente: detener la ejecución del script (o salvar el error en caso de ser posible) y mostrar un mensaje informando el problema de una manera amigable con el usuario, pensando que el usuario no tiene conocimientos informáticos.
-   Si se generan archivos temporales de trabajo se deben crear en el directorio temporal `/tmp`; y se deben eliminar al finalizar el script, tanto en forma exitosa como por error, para no dejar archivos basura. (Ver `trap` en Bash / `try-catch-finally` en PowerShell)
-   Deseable:
    -   Utilización de funciones en el código para resolver los ejercicios.

## Ejercicios

1. [Análisis de resultados de encuestas de satisfacción de clientes](./exercises/exercise-01.md)
2. [Análisis de rutas en un mapa de transporte](./exercises/exercise-02.md)
3. [Conteo de eventos en logs de sistemas](./exercises/exercise-03.md)
4. [Análisis de seguridad de código en repositorios Git](./exercises/exercise-04.md)
5. [Buscador de información de países](./exercises/exercise-05.md)
