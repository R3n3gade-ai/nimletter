


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


proc listIDsFromUUIDs*(uuids: seq[string], includeDefaultList = true): tuple[requireOptIn: bool, ids: seq[string]] =
  var
    ids: seq[string]
    requireOptIn = false

  if includeDefaultList:
    ids.add("1")

  pg.withConnection conn:
    let data = getAllRows(conn, sqlSelect(
        table = "lists",
        select = ["id", "require_optin"],
        where = ["uuid = ANY(?::uuid[])"]
      ), "{" & uuids.join(",") & "}")

    for row in data:
      if row[0] == "1":
        continue
      ids.add(row[0])
      if row[1] == "t" and not requireOptIn:
        requireOptIn = true

  return (requireOptIn, ids)