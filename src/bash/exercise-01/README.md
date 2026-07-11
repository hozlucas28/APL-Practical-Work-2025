# Analysis of Customer Satisfaction Survey Results

> Learning objectives: handling text files, processing tabular data, managing parameters, and screen output.

[(solution in Bash)](./) [(solution in PowerShell)](../../powerShell/exercise-01/) [(spanish version)](../../../docs/translations/es/exercises/exercise-01.md)

A script is required to analyze the results of customer satisfaction surveys from a customer service department. The data is recorded daily in text files, with each survey on a single line.

The log file has a fixed-field format, where the position of each field indicates its meaning, and the fields are separated by a pipe (`|`). The file name will contain the date of the survey records.

Format: `SURVEY_ID|DATE|CHANNEL|RESPONSE_TIME|SATISFACTION_SCORE`

Fields:

-   SURVEY_ID: numeric
-   DATE: text (`yyyy-mm-dd hh:mm:ss`)
-   CHANNEL: text (Phone, Email, Chat)
-   RESPONSE_TIME: numeric (in minutes)
-   SATISFACTION_SCORE: numeric (from 1 to 5)

A script is required to process all survey files in a directory, calculate the average response time and average satisfaction score by service channel and by day. The result must be either a file or printed on the screen, both in JSON format.

## Example input file (`2025-07-01.txt`)

```plaintext
101|2025-07-01 10:22:33|Telephone|5.5|4
102|2025-07-01 12:23:11|Email|120|5
103|2025-07-01 22:34:43|Chat|2.1|3
104|2025-06-30 23:11:10|Telephone|7.8|2
```

## Example JSON output

```json
{
    "2025-06-30": {
        "Telephone": {
            "response_time": 7.8,
            "satisfaction_score": 2
        }
    },
    "2025-07-01": {
        "Telephone": {
            "response_time": 7.8,
            "satisfaction_score": 2
        },
        "Email": {
            "response_time": 120,
            "satisfaction_score": 5
        },
        "Chat": {
            "response_time": 2.1,
            "satisfaction_score": 3
        }
    }
}
```

## Parameters

| Bash parameter       | PowerShell   | Description                                                             |
| :------------------- | :----------- | :---------------------------------------------------------------------- |
| `-d` / `--directory` | `-directory` | Path to the directory containing the survey files to process            |
| `-f` / `--file`      | `-file`      | Full path to the output JSON file. Cannot be used with `-s` / `-screen` |
| `-s` / `--screen`    | `-screen`    | Displays the output on screen. Cannot be used with `-f` / `-file`.      |

## Considerations

1. Keep in mind that, for various reasons, a file may contain records with dates that do not match the one indicated in its name.
