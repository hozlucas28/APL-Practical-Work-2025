# Practical work requirements

## Delivery conditions

-   A file in `.zip` or `.tar` format must be submitted through the MIeL platform (`.rar` or other compression/packaging formats are not accepted), containing the cover page published in MIeL along with the files of the work resolution.
-   The source code of each of the solved exercises must be submitted in both Bash and Powershell. If an exercise is solved in only one language, it will be considered incomplete and, therefore, failed.
-   Valid test batches must be submitted for the exercises that receive files or directories as parameters.
-   Code files must have a header listing the group members.
-   The files with the code for each exercise and their test batches must be placed in a directory with the following structure:
    -   APL/
        -   bash/
            -   exercise1
            -   exercise2
            -   exercise3
            -   exercise4
            -   exercise5
        -   powershell/
            -   exercise1
            -   exercise2
            -   exercise3
            -   exercise4
            -   exercise5

## General correction and evaluation criteria for all exercises

-   Bash scripts must show help with the `-h` and `--help` parameters. They must allow parameters to be entered in any order, not in a fixed order.
-   Powershell scripts must show help with the `Get-Help` command. E.g.: `Get-Help ./exercise1.ps1`. They must validate parameters in the params section using Powershell’s native functionality.
-   When there are parameters that receive directory or file paths, both relative and absolute paths, as well as those containing spaces, must be accepted.
-   Script execution must not be allowed if at least one required parameter is missing.
-   If any command used in the script fails, it must be handled properly: stop the script execution (or save the error if possible) and show a message informing the user about the problem in a user-friendly way, assuming the user has no IT knowledge.
-   If temporary work files are generated, they must be created in the `/tmp` temporary directory; and they must be deleted at the end of the script, whether successful or failed, to avoid leaving junk files. (See `trap` in Bash / `try-catch-finally` in PowerShell)
-   Desirable:
    -   Use of functions in the code to solve the exercises.

## Exercises

1. [Customer satisfaction survey results analysis](../../../src/bash/exercise-01/README.md)
2. [Route analysis in a transport map](../../../src/bash/exercise-02/README.md)
3. [Event counting in system logs](../../../src/bash/exercise-03/README.md)
4. [Code security analysis in Git repositories](../../../src/bash/exercise-04/README.md)
5. [Country information search tool](../../../src/bash/exercise-05/README.md)
