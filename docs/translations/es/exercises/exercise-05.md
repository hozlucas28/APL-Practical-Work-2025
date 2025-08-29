# Buscador de información de países

> Objetivos de aprendizaje: conexión con APIs y web services, manejo de archivos y objetos JSON, y Cache de información.

[ [Solución en Bash](../../../../src/bash/exercise-05/) ] [ [Solución en PowerShell](../../../../src/powerShell/exercise-05/) ] [ [Versión en inglés](../../../../src/bash/exercise-05/README.md) ]

Se necesita un script para consultar información de países utilizando una API pública. El script permitirá buscar países por nombre y una vez que obtiene la información de un país, se debe guardar en un archivo de Cache para evitar futuras consultas a la API. Los detalles relevantes de cada país deben mostrarse por pantalla con el formato mencionado más adelante.

Los resultados guardados en el archivo Cache deberán tener un TTL (time to live) que indica durante cuánto tiempo es válido ese resultado. Pasado ese tiempo deberá consultar nuevamente a la API para actualizar los valores en Cache de ese elemento.

## Documentación de la API

La API de REST Countries no requiere registro. La consulta se realiza por nombre de país.

> URL de la API: `https://restcountries.com/v3.1/name/{nombre}`

## Ejemplo de llamada cURL

```plaintext
curl "https://restcountries.com/v3.1/name/spain"
```

## Ejemplo de salida esperada (por cada país encontrado)

```plaintext
País: Spain
Capital: Madrid
Región: Europe
Población: 47615034
Moneda: Euro (EUR)
```

## Parámetros

| Parámetro bash    | Parámetro PowerShell | Descripción                                                 |
| :---------------- | :------------------- | :---------------------------------------------------------- |
| `-n` / `--nombre` | `-nombre`            | Nombre/s de los países a buscar.                            |
| `-t` / `--ttl`    | `-ttl`               | Tiempo en segundos que se guardaran los resultados en Cache |

## Consideraciones

1. Los nombres de los países pueden ser múltiples y deben ser de tipo array en PowerShell.
2. El archivo de Cache debe persistir las consultas durante un tiempo determinado (TTL).
