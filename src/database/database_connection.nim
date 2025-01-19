
from std/strutils import parseInt
from std/os import getEnv, createDir

when defined(DB_SQLITE):
  import
    waterpark/sqlite
  export
    sqlite

  createDir("db")
  let
    pgWorkers = getEnv("PG_WORKERS", "1").parseInt()
    pg* = newSqlitePool(pgWorkers, "db/nimsletter.db")

else:
  import
    waterpark/postgres
  export
    postgres

  let
    pgHost      = getEnv("PG_HOST", "localhost")
    pgUser      = getEnv("PG_USER", "nimsletter")
    pgPassword  = getEnv("PG_PASSWORD", "nimsletter")
    pgDatabase  = getEnv("PG_DATABASE", "nimsletter_db")
    pgWorkers   = getEnv("PG_WORKERS", "3").parseInt()
    pg* = newPostgresPool(pgWorkers, pgHost, pgUser, pgPassword, pgDatabase)
