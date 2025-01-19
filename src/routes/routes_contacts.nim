


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
  mummy, mummy/routers,
  mummy_utils


import
  sqlbuilder


import
  ../database/database_connection,
  ../email/email_optin,
  ../scheduling/schedule_mail,
  ../utils/auth,
  ../utils/contacts_utils,
  ../utils/list_utils,
  ../utils/validate_data,
  ../webhook/webhook_events


type
  UserStatus = enum
    enabled
    disabled


var usersRouter*: Router

usersRouter.post("/api/contacts/create",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    email = @"email".toLowerAscii().strip()
    name  = @"name".strip()
    requiresDoubleOptIn = (@"requiresDoubleOptIn" == "true")
    flowStep = (if @"flowStep" == "": 1 else: @"flowStep".parseInt())

  if email.strip() == "" or email.len() > 255 or not email.isValidEmail():
    resp Http400, "Email is required"

  if name.len() > 255:
    resp Http400, "Name is too long"

  let listID =
    if @"list" != "":
      listIDfromIdentifier(@"list")
    else:
      "1" # => Default list

  let userID = createContact(email, name, requiresDoubleOptIn, listIDs = @[])

  if requiresDoubleOptIn:
    emailOptinSend(email, name)

    if listID != "":
      discard addContactToPendinglist(userID, listID)

  elif listID != "":
    discard addContactToList($userID, listID, flowStep = flowStep)

  let data = %* {
      "success": true,
      "id": userID,
      "requiresDoubleOptIn": requiresDoubleOptIn,
      "email": email,
      "name": name,
      "list": (if @"list" != "": @"list" else: "default"),
      "event": "contact_created"
    }

  parseWebhookEvent(contact_created, data)

  resp Http200, data
)


usersRouter.post("/api/contacts/update",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    contactID = @"contactID"
    email  = @"email"
    name   = @"name"
    status = $parseEnum[UserStatus](@"status", disabled)
    requiresDoubleOptIn = (@"requiresDoubleOptIn" == "true")
    doubleOptIn = (@"doubleOptIn" == "true")
    meta   = @"meta"

  if not contactID.isValidInt() and not email.isValidEmail():
    resp Http400, "Invalid user ID or EMAIL"

  if email.len() > 255 or not email.isValidEmail():
    resp Http400, "Invalid email"

  if meta.len() > 0:
    try:
      discard parseJson(meta)
    except:
      resp Http400, "Invalid meta JSON"

  pg.withConnection conn:
    exec(conn, sqlUpdate(
        table = "contacts",
        data  = [
          "updated_at",
          "email",
          "name",
          "status",
          "requires_double_opt_in",
          "double_opt_in",
          "meta",
        ],
        where = [
          (if contactID != "":
            "id = ?"
          else:
            "email = ?")
        ]
      ),
        $now().utc,
        email, name, status, $requiresDoubleOptIn, $doubleOptIn, meta,
        (if contactID != "":
          contactID
        else:
          email)
      )

  if not requiresDoubleOptIn or doubleOptIn:
    moveFromPendingToSubscription(contactID)

  let data = %* {
      "success": true,
      "id": contactID,
      "requiresDoubleOptIn": requiresDoubleOptIn,
      "email": email,
      "name": name,
      "status": status,
      "meta": (if meta != "": parseJson(meta) else: parseJson("{}")),
      "event": "contact_updated"
    }

  parseWebhookEvent(contact_updated, data)

  resp Http200
)


usersRouter.post("/api/contacts/meta/@action",
proc(request: Request) =
  ## meta is JSONB. If action = add, add new, if action = remove, remove key
  createTFD()
  if not c.loggedIn: resp Http401

  var
    contactID = @"contactID"
    email     = @"email"
    action    = @"action"
    key       = @"key"
    value     = @"value"

  if not contactID.isValidInt() and not email.isValidEmail():
    resp Http400, "Invalid user ID or EMAIL"

  if action != "add" and action != "remove":
    resp Http400, "Invalid action"

  if key.len() == 0:
    resp Http400, "Invalid key"

  if action == "add":
    pg.withConnection conn:
      exec(conn, sqlUpdate(
          table = "contacts",
          data  = [
            "meta = jsonb_set(meta, ?::text[], to_jsonb(?))",
            "updated_at",
          ],
          where = [
            (if contactID != "":
              "id = ?"
            else:
              "email = ?")
          ]
        ),
        "{" & key & "}", value,
        $now().utc,
        (if contactID != "":
          contactID
        else:
          email)
      )

  elif action == "remove":
    pg.withConnection conn:
      exec(conn, sqlUpdate(
          table = "contacts",
          data  = [
            "meta = meta - ?",
            "updated_at",
          ],
          where = [
            (if contactID != "":
              "id = ?"
            else:
              "email = ?")
          ]
        ),
        key,
        $now().utc,
        (if contactID != "":
          contactID
        else:
          email)
      )

  resp Http200
)


usersRouter.post("/api/contacts/list/add",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    userID = @"contactID"
    listID = @"listID"
    listType = @"listType"

  if not userID.isValidInt():
    resp Http400, "Invalid user ID"

  if not listID.isValidInt():
    resp Http400, "Invalid list ID"



  if listType == "pending":
    pg.withConnection conn:
      exec(conn, sqlUpdate(
          table = "contacts",
          data  = [
            "pending_lists = array_append(pending_lists, ?)",
            "updated_at",
          ],
          where = ["id = ?"]
        ),
        listID,
        $now().utc,
        userID
      )

    resp Http200


  if not addContactToList(userID, listID):
    resp Http400, "Error subscribing user"

  resp Http200
)


usersRouter.post("/api/contacts/list/remove",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    userID = @"contactID"
    listID = @"listID"
    listType = @"listType"

  if not userID.isValidInt():
    resp Http400, "Invalid user ID"

  if not listID.isValidInt():
    resp Http400, "Invalid list ID"

  if listType == "pending":
    # Remove int from array pendinglists
    pg.withConnection conn:
      exec(conn, sqlUpdate(
          table = "contacts",
          data  = [
            "pending_lists = array_remove(pending_lists, ?)",
            "updated_at",
          ],
          where = ["id = ?"]
        ),
        listID,
        $now().utc,
        userID
      )

    resp Http200

  #
  # Get potential flow, so we can stop pending emails
  #
  pg.withConnection conn:
    let flowIDs = getValue(conn, sqlSelect(
        table = "lists",
        select = ["array_to_string(lists.flow_ids, ',') as flows"],
        where = ["id = ?"]
      ), listID)

    if flowIDs != "":
      for flowID in flowIDs.split(","):
        exec(conn, sqlUpdate(
            table = "pending_emails",
            data  = [
              "status = 'cancelled'",
              "scheduled_for = NULL",
              "updated_at = ?"
            ],
            where = [
              "user_id = ?",
              "flow_id = ?",
              "status = 'pending'"
            ]
          ),
          $now().utc, userID, flowID)


  pg.withConnection conn:
    exec(conn, sqlDelete(
        table = "subscriptions",
        where = ["user_id = ?", "list_id = ?"]),
        userID, listID
      )

  resp Http200
)


usersRouter.delete("/api/contacts/delete",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let userUUID = @"userUUID"

  if not userUUID.isValidUUID():
    resp Http400, "Invalid user UUID"

  pg.withConnection conn:
    exec(conn, sqlDelete(
        table = "contacts",
        where = ["uuid = ?"]),
      userUUID)

  resp Http200
)


usersRouter.get("/api/contacts/get",
proc(request: Request) =
  createTFD()
  if not c.loggedIn:
    redirect("/login")

  if not @"contactID".isValidInt():
    resp Http400, "Invalid user ID"

  let
    contactID = @"contactID"

  var
    contact: seq[string]
    subscriptions: seq[seq[string]]
    pendingList: seq[seq[string]]

  pg.withConnection conn:
    #
    # Get user
    #
    contact = getRow(conn, sqlSelect(
      table = "contacts",
      select = [
        "contacts.id",
        "contacts.uuid",
        "contacts.email",
        "contacts.name",
        "contacts.requires_double_opt_in",
        "contacts.double_opt_in",
        "contacts.double_opt_in_data",
        "contacts.bounced_at",
        "contacts.complained_at",
        "contacts.created_at",
        "contacts.updated_at",
        "contacts.meta",
        "contacts.status",
        "contacts.pending_lists"
      ],
      where = ["contacts.id = ?"],
      customSQL = "ORDER BY contacts.created_at"
      ), contactID)


    #
    # Get subscriptions
    #
    subscriptions = getAllRows(conn, sqlSelect(
      table = "subscriptions",
      select = [
        "subscriptions.id",
        "subscriptions.list_id",
        "subscriptions.subscribed_at",
        "lists.name",
      ],
      joinargs = [
        (table: "lists", tableAs: "", on: @["subscriptions.list_id = lists.id"]),
      ],
      where = ["subscriptions.user_id = ?"],
      customSQL = "ORDER BY lists.name"
      ), contactID)


    #
    # Get pending lists
    #
    if contact[13] != "":
      pendingList = getAllRows(conn, sqlSelect(
        table = "lists",
        select = [
          "lists.id",
          "lists.name",
          "lists.description",
          "array_to_string(lists.flow_ids, ',') as flows",
          "lists.created_at",
          "lists.updated_at",
        ],
        where = ["lists.id = ANY(?::int[])"],
        customSQL = "ORDER BY lists.name",
        ), contact[13])


  if contact.len == 0:
    resp Http404, "User not found"

  #
  # Build JSON response
  #
  var subscriptionsJson = parseJson("[]")
  for subscription in subscriptions:
    subscriptionsJson.add( %* {
      "id": subscription[0],
      "list_id": subscription[1],
      "subscribed_at": subscription[2],
      "list_name": subscription[3],
    })

  var pendingListsJson = parseJson("[]")
  for pending in pendingList:
    pendingListsJson.add( %* {
      "id": pending[0],
      "list_name": pending[1],
      "description": pending[2],
      "flow_id": pending[3],
      "created_at": pending[4],
      "updated_at": pending[5],
    })

  var bodyJson = parseJson("[]")
  bodyJson.add( %* {
    "id": contact[0],
    "uuid": contact[1],
    "email": contact[2],
    "name": contact[3],
    "requires_double_opt_in": (contact[4] == "t"),
    "double_opt_in": (contact[5] == "t"),
    "double_opt_in_data": (if contact[6] != "": parseJson(contact[6]) else: parseJson("[]")),
    "bounced_at": contact[7],
    "complained_at": contact[8],
    "created_at": contact[9],
    "updated_at": contact[10],
    "meta": (if contact[11] != "": parseJson(contact[11]) else: parseJson("{}")),
    "status": contact[12],
    "pending_lists": pendingListsJson,
    "subscriptions": subscriptionsJson,
  })

  resp Http200, (
    %* {
      "data": bodyJson,
      "count": 1,
      "last_page": 1
    }
  )
)


usersRouter.get("/api/contacts/get/activity",
proc(request: Request) =
  ## Data from each of the tables:
  ## pending_emails, email_clicks, email_opens, email_bounces, email_complaints
  createTFD()
  if not c.loggedIn: resp Http401

  if not @"contactID".isValidInt():
    resp Http400, "Invalid user ID"

  let contactID = @"contactID"

  var
    pendingEmails: seq[seq[string]]
    emailClicks: seq[seq[string]]
    emailOpens: seq[seq[string]]
    emailBounces: seq[seq[string]]
    emailComplaints: seq[seq[string]]


  pg.withConnection conn:

    pendingEmails = getAllRows(conn, sqlSelect(
      table = "pending_emails",
      select = [
        "pending_emails.scheduled_for",
        "pending_emails.sent_at",
        "flows.name",                   # 2
        "flow_steps.subject",           # 3
        "flow_steps.trigger_type",      # 4
        "flow_steps.delay_minutes",     # 5
        "pending_emails.updated_at",    # 6
        "pending_emails.status",        # 7
        "flow_steps.mail_id",       # 8
      ],
      joinargs = [
        (table: "flows", tableAs: "flows", on: @["pending_emails.flow_id = flows.id"]),
        (table: "flow_steps", tableAs: "flow_steps", on: @["pending_emails.flow_step_id = flow_steps.id"]),
      ],
      where = ["user_id = ?"],
      ), contactID)

    emailClicks = getAllRows(conn, sqlSelect(
      table = "email_clicks",
      select = [
        "clicked_at",
        "link_url"
      ],
      where = ["user_id = ?"],
      ), contactID)

    emailOpens = getAllRows(conn, sqlSelect(
      table = "email_opens",
      select = [
        "opened_at"
      ],
      where = ["user_id = ?"],
      ), contactID)

    emailBounces = getAllRows(conn, sqlSelect(
      table = "email_bounces",
      select = [
        "bounced_at",
        "bounce_type",
        "bounce_subtype",
        "diagnostic_code"
      ],
      where = ["user_id = ?"],
      ), contactID)

    emailComplaints = getAllRows(conn, sqlSelect(
      table = "email_complaints",
      select = [
        "complained_at",
        "complaint_feedback"
      ],
      where = ["user_id = ?"],
      ), contactID)

  var
    bodyJson = parseJson("[]")
    pendingEmailsJson = parseJson("[]")
    tableJson: OrderedTable[string, JsonNode]

  for pendingEmail in pendingEmails:
    let jItem = %* {
      "type": "pending_email",
      "date": (
        if pendingEmail[1] != "":
          pendingEmail[1]
        elif pendingEmail[0] != "":
          pendingEmail[0]
        elif pendingEmail[7] == "cancelled":
          pendingEmail[6]
        else:
          ""
      ),
      "scheduled_for": pendingEmail[0],
      "sent_at": pendingEmail[1],
      "subject": pendingEmail[3],
      "flow_name": pendingEmail[2],
      "trigger_type": pendingEmail[4],
      "delay_minutes": pendingEmail[5],
      "mail_id": pendingEmail[8],
    }

    if jItem["date"].getStr() == "":
      pendingEmailsJson.add( jItem )
      continue

    bodyJson.add( jItem )
    tableJson[jItem["date"].getStr()] = jItem

  for emailClick in emailClicks:
    let jItem = %* {
      "type": "email_click",
      "date": emailClick[0],
      "link_url": emailClick[1],
    }

    bodyJson.add( jItem )
    tableJson[emailClick[0]] = jItem

  for emailOpen in emailOpens:
    let jItem = %* {
      "type": "email_open",
      "date": emailOpen[0],
    }

    bodyJson.add( jItem )
    tableJson[emailOpen[0]] = jItem

  for emailBounce in emailBounces:
    let jItem = %* {
      "type": "email_bounce",
      "date": emailBounce[0],
      "bounced_feedback": emailBounce[1],
      "bounce_subtype": emailBounce[2],
      "diagnostic_code": emailBounce[3],
    }

    bodyJson.add( jItem )
    tableJson[emailBounce[0]] = jItem

  for emailComplaint in emailComplaints:
    let jItem = %* {
      "type": "email_complaint",
      "date": emailComplaint[0],
      "complaint_feedback": emailComplaint[1],
    }

    bodyJson.add( jItem )
    tableJson[emailComplaint[0]] = jItem


  tableJson.sort(system.cmp, order = SortOrder.Descending)

  var newBodyJson = parseJson("[]")
  for value in pendingEmailsJson:
    newBodyJson.add(value)

  for k, value in tableJson:
    newBodyJson.add(value)


  resp Http200, newBodyJson
)


usersRouter.get("/api/contacts/all",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    limit = (if @"limit" == "": 2000 else: @"limit".parseInt())
    offset = (if @"offset" == "": 0 else: @"offset".parseInt())

  var
    contacts: seq[seq[string]]
    contactsCount: int

  pg.withConnection conn:
    contacts = getAllRows(conn, sqlSelect(
      table = "contacts",
      select = [
        "contacts.id",
        "contacts.uuid",
        "contacts.email",
        "contacts.name",
        "contacts.requires_double_opt_in",
        "contacts.double_opt_in",
        "contacts.double_opt_in_data",
        "contacts.bounced_at",
        "contacts.complained_at",
        "to_char(contacts.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at",
        "to_char(contacts.updated_at, 'YYYY-MM-DD HH24:MI:SS') as updated_at",
        "contacts.status",
        "COUNT(pending_emails.id) FILTER (WHERE pending_emails.status = 'sent') AS sent_emails_count",
        "COUNT(pending_emails.id) FILTER (WHERE pending_emails.status = 'pending') AS pending_emails_count",
        "(SELECT COUNT(*) FROM email_opens WHERE email_opens.user_id = contacts.id) AS email_opens_count",
        "(SELECT COUNT(*) FROM email_clicks WHERE email_clicks.user_id = contacts.id) AS email_clicks_count",
        "(SELECT STRING_AGG(lists.name, ', ') FROM subscriptions JOIN lists ON subscriptions.list_id = lists.id WHERE subscriptions.user_id = contacts.id) AS subscribed_lists",
        "contacts.meta->>'country' AS country"
      ],
      joinargs = [
        (table: "pending_emails", tableAs: "", on: @["contacts.id = pending_emails.user_id"])
      ],
      customSQL = "GROUP BY contacts.id ORDER BY contacts.created_at DESC LIMIT $1 OFFSET $2".format(
        $limit,
        $offset
      )))

    contactsCount = getValue(conn, sqlSelect(
      table = "contacts",
      select = ["COUNT(*)"])).parseInt()


  var bodyJson = parseJson("[]")
  let fakeJson = parseJson("{}")
  for contact in contacts:
    bodyJson.add( %* {
      "id": contact[0],
      "uuid": contact[1],
      "email": contact[2],
      "name": contact[3],
      "requires_double_opt_in": (contact[4] == "t"),
      "double_opt_in": (contact[5] == "t"),
      "double_opt_in_data": (if contact[6] != "": parseJson(contact[6]) else: fakeJson),
      "bounced_at": contact[7].split(".")[0],
      "complained_at": contact[8].split(".")[0],
      "created_at": contact[9].split(".")[0],
      "updated_at": contact[10].split(".")[0],
      "status": contact[11],
      "emails_count_sent": contact[12].parseInt(),
      "emails_count_pending": contact[13].parseInt(),
      "emails_count_open": contact[14].parseInt(),
      "emails_count_clicks": contact[15].parseInt(),
      "subscribed_lists": contact[16],
      "country": contact[17]
    })

  resp Http200, (
    %* {
      "data": bodyJson,
      "count": contactsCount,
      "limit": limit,
      "offset": offset,
      "last_page": (if contactsCount == 0: 0 else: (contactsCount / limit).toInt()),
    }
  )
)



