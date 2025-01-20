
import
  std/strutils

import
  ./database_connection


# $1 rolename, $2 user, $3 password
const createUser = """
IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$1') THEN
  CREATE USER $2 WITH PASSWORD '$3';
"""

# $1 dbname, $2 user
const createDatabase = """
IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$1') THEN
  CREATE DATABASE $1 OWNER $2;
"""

# $1 dbname, $2 user
const grantPrivileges = """
GRANT ALL PRIVILEGES ON DATABASE $1 TO $2;
"""


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