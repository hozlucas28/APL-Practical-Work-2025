# Code Security Analysis in Git Repositories

> Learning objectives: daemon processes, configuration file handling, text search and replacement.

[ [Solution in Bash](./) ] [ [Solution in PowerShell](../../powerShell/exercise-04/) ] [ [Spanish version](../../../docs/translations/es/exercises/exercise-04.md) ]

A daemon script is required to monitor a [Git](https://git-scm.com/) repository and detect credentials or sensitive data that may have been accidentally uploaded. The daemon must read a configuration file containing a list of keywords or [regex patterns](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_expressions) to search for (e.g., `password`, `API_KEY`, `API_KEY = `). Each time a new modification is detected in the repository’s main branch, the daemon must scan the modified files. If it finds a match, it must log an alert in a log file with the file name, the pattern found, and the date. The script must run in the background, freeing the terminal.

## Example daemon input

```plaintext
$ ./audit.sh -r /home/user/myrepo -c ./patterns.conf -a 10
> ./audit.ps1 -repo /home/user/myrepo -configuration ./patterns.conf -alert 10
```

## Example configuration file (`patterns.conf`)

```plaintext
password
API_KEY
secret
regex:^.*API_KEY\s*=\s*['"].*['"].*$
```

## Example log file output

```plaintext
[2025-08-23 11:30:00] Alert: 'API_KEY' pattern found in 'config.js' file.
```

## Parameters

| Bash parameter           | PowerShell parameter | Description                                                                                                     |
| :----------------------- | :------------------- | :-------------------------------------------------------------------------------------------------------------- |
| `-r` / `--repo`          | `-repo`              | Path to the Git repository to monitor.                                                                          |
| `-c` / `--configuration` | `-configuration`     | Path to the configuration file containing the list of patterns to search for.                                   |
| `-l` / `--log`           | `-log`               | Path to the log file containing the list of identified events.                                                  |
| `-k` / `--kill`          | `-kill`              | Flag to stop the daemon. Only used together with `-r` / `-repo` and must validate that a daemon process exists. |

## Considerations

1. The solution must be a single script that can be started and later stopped.
2. No more than one daemon process can be run for the same repository.
3. Monitoring must be triggered by changes identified in the files of the directory.
4. The list of patterns to search for must be configurable in an external file.
5. The script must be stoppable with a flag.
