


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
  ../utils/auth,
  ../utils/validate_data


var pendingemailsRouter*: Router

pendingemailsRouter.post("/api/pending_emails/create",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    userID          = @"userID"
    listID          = @"listID"
    flowIDRaw       = @"flowID"
    flowStepIDRaw   = @"flowStepID"
    triggerType     = @"triggerType"
    scheduledForRaw = @"scheduledFor" # TIMESTAMP
    status          = "pending"

  #
  # Validate input
  #
  if userID.strip() == "" or listID.strip() == "":
    resp Http400, "User ID and List ID are required"

  var
    flowID: string
    flowStepID: string

  pg.withConnection conn:
    # Flow
    flowID = getValue(conn, sqlSelect(
        table   = "flows",
        select  = ["id"],
        where   = ["id = ?"]
      ), flowIDRaw)

    if flowID == "":
      resp Http400, "Flow ID not found, ID: " & flowIDRaw

    # Flow Step
    flowStepID = getValue(conn, sqlSelect(
        table   = "flow_steps",
        select  = ["id"],
        where   = ["id = ?"]
      ), flowStepIDRaw)

  if flowStepID == "":
    resp Http400, "Flow Step ID not found, ID: " & flowStepIDRaw



  let scheduledFor = scheduledForRaw

  #
  # Insert into database
  #
  let
    args = @[
      userID,
      listID,
      flowID,
      flowStepID,
      triggerType,
      scheduledFor,
      status
    ]

  pg.withConnection conn:
    exec(conn, sqlInsert(
        table = "pending_emails",
        data  = [
          "user_id",
          "list_id",
          "flow_id",
          "flow_step_id",
          "trigger_type",
          "scheduled_for",
          "status"
        ],
        args  = args),
      args)

  resp Http200
)


pendingemailsRouter.get("/api/pending_emails/get",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  #
  # Validate input
  #
  let
    emailID = @"emailID"

  if emailID.strip() == "":
    resp Http400, "Email ID is required"

  #
  # Get data
  #
  var data: seq[string]
  pg.withConnection conn:
    data = getRow(conn, sqlSelect(
        table   = "pending_emails",
        select  = [
          "user_id",
          "list_id",
          "flow_id",
          "flow_step_id",
          "trigger_type",
          "scheduled_for",
          "status",
          "message_id",
          "sent_at"
        ],
        where   = ["id = ?"]
      ), emailID)

  resp Http200, (
    %* {
      "user_id": data[0],
      "list_id": data[1],
      "flow_id": data[2],
      "flow_step_id": data[3],
      "trigger_type": data[4],
      "scheduled_for": data[5],
      "status": data[6],
      "message_id": data[7],
      "sent_at": data[8]
    }
  )
)


pendingemailsRouter.post("/api/pending_emails/update",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    emailID         = @"emailID"
    scheduledForRaw = @"scheduledFor"

  #
  # Validate input
  #
  if emailID.strip() == "":
    resp Http400, "Email ID is required"

  if scheduledForRaw.strip() == "":
    resp Http400, "Scheduled For is required"

  #
  # Update database
  #
  pg.withConnection conn:
    exec(conn, sqlUpdate(
        table = "pending_emails",
        data  = [
          "scheduled_for"
        ],
        where = ["id = ?"]),
      scheduledForRaw,
      emailID
    )

  resp Http200
)


pendingemailsRouter.delete("/api/pending_emails/delete",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  #
  # Validate input
  #
  let
    emailID = @"emailID"

  if emailID.strip() == "":
    resp Http400, "Email ID is required"

  #
  # Delete
  #
  pg.withConnection conn:
    exec(conn, sqlDelete(
        table = "pending_emails",
        where = ["id = ?"]),
      emailID)

  resp Http200
)


pendingemailsRouter.get("/api/pending_emails/all",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    limit = (if @"limit" == "": "0" else: @"limit")
    offset = (if @"offset" == "": "0" else: @"offset")

  var data: seq[seq[string]]
  pg.withConnection conn:
    data = getAllRows(conn, sqlSelect(
        table   = "pending_emails",
        select  = [
          "user_id",
          "list_id",
          "flow_id",
          "flow_step_id",
          "trigger_type",
          "scheduled_for",
          "status",
          "message_id",
          "sent_at"
        ],
        customSQL = "ORDER BY scheduled_for DESC LIMIT $1 OFFSET $2".format(
          limit,
          offset
        )
      ))

  var respJson = parseJson("[]")
  for row in data:
    respJson.add(
      %* {
        "user_id": row[0],
        "list_id": row[1],
        "flow_id": row[2],
        "flow_step_id": row[3],
        "trigger_type": row[4],
        "scheduled_for": row[5],
        "status": row[6],
        "message_id": row[7],
        "sent_at": row[8]
      }
    )

  resp Http200, (
    %* {
      "count": data.len(),
      "limit": limit,
      "offset": offset,
      "data": respJson
    }
  )
)

