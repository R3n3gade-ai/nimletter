
import
  std/strutils

import
  ./database_connection


proc databaseCreate*() =
  let dbSchema = readFile("./src/database/db_schema.sql")

  let dbSplit = dbSchema.split(";\n")

  pg.withConnection conn:
    for sqlItem in dbSplit:
      if sqlItem.strip() == "":
        continue

      try:
        exec(conn, sql(sqlItem.strip() & ";"))
      except:
        echo "Error executing SQL: " & sqlItem
        echo "Got this error code: " & getCurrentExceptionMsg()


proc databaseDelete*() =
  pg.withConnection conn:
    when defined(DB_SQLITE):
      exec(conn, sql("PRAGMA writable_schema = 1;"))
      exec(conn, sql("delete from sqlite_master where type in ('table', 'index', 'trigger');"))
      exec(conn, sql("PRAGMA writable_schema = 0;"))
      exec(conn, sql("VACUUM;"))
    else:
      exec(conn, sql("DROP SCHEMA public CASCADE;"))
      exec(conn, sql("CREATE SCHEMA public;"))