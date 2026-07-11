# Event Counting in System Logs

> Learning objectives: associative arrays, file search, file handling, and AWK.

[(solution in Bash)](../../bash/exercise-03/) [(solution in PowerShell)](./) [(spanish version)](../../../docs/translations/es/exercises/exercise-03.md)

Develop a script that analyzes all log files (files with the `.log` extension) in a directory to count the occurrence of specific events. The events to search for will be provided as a list of keywords.

## Example input file (`system.log`)

In this example, the keywords could be `Invalid` and `USB`.

```plaintext
Aug 23 10:00:01 server.local kernel: [256.789] USB device plugged in.
Aug 23 10:00:05 server.local sshd[1234]: Invalid user from 192.168.1.1.
Aug 23 10:00:10 server.local sudo[5678]: Command not found.
Aug 23 10:00:15 server.local kernel: [258.123] USB device unplugged.
Aug 23 10:00:20 server.local sshd[1234]: Invalid user from 192.168.1.2.
```

## Example output

```plaintext
USB: 2
Invalid: 2
```

## Parameters

| Bash parameter       | PowerShell parameter | Description                           |
| :------------------- | :------------------- | :------------------------------------ |
| `-d` / `--directory` | `-directory`         | Path to the log directory to analyze. |
| `-w` / `--words`     | `-words`             | List of keywords to count.            |

## Considerations

1. The script must use AWK to process the information in Bash.
2. Keywords must be an array type in PowerShell. In Bash, they will be separated by commas. For example: `usb,invalid`.
3. Searches must be [case-insensitive](https://en.m.wikipedia.org/wiki/Case_sensitivity).
