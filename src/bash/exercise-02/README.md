# Route Analysis in a Transportation Map

> Learning objectives: arrays and matrices.

[ [Solution in Bash](./) ] [ [Solution in PowerShell](../../powerShell/exercise-02/) ] [ [Spanish version](../../../docs/translations/es/exercises/exercise-02.md) ]

Develop a script to analyze routes in a public transportation network. The network information is represented as an adjacency matrix where the values represent the travel time between stations. The script must be able to determine whether a station is a "hub" (station with the most connections) or find the shortest travel-time path between all stations. If there is more than one path, it will display all that meet the condition. The output will be saved in a file named `report.<inputFileName>` in the same directory as the original file.

The shortest path will be calculated using [Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm). This algorithm finds the path with the lowest weight (in this case, travel time) between two nodes in a graph. The logic of this algorithm must be implemented to solve the problem.

## Example input file (`transport_map.txt`)

In this example, the matrix represents the connection between 4 stations (1, 2, 3, and 4).

```plaintext
0|10|0|5
10|0|4|0
0|4|0|8
5|0|8|0
```

> [!NOTE]
> A `0` indicates that there is no direct connection or that it is the same station. Other values represent the time in minutes.

## Example report output

```plaintext
## Transportation network analysis report
**Network Hub:** Station 2 (4 connections)
**Shortest path: between Station 1 and Station 4:**
**Total time:** 9 minutes
**Route:** 1 -> 2 -> 3 -> 4
```

> [!IMPORTANT]
> Varies depending on the parameter received

## Parameters

| Bash parameter       | PowerShell parameter | Description                                                                                   |
| :------------------- | :------------------- | :-------------------------------------------------------------------------------------------- |
| `-m` / `--matrix`    | `-matrix`            | Path to the adjacency matrix file.                                                            |
| `-h` / `--hub`       | `-hub`               | Determines which station is the network's "hub." Cannot be used together with `-p` / `-path`. |
| `-p` / `--path`      | `-path`              | Finds the shortest travel-time path. Cannot be used together with `-h` / `-hub`.              |
| `-s` / `--separator` | `-separator`         | Character to be used as column separator.                                                     |

## Considerations

1. The script must validate that the input file is a square and symmetric matrix with numeric values.
2. The matrix values may be integers or decimals.
