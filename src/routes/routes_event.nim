import
  std/[
    json,
    strutils,
    times
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


var eventRouter*: Router

eventRouter.post("/api/event",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  when defined(dev):
    echo "Event called"

  var data: JsonNode
  try:
    data = parseJson(c.req.body)
  except:
    resp Http400, "Invalid JSON"

  var
    event: string
    email: string
    mail: string
    delay: int

  try:
    event = data["event"].getStr()
    email = data["email"].getStr()
    mail  = data["mail"].getStr()
  except:
    resp Http400, "Invalid data, event = " & event & ", email = " & email & ", mail = " & mail

  try:
    delay = data["delay"].getInt()
  except:
    resp Http400, "Invalid delay"


  #
  # Get user ID
  #
  var userID: string
  pg.withConnection conn:
    userID = getValue(conn, sqlSelect(
        table  = "users",
        select = ["id"],
        where  = ["email = ?"],
      ), email)

  if userID == "":
    resp Http400, "User not found"


  #
  # Mail ID
  #
  var mailID: string
  pg.withConnection conn:
    mailID = getValue(conn, sqlSelect(
        table  = "mails",
        select = ["id"],
        where  = ["identifier = ?"],
      ), mail)

  if mailID == "":
    resp Http400, "Mail not found"


  #
  # Event
  #
  case event
  of "send-email":
    pg.withConnection conn:
      if getValue(conn, sqlSelect(
          table = "mails",
          select = [
            "mails.id"
          ],
          joinargs = [
            (table: "pending_emails", tableAs: "", on: @["pending_emails.mail_id = mails.id"])
          ],
          where = [
            "mails.id =",
            "mails.send_once = true",
            "pending_emails.user_id ="
          ],
          customSQL = "AND pending_emails.status = 'sent' LIMIT 1"
      ), mailID, userID) != "":
        resp Http200, ( %* { "success": false, "message": "Mail enforces send_once. Mail already sent." } )

      exec(conn, sqlInsert(
        table = "pending_emails",
        data  = [
          "user_id",
          "mail_id",
          "status",
          "scheduled_for",
          "trigger_type"
        ]),
          userID, mailID,
          "pending",
          $(now().utc + delay.minutes).format("yyyy-MM-dd HH:mm:ss"),
          "event-send"
        )

      resp Http200, ( %* { "success": true, "message": "Email scheduled" } )

  of "cancel-email":
    pg.withConnection conn:
      if execAffectedRows(conn, sqlUpdate(
        table = "pending_emails",
        data  = ["status = ?"],
        where = [
          "user_id =",
          "mail_id =",
          "status ="
        ],
      ), "cancelled", userID, mailID, "pending") > 0:
        resp Http200, ( %* { "success": true, "message": "Email cancelled" } )
      else:
        resp Http200, ( %* { "success": false, "message": "No pending email found" } )

  of "create-contact":
    resp Http200, "Not implemented"

  else:
    resp Http400, "Invalid event"

)