

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
  ../email/email_connection,
  ../scheduling/schedule_mail,
  ../utils/auth,
  ../utils/validate_data


proc formatTags(tags: string): seq[string] =
  for tag in tags.split(","):
    if tag.strip() != "":
      result.add(tag.strip())


var mailRouter*: Router

mailRouter.post("/api/mails/create",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  #
  # Get data
  #
  let
    name      = @"name"
    tags      = @"tags"
    category  = @"category"
    contentHTML = @"contentHTML"
    contentEditor = @"contentEditor"

  if name.strip() == "":
    resp Http400, "Name is required"


  #
  # Insert into database
  #
  var mailID: string
  pg.withConnection conn:
    mailID = $insertID(conn, sqlInsert(
        table = "mails",
        data  = [
          "name",
          "identifier",
          "tags",
          "category",
          "contentHTML",
          "contentEditor",
        ]),
        name,
        (name.toLowerAscii().replace(" ", "-").subStr(0, 20).strip(chars={'-', '_'})),
        "{" & formatTags(tags).join(",") & "}",
        category,
        contentHTML,
        contentEditor
      )

  resp Http200, (
    %* {
      "id": mailID
    }
  )
)


mailRouter.get("/api/mails/get",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  #
  # Validate input
  #
  let
    mailID = @"mailID"

  if not mailID.isValidInt():
    resp Http400, "Invalid UUID"


  #
  # Get data
  #
  var mailData: seq[string]
  pg.withConnection conn:
    mailData = getRow(conn, sqlSelect(
        table   = "mails",
        select  = [
          "id",
          "name",
          "contentHTML",
          "contentEditor",
          "editorType",
          "tags",
          "category",
          "subject",
          "to_char(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at",
          "to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') as updated_at",
          "identifier",
          "send_once"
          ],
        where   = [
          "id = ?"
        ]),
      mailID)

  #
  # Check return
  #
  if mailData.len() == 0 or mailData[0] == "":
    resp Http404, "mail not found for UUID " & mailID


  resp Http200, (
    %* {
      "id": mailData[0],
      "name": mailData[1],
      "contentHTML": mailData[2],
      "contentEditor": mailData[3],
      "editorType": mailData[4],
      "tags": (if mailData[5] == "{}": @[] else: mailData[5].strip(chars = {'{', '}'}).split(",")),
      "category": mailData[6],
      "subject": mailData[7],
      "created_at": mailData[8],
      "updated_at": mailData[9],
      "identifier": mailData[10],
      "send_once": mailData[11] == "t"
    }
  )
)


mailRouter.post("/api/mails/update",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  #
  # Get data
  #
  let
    mailID  = @"mailID"
    name      = @"name".strip()
    identifier = (if @"identifier" == "": name.toLowerAscii().replace(" ", "-").subStr(0, 20).strip(chars={'-', '_'}) else: @"identifier".replace(" ", "-").subStr(0, 20).strip(chars={'-', '_'}))
    tags      = @"tags"
    category  = @"category"
    sendOnce  = (if @"sendOnce" == "true": true else: false)
    contentHTML = @"contentHTML"
    contentEditor = @"contentEditor"
    editorType = (if @"editorType" in ["html", "emailbuilder"]: @"editorType" else: "html")

  if not mailID.isValidInt():
    resp Http400, "Invalid UUID"

  if name == "":
    resp Http400, "Name is required"

  var hit = false
  pg.withConnection conn:
    hit = execAffectedRows(conn, sqlUpdate(
        table = "mails",
        data  = [
          "name",
          "identifier",
          "tags",
          "category",
          "contentHTML",
          "contentEditor",
          "editorType",
          "send_once"
        ],
        where = [
          "id = ?"
        ]),
      name,
      identifier,
      "{" & formatTags(tags).join(",") & "}",
      category,
      contentHTML,
      contentEditor,
      editorType,
      sendOnce,
      mailID
    ) > 0

  if not hit:
    resp Http404, "Mail not found for UUID " & mailID

  resp Http200
)


mailRouter.delete("/api/mails/delete",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let mailUUID = @"mail_uuid"

  if not mailUUID.isValidUUID():
    resp Http400, "Invalid UUID"

  var hit = false
  pg.withConnection conn:
    hit = execAffectedRows(conn, sqlDelete(
        table = "mails",
        where = [
          "uuid = ?"
        ]),
      mailUUID
    ) > 0

  if not hit:
    resp Http404, "Mail not found for UUID " & mailUUID

  resp Http200
)


mailRouter.get("/api/mails/all",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    limit = (if @"limit" == "": 2000 else: @"limit".parseInt())
    offset = (if @"offset" == "": 0 else: @"offset".parseInt())

  var
    mails: seq[seq[string]]
    mailsCount: int

  pg.withConnection conn:
    mails = getAllRows(conn, sqlSelect(
      table   = "mails",
      select  = [
        "mails.id",
        "mails.name",
        "mails.subject",
        "mails.tags",
        "mails.category",
        "to_char(mails.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at",
        "to_char(mails.updated_at, 'YYYY-MM-DD HH24:MI:SS') as updated_at",
        "(SELECT COUNT(*) FROM pending_emails WHERE flow_step_id = flow_steps.id AND status = 'sent') as sent_count",
        "(SELECT COUNT(*) FROM pending_emails WHERE flow_step_id = flow_steps.id AND status = 'pending') as pending_count",
        "mails.identifier"
      ],
      joinargs = [
        (table: "flow_steps", tableAs: "", on: @["flow_steps.mail_id = mails.id"])
      ],
      customSQL = "ORDER BY name ASC LIMIT $1 OFFSET $2".format(
        $limit,
        $offset
      )
      ))

    mailsCount = getRow(conn, sqlSelect(
      table   = "mails",
      select  = ["count(*)"]
      )
    )[0].parseInt()

  var bodyJson = parseJson("[]")

  for mail in mails:
    bodyJson.add(
      %* {
        "id": mail[0],
        "name": mail[1],
        "subject": mail[2],
        "tags": mail[3].split(","),
        "category": mail[4],
        "created_at": mail[5],
        "updated_at": mail[6],
        "sent_count": mail[7].parseInt(),
        "pending_count": mail[8].parseInt(),
        "identifier": mail[9]
      }
    )

  resp Http200, (
    %* {
      "data": bodyJson,
      "count": mailsCount,
      "limit": limit,
      "offset": offset,
      "last_page": (if mailsCount == 0: 0 else: (mailsCount / limit).toInt())
    }
  )
)


mailRouter.get("/api/mails/log",
proc(request: Request) =
  ## Getting the last 2000 sent emails from pending_emails
  createTFD()
  if not c.loggedIn: resp Http401

  let
    limit = (if @"limit" == "": 2000 else: @"limit".parseInt())
    offset = (if @"offset" == "": 0 else: @"offset".parseInt())

  var
    mails: seq[seq[string]]
    mailsCount: int

  pg.withConnection conn:
    mails = getAllRows(conn, sqlSelect(
        table   = "pending_emails",
        select  = [
        "pending_emails.id",
        "pending_emails.user_id",
        "pending_emails.list_id",
        "pending_emails.flow_id",
        "pending_emails.flow_step_id",
        "pending_emails.trigger_type",
        "pending_emails.scheduled_for",
        "pending_emails.status",
        "pending_emails.message_id",
        "pending_emails.sent_at",
        "to_char(pending_emails.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at",
        "to_char(pending_emails.updated_at, 'YYYY-MM-DD HH24:MI:SS') as updated_at",
        "contacts.email as user_email",
        "contacts.meta->>'country' AS country",
        "lists.name as list_name",
        "flows.name as flow_name",
        "flow_steps.name as flow_step_name",
        "CASE WHEN EXISTS (SELECT 1 FROM email_opens WHERE email_opens.pending_email_id = pending_emails.id) THEN 'true' ELSE 'false' END as opened",
        "CASE WHEN EXISTS (SELECT 1 FROM email_clicks WHERE email_clicks.pending_email_id = pending_emails.id) THEN 'true' ELSE 'false' END as clicked"
        ],
        joinargs = [
        (table: "contacts", tableAs: "", on: @["contacts.id = pending_emails.user_id"]),
        (table: "lists", tableAs: "", on: @["lists.id = pending_emails.list_id"]),
        (table: "flows", tableAs: "", on: @["flows.id = pending_emails.flow_id"]),
        (table: "flow_steps", tableAs: "", on: @["flow_steps.id = pending_emails.flow_step_id"])
        ],
        where = [
        "pending_emails.status = 'sent'"
        ],
        customSQL = "ORDER BY created_at DESC LIMIT $1 OFFSET $2".format(
        $limit,
        $offset
        )
        ))

    mailsCount = getRow(conn, sqlSelect(
      table   = "pending_emails",
      select  = ["count(*)"]
      )
    )[0].parseInt()


  var bodyJson = parseJson("[]")
  for mail in mails:
    bodyJson.add(
      %* {
        "id": mail[0],
        "user_id": mail[1],
        "list_id": mail[2],
        "flow_id": mail[3],
        "flow_step_id": mail[4],
        "trigger_type": mail[5],
        "scheduled_for": mail[6],
        "status": mail[7],
        "message_id": mail[8],
        "sent_at": mail[9],
        "created_at": mail[10],
        "updated_at": mail[11],
        "user_email": mail[12],
        "country": mail[13],
        "list_name": mail[14],
        "flow_name": mail[15],
        "flow_step_name": mail[16],
        "opened": mail[17],
        "clicked": mail[18]
      }
    )

  resp Http200, (
    %* {
      "data": bodyJson,
      "count": mailsCount,
      "limit": limit,
      "offset": offset,
      "last_page": (if mailsCount == 0: 0 else: (mailsCount / limit).toInt())
    }
  )
)


mailRouter.post("/api/mails/send",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    mailID = @"mailID"
    listID = @"listID"
    email  = @"email"

  var
    mailData: seq[string]
    contactData: seq[string]
    listExists = false

  pg.withConnection conn:
    mailData = getRow(conn, sqlSelect(
        table   = "mails",
        select  = [
          "id",
          "contentHTML",
          "subject"
          ],
        where   = [
          "id = ?"
        ]),
      mailID)

    if email.isValidEmail():
      contactData = getRow(conn, sqlSelect(
          table   = "contacts",
          select  = [
            "id",
            "email"
            ],
          where   = [
            "email = ?"
          ]),
        email)

    elif listID != "":
      listExists = getValue(conn, sqlSelect(
          table   = "lists",
          select  = [
            "id",
            ],
          where   = [
            "id = ?"
          ]),
        listID) != ""

  if mailData[0] == "":
    resp Http404, "Mail not found for ID " & mailID

  if email.isValidEmail():
    discard sendMailMimeNow(
      contactID = contactData[0],
      subject = mailData[2],
      message = mailData[1],
      recipient = contactData[1]
    )

    resp Http200, "Mail sent to " & email

  elif listExists:
    createPendingEmailToAllListContacts(listID, mailID)

)