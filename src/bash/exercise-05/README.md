# Country Information Searcher

> Learning objectives: connection with APIs and web services, handling files and JSON objects, and information caching.

[(solution in Bash)](./) [(solution in PowerShell)](../../powerShell/exercise-05/) [(spanish version)](../../../docs/translations/es/exercises/exercise-05.md)

A script is required to query country information using a public API. The script will allow searching for countries by name, and once the information of a country is obtained, it must be saved in a cache file to avoid future queries to the API. The relevant details of each country must be displayed on the screen in the format mentioned later.

The results stored in the cache file must have a TTL (time to live) that indicates how long that result is valid. After that time, the script must query the API again to update the cached values of that element.

## API Documentation

The REST Countries API does not require registration. The query is made by country name.

> API URL: `https://restcountries.com/v3.1/name/{name}`

## Example cURL request

```plaintext
curl "https://restcountries.com/v3.1/name/spain"
```

## Example of expected output (for each country found)

```plaintext
Country: Spain
Capital: Madrid
Region: Europe
Population: 47615034
Currency: Euro (EUR)
```

## Parameters

| Bash parameter  | PowerShell parameter | Description                                               |
| :-------------- | :------------------- | :-------------------------------------------------------- |
| `-n` / `--name` | `-name`              | Name(s) of the countries to search for.                   |
| `-t` / `--ttl`  | `-ttl`               | Time in seconds that the results will be stored in cache. |

## Considerations

1. Country names can be multiple and must be of array type in PowerShell.
2. The cache file must persist queries for a specific time (TTL).
