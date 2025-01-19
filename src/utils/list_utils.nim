


import
  std/[
    algorithm,
    json,
    sequtils,
    strutils,
    tables,
    times
  ]


import
  sqlbuilder


import
  ../database/database_connection,
  ../scheduling/schedule_mail


proc listIDfromIdentifier*(listIdentifer: string): string =
  pg.withConnection conn:
    result = getValue(conn, sqlSelect(
        table = "lists",
        select = ["id"],
        where = ["identifier = ?"]
      ), listIdentifer)


proc listIDsFromUUIDs*(uuids: seq[string], includeDefaultList = true): seq[string] =
  if includeDefaultList:
    result.add("1")

  pg.withConnection conn:
    let data = getAllRows(conn, sqlSelect(
        table = "lists",
        select = ["id"],
        where = ["uuid = ANY(?::uuid[])"]
      ), "{" & uuids.join(",") & "}")

    for row in data:
      if row[0] == "1":
        continue
      result.add(row[0])

  return result