For supported databases, which are currently postgres and redis, create a
server local to the current directory.  For example, for postgres:

```
dbenv-pg [ARGUMENTS] [ACTION] [[EXTRA ARGUMENTS]]

ARGUMENTS:
    -h, --help               This screen
    -b, --base-dir [PATH]    Path to base directory.  If unspecified, the directory
                             tree will be searched upward to either the user's home
                             directory or / looking for the directory '.local-pg/'.
                             If not found, the default ~/.local/dbenv/local-pg/ is used.
    -I, --initialize         Shortcut for "--base-dir ./.local-pg"


ACTION:
    start         Start the pg server and create the default database
    stop          Stop the resid server
    shell         Connect to server with psql
    clean         Stop the server and wipe any remaining files
    url           Print url to pg server
    base-dir      Print the resolved base-dir

EXTRA ARGUMENTS are passed when using the 'shell' action and are otherwise ignored.
```
