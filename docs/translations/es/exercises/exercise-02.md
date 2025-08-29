# Análisis de rutas en un mapa de transporte

> Objetivos de aprendizaje: arrays y matrices.

[ [Solución en Bash](../../../../src/bash/exercise-02/) ] [ [Solución en PowerShell](../../../../src/powerShell/exercise-02/) ] [ [Versión en inglés](../../../../src/bash/exercise-02/README.md) ]

Desarrollar un script para analizar rutas en una red de transporte público. La información de la red se representa como una matriz de adyacencia donde los valores representan el tiempo de viaje entre estaciones. El script debe ser capaz de determinar si una estación es un "hub" (estación con más conexiones) o encontrar el camino más corto en tiempo entre todas las estaciones. En caso de haber más de un camino, mostrará todos aquellos que cumplan con la condición. La salida se guardará en un archivo `informe.<nombreArchivoEntrada>` en el mismo directorio del archivo original.

El camino más corto se calculará usando el [algoritmo de Dijkstra](https://es.wikipedia.org/wiki/Algoritmo_de_Dijkstra). Este algoritmo encuentra la ruta con menor peso (en este caso, tiempo de viaje) entre dos nodos en un grafo. Se debe implementar la lógica de este algoritmo para resolver el problema.

## Ejemplo de archivo de entrada (`mapa_transporte.txt`)

En este ejemplo, la matriz representa la conexión entre 4 estaciones (1, 2, 3 y 4).

```plaintext
0|10|0|5
10|0|4|0
0|4|0|8
5|0|8|0
```

> [!NOTE]
> Un `0` indica que no hay conexión directa o qué es la misma estación. Los otros valores son el tiempo en minutos.

## Ejemplo de salida del informe

```plaintext
## Informe de análisis de red de transporte
**Hub de la red:** Estación 2 (4 conexiones)
**Camino más corto: entre Estación 1 y Estación 4:**
**Tiempo total:** 9 minutos
**Ruta:** 1 -> 2 -> 3 -> 4
```

> [!IMPORTANT]
> Varía según el parámetro recibido

## Parámetros

| Parámetro bash       | Parámetro PowerShell | Descripción                                                                                |
| :------------------- | :------------------- | :----------------------------------------------------------------------------------------- |
| `-m` / `--matriz`    | `-matriz`            | Ruta del archivo de la matriz de adyacencia.                                               |
| `-h` / `--hub`       | `-hub`               | Determina qué estación es el "hub" de la red. No se puede usar junto con `-c` / `-camino`. |
| `-c` / `--camino`    | `-camino`            | Encuentra el camino más corto en tiempo. No se puede usar junto a `-h` / `-hub`.           |
| `-s` / `--separador` | `-separador`         | Carácter para utilizarse como separador de columnas.                                       |

## Consideraciones

1. El script debe validar que el archivo de entrada sea una matriz cuadrada y simétrica con valores numéricos.
2. Los valores de la matriz serán enteros o decimales.
