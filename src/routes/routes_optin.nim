


import
  std/[
    json,
    options,
    sequtils,
    strutils,
    tables,
    times
  ]

from std/os import getEnv

import
  mummy, mummy/routers,
  mummy_utils


import
  mmgeoip,
  sqlbuilder


import
  ../database/database_connection,
  ../email/email_optin,
  ../utils/contacts_utils,
  ../utils/list_utils,
  ../utils/validate_data,
  ../webhook/webhook_events


include
  "../html/optin.nimf"




const requiresDoubleOptIn = true

var optinRouter*: Router


optinRouter.get("/subscribe",
proc(request: Request) =
  if getEnv("ALLOW_GLOBAL_SUBSCRIPTION").toLowerAscii() != "true":
    resp Http200, nimfOptinSubscribe(false, "Please find a subscription list first", "", listUUID = "")

  var defaultListUUID: string
  pg.withConnection conn:
    defaultListUUID = getValue(conn, sqlSelect(
        table = "lists",
        select = ["uuid"],
        where = ["identifier = 'default'"]
      ))
  redirect("/subscribe/" & defaultListUUID)
)


optinRouter.get("/subscribe/optin",
proc(request: Request) =
  let userUUID = @"contactUUID"

  if not userUUID.isValidUUID():
    resp Http200, nimfOptinSubscribeOptin("")

  # Don't allow user-agents that are not browsers
  elif not request.headers.hasKey("User-Agent") or request.headers["User-Agent"] == "":
    resp Http204

  var
    userID: string
    name: string
    email: string

    country: string
    meta: string

  try:
    let
      geoPath = (if getEnv("GEOIP_PATH") != "":
        getEnv("GEOIP_PATH")
      else:
        "/usr/share/GeoIP/GeoIP.dat")
      geo     = GeoIP(geoPath)
    country = $geo.country_name_by_addr(request.ip)
    meta = $( %* { "country": country } )
  except:
    country = ""



  pg.withConnection conn:
    let userData = getRow(conn, sqlSelect(table = "contacts", select = ["id", "name", "email"], where = ["uuid = ?"]), userUUID)

    userID  = userData[0]
    name    = userData[1]
    email   = userData[2]

    if userID == "":
      resp Http200, nimfOptinSubscribe(true, "We could not find your email.. subscribe again.", "")

    exec(conn, sqlUpdate(
        table = "contacts",
        data  = [
          "double_opt_in",
          "double_opt_in_data",
          "meta"
        ],
        where = ["uuid = ?"]),
        "true",
        $(
          %* {
            "ua": $request.headers["User-Agent"],
            "ip": $request.ip,
            "time": $(now().utc).format("yyyy-MM-dd HH:mm:ss")
          }
        ),
        meta,
        userUUID
      )

  moveFromPendingToSubscription(userID)

  let data = %* {
      "success": true,
      "id": userID,
      "name": name,
      "email": email,
      "event": "contact_optedin"
    }

  parseWebhookEvent(contact_optedin, data)

  resp Http200, nimfOptinSubscribeOptin(userUUID)
)


optinRouter.get("/subscribe/@listUUID",
proc(request: Request) =
  resp Http200, nimfOptinSubscribe(true, "", "", listUUID = @"listUUID")
)


optinRouter.post("/subscribe",
proc(request: Request) =

  let
    email = @"email"
    name  = @"name"
    lists = @"lists".split(",")

  if @"username_second" != "":
    resp Http200, nimfOptinSubscribe(true, "", "")

  if not email.isValidEmail():
    resp Http400, nimfOptinSubscribe(true, "Invalid email", "")


  var
    userID: string
    createSuccess: bool
    listsData: tuple[requireOptIn: bool, ids: seq[string]] = (true, @["1"])
  pg.withConnection conn:

    #
    # If we have any pending lists, then get those
    #
    if lists.len() > 0:
      var listsTmp: seq[string]
      for listUUID in lists:
        if listUUID.isValidUUID(): continue
        listsTmp.add(listUUID)

      listsData = listIDsFromUUIDs(listsTmp, true)

    (createSuccess, userID) = createContact(email, name, listsData.requireOptIn, listsData.ids)

  if not createSuccess:
    resp Http200, nimfOptinSubscribe(true, "Contact already exists", "")

  if requiresDoubleOptIn:
    emailOptinSend(email, name, userID)

  let data = %* {
      "success": true,
      "id": userID,
      "requiresDoubleOptIn": listsData.requireOptIn,
      "listIDs": listsData.ids,
      "email": email,
      "name": name,
      "event": "contact_created"
    }

  parseWebhookEvent(contact_created, data)

  resp Http200, nimfOptinSubscribe(false, "", "Succes")
)

optinRouter.get("/unsubscribe",
proc(request: Request) =
  let userUUID = @"contactUUID"

  if not userUUID.isValidUUID():
    resp Http200, nimfOptinUnubscribe("", "", "")

  var userData: seq[string]
  pg.withConnection conn:
    if (
        execAffectedRows(conn, sqlUpdate(
        table = "contacts",
        data  = [
          "double_opt_in",
          "double_opt_in_data",
        ],
        where = ["uuid = ?"]
        ), "false", "", userUUID) > 0
    ):
      userData = getRow(conn, sqlSelect(table = "contacts", select = ["id", "name", "email"], where = ["uuid = ?"]), userUUID)

  if userData[0] == "":
    resp Http200, nimfOptinUnubscribe("", "", "")

  let data = %* {
      "success": true,
      "id": userData[0],
      "name": userData[1],
      "email": userData[2],
      "event": "contact_optedin"
    }

  parseWebhookEvent(contact_optedin, data)

  resp Http200, nimfOptinUnubscribe(userUUID, userData[1], userData[2])
)


