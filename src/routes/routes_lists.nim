


import
  std/[
    json,
    strutils
  ]


import
  mummy, mummy/routers,
  mummy_utils


import
  sqlbuilder


import
  ../database/database_connection,
  ../scheduling/schedule_mail,
  ../utils/auth,
  ../utils/validate_data


var listsRouter*: Router

listsRouter.post("/api/lists/create",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    name    = @"name"
    identifier = (if @"identifier" == "": name.toLowerAscii().replace(" ", "-").subStr(0, 20).strip(chars={'-', '_'}) else: @"identifier".replace(" ", "-").subStr(0, 20).strip(chars={'-', '_'}))
    description = @"description"
    flowIDRaw   = @"flowID"
    requireOptIn = @"requireOptIn" == "true"

  if name.strip() == "":
    resp Http400, "Name is required"

  #
  # Validate flow ID
  #
  var flowID: string
  if flowIDRaw != "":
    pg.withConnection conn:
      flowID = getValue(conn, sqlSelect(
          table   = "flows",
          select  = ["id"],
          where   = ["id = ?"]
        ), flowIDRaw)

    if flowID == "":
      resp Http400, "Flow ID not found, ID: " & flowIDRaw


  #
  # Insert into database
  #
  if flowID == "":
    pg.withConnection conn:
      exec(conn, sqlInsert(
          table = "lists",
          data  = [
            "name",
            "identifier",
            "require_optin",
            "description",
          ]),
          name,
          identifier,
          $requireOptIn,
          description
        )

  else:
    pg.withConnection conn:
      exec(conn, sqlInsert(
          table = "lists",
          data  = [
            "name",
            "identifier",
            "require_optin",
            "description",
            "flow_id",
          ]),
          name,
          identifier,
          $requireOptIn,
          description,
          flowID
        )


  resp Http200
)


listsRouter.get("/api/lists/get",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  #
  # Validate input
  #
  let
    listID = @"listID"

  if not listID.isValidInt():
    resp Http400, "Invalid UUID"

  #
  # Get data
  #
  var data: seq[string]
  var flows: seq[seq[string]]
  pg.withConnection conn:
    data = getRow(conn, sqlSelect(
        table   = "lists",
        select  = ["lists.name", "lists.identifier", "lists.description", "array_to_string(lists.flow_ids, ',') as flows", "lists.uuid", "lists.require_optin"],
        where   = ["lists.id = ?"]
      ), listID)

    flows = getAllRows(conn, sqlSelect(
        table   = "flows",
        select  = ["id", "name"],
        where   = ["id = ANY(?::int[])"]
      ), "{" & data[3] & "}")

  var flowdata = parseJson("[]")
  for row in flows:
    flowdata.add(%* {
      "id": row[0],
      "name": row[1]
    })

  resp Http200, (
    %* {
      "name": data[0],
      "identifier": data[1],
      "description": data[2],
      "uuid": data[4],
      "flow_id": flowdata,
      "require_optin": data[5] == "t"
    }
  )
)


listsRouter.post("/api/lists/update",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    listID   = @"listID"
    name     = @"name"
    identifier  = (if @"identifier" == "": name.toLowerAscii().replace(" ", "-").subStr(0, 20).strip(chars={'-', '_'}) else: @"identifier".replace(" ", "-").subStr(0, 20).strip(chars={'-', '_'}))
    description = @"description"
    requireOptIn = @"requireOptIn" == "true"

  #
  # Validate input
  #
  if not listID.isValidInt():
    resp Http400, "Invalid ID"

  #
  # Simple update
  #
  else:
    pg.withConnection conn:
      exec(conn, sqlUpdate(
          table = "lists",
          data  = [
            "name",
            "identifier",
            "description",
            "require_optin"
          ],
          where = ["id = ?", "identifier != 'default'"]),
        name, identifier, description, $requireOptIn, listID)

  resp Http200
)


listsRouter.post("/api/lists/flow/@action",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    listID = @"listID"
    flowIDRaw = @"flowID"
    action = @"action"

  if action notin ["add", "remove"]:
    resp Http400, "Invalid action"

  if not flowIDRaw.isValidInt():
    resp Http400, "Invalid flow ID"

  if action == "remove":
    pg.withConnection conn:
      exec(conn, sqlUpdate(
          table = "lists",
          data  = [
            "flow_ids = array_remove(flow_ids, ?)"
          ],
          where = ["id = ?"]),
        flowIDRaw, listID
      )

  else:
    #
    # Validate flow ID
    #
    var flowID: string
    pg.withConnection conn:
      flowID = getValue(conn, sqlSelect(
          table   = "flows",
          select  = ["id"],
          where   = ["id = ?"]
        ), flowIDRaw)

    if flowID == "":
      resp Http400, "Flow ID not found, ID: " & flowIDRaw

    var users: seq[seq[string]]
    pg.withConnection conn:
      exec(conn, sqlUpdate(
          table = "lists",
          data  = [
            "flow_ids = array_append(flow_ids, ?)"
          ],
          where = ["id = ?"]),
        flowID, listID
      )

      users = getAllRows(conn, sqlSelect(
          table   = "subscriptions",
          select  = ["user_id"],
          where   = ["list_id = ?"]
        ), listID)

    for user in users:
      createPendingEmailFromFlowstep(user[0], listID, flowID, 1)

  resp Http200
)




listsRouter.delete("/api/lists/delete",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  #
  # Validate input
  #
  let
    listID = @"listID"

  if not listID.isValidInt():
    resp Http400, "Invalid ID"

  #
  # Delete
  #
  pg.withConnection conn:
    exec(conn, sqlDelete(
        table = "lists",
        where = ["id = ?", "identifier != 'default'"]),
      listID)

  resp Http200
)


listsRouter.get("/api/lists/all",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  var
    lists: seq[seq[string]]
    listsCount: int
  pg.withConnection conn:
    lists = getAllRows(conn, sqlSelect(
        table   = "lists",
        select  = [
          "lists.id",
          "lists.uuid",
          "lists.name",
          "lists.identifier",
          "lists.description",
          "array_to_string(lists.flow_ids, ',') as flows",
          "to_char(lists.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at",
          "to_char(lists.updated_at, 'YYYY-MM-DD HH24:MI:SS') as updated_at",
          "(SELECT COUNT(*) FROM subscriptions WHERE subscriptions.list_id = lists.id) as user_count",
          "lists.require_optin"
        ],
        customSQL = "ORDER BY lists.name DESC"
      ))

    listsCount = getValue(conn, sqlSelect(
        table = "lists",
        select = ["COUNT(*)"])).parseInt()


  var bodyJson = parseJson("[]")
  for row in lists:
    bodyJson.add(%* {
      "id": row[0],
      "uuid": row[1],
      "name": row[2],
      "identifier": row[3],
      "description": row[4],
      "flows": row[5],
      "created_at": row[6],
      "updated_at": row[7],
      "user_count": row[8],
      "require_optin": row[9] == "t"
    })

  resp Http200, (
    %* {
      "data": bodyJson,
      "count": listsCount,
      "last_page": 1
    }
  )
)
