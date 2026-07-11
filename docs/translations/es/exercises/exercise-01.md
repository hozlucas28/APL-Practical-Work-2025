# Análisis de resultados de encuestas de satisfacción de clientes

> Objetivos de aprendizaje: manejo de archivos de texto, procesamiento de datos tabulares, manejo de parámetros y salida por pantalla.

[(solución en Bash)](../../../../src/bash/exercise-01/) [(solución en PowerShell)](../../../../src/powerShell/exercise-01/) [(versión en inglés)](../../../../src/bash/exercise-01/README.md)

Se requiere un script para analizar los resultados de encuestas de satisfacción de clientes de un servicio de atención al cliente. Los datos se registran diariamente en archivos de texto, con cada encuesta en una línea.

El archivo de registro tiene un formato de campos fijos, donde la posición de cada campo indica su significado, y los campos están separados por un pipe (`|`). El nombre del archivo tendrá la fecha de registro de las encuestas.

Formato: `ID_ENCUESTA|FECHA|CANAL|TIEMPO_RESPUESTA|NOTA_SATISFACCIÓN`

Campos:

-   ID_ENCUESTA: numérico
-   FECHA: texto (`yyyy-mm-dd hh:mm:ss`)
-   CANAL: texto (Teléfono, Email, Chat)
-   TIEMPO_RESPUESTA: numérico (en minutos)
-   NOTA_SATISFACCIÓN: numérico (de 1 a 5)

Se requiere un script que procese todos los archivos de encuestas en un directorio, calcule el tiempo de respuesta promedio y la nota de satisfacción promedio por canal de atención y por día. El resultado debe ser un archivo o una impresión en pantalla, ambas en formato JSON.

## Ejemplo de archivo de entrada (`2025-07-01.txt`)

```plaintext
101|2025-07-01 10:22:33|Telefono|5.5|4
102|2025-07-01 12:23:11|Email|120|5
103|2025-07-01 22:34:43|Chat|2.1|3
104|2025-06-30 23:11:10|Telefono|7.8|2
```

## Ejemplo de salida JSON

```json
{
    "2025-06-30": {
        "Telefono": {
            "tiempo_respuesta_promedio": 7.8,
            "nota_satisfaccion_promedio": 2
        }
    },
    "2025-07-01": {
        "Telefono": {
            "tiempo_respuesta_promedio": 7.8,
            "nota_satisfaccion_promedio": 2
        },
        "Email": {
            "tiempo_respuesta_promedio": 120,
            "nota_satisfaccion_promedio": 5
        },
        "Chat": {
            "tiempo_respuesta_promedio": 2.1,
            "nota_satisfaccion_promedio": 3
        }
    }
}
```

## Parámetros

| Parámetro bash Parámetro | PowerShell    | Descripción                                                                       |
| :----------------------- | :------------ | :-------------------------------------------------------------------------------- |
| `-d` / `--directorio`    | `-directorio` | Ruta del directorio con los archivos de encuestas a procesar                      |
| `-a` / `--archivo`       | `-archivo`    | Ruta completa del archivo JSON de salida. No se puede usar con `-p` / `-pantalla` |
| `-p` / `--pantalla`      | `-pantalla`   | Muestra la salida por pantalla. No se puede usar con `-a` / `-archivo`.           |

## Consideraciones

1. Tener en cuenta que, por diferentes motivos, un archivo puede tener registros con fechas que no sean la misma que la indicada en su nombre.
