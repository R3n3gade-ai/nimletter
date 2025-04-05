
import
  std/[
    json,
    strtabs,
    strutils,
    times
  ]


import
  mummy, mummy/routers,
  mummy_utils


import
  sqlbuilder,
  yubikey_otp


import
  ../database/database_connection,
  ../utils/password_utils


type
  UserData* = ref object
    userID*: string
    loggedIn*: bool
    req*: Request
    sessionkey*: string
    loggedInTime*: int
    rank*: string

  CookieSessionName* = enum
    Default = "sidletter"


proc insertIntoSessions*(userID, token: string) =
  pg.withConnection conn:
    exec(conn, sqlInsert(
      table = "sessions",
      data  = ["token", "user_id"],
    ), token, userID)

proc checkApikey*(apikey: string): bool =
  var user: seq[string]
  pg.withConnection conn:
    user = getRow(conn, sqlSelect(
      table   = "api_keys",
      select  = ["id"],
      where   = ["key = ?"],
    ), apikey)

  return user.len > 0



proc checkPasswordAndOTP*(email, password, yubikeyOTP: string): tuple[userID: string, passwordOK: bool, otpOK: bool, otpRequired: bool, rank: string] =
  var user: seq[string]
  pg.withConnection conn:
    user = getRow(conn, sqlSelect(
      table   = "users",
      select  = ["id", "password", "salt", "yubikey_public", "yubikey_clientid", "rank"],
      where   = ["email = ?"],
    ), email)

  if user.len == 0 or user[0] == "":
    return ("", false, false, false, "")

  # YK not enabled
  let passOK = (user[1] == makePassword(password, user[2], user[1]))
  if user[3] == "":
    return (user[0], passOK, false, false, user[5])

  if yubikeyOTP == "":
    return (user[0], passOK, false, true, user[5])


  # YK enabled
  if yubikeyOTP.len != 44:
    return (user[0], passOK, false, true, user[5])

  let
    userID           = user[0]
    yubikeyPublicIDs = user[3]
    yubikeyClientID  = user[4]

  #
  # Get publicID from current OTP
  #
  let currentPublicID = yubikeyExtractPublicID(yubikeyOTP)
  if currentPublicID == "":
    return (user[0], passOK, false, true, user[5])

  #
  # Parse DB publicIDs to JSON
  #
  var ykJson: JsonNode
  try:
    ykJson = parseJson(yubikeyPublicIDs)
  except:
    return (user[0], passOK, false, true, user[5])

  #
  # Check if current publicID is in the DB
  #
  var ykPublicIDConfirmed = false
  for yk in ykJson:
    if yk["publicid"].getStr() == currentPublicID:
      ykPublicIDConfirmed = true
      break

  if not ykPublicIDConfirmed:
    return (user[0], passOK, false, true, user[5])

  #
  # Validate OTP in Yubikey API
  #
  let yubikeyApproved = yubikeyValidate(yubikeyClientID, currentPublicID, yubikeyOTP)
  if not yubikeyApproved:
    return (user[0], passOK, yubikeyApproved, true, user[5])

  #
  # Update last used publicID
  #
  var ykJsonNew: JsonNode = parseJson("[]")
  for yk in ykJson:
    if yk["publicid"].getStr() == currentPublicID:
      yk["lastUsed"]    = toInt(epochTime()).newJInt()
      yk["usedCount"]   = (if yk.hasKey("usedCount"): yk["usedCount"].getInt() + 1 else: 1).newJInt()
      ykJsonNew.add(yk)
    else:
      ykJsonNew.add(yk)

  pg.withConnection conn:
    exec(conn, sqlUpdate(
        table = "users",
        data  = ["yubikey_public"],
        where = ["id"]
      ), $ykJsonNew, userID)

  return (user[0], passOK, yubikeyApproved, true, user[5])



template loginSetCookie*(c: var UserData) =
  var
    cookieNaming = $CookieSessionName.Default
    cookieSameSite = Lax
    cookieDaysForward = getTime().utc + initTimeInterval(days = 7) #daysForward(loginTimeInDays)

  when defined(dev):
    setCookie(key = cookieNaming, value = c.sessionkey, expires = cookieDaysForward, sameSite = cookieSameSite, secure = false, httpOnly = true, path = "/")
  else:
    setCookie(key = cookieNaming, value = c.sessionkey, expires = cookieDaysForward, sameSite = cookieSameSite, secure = true, httpOnly = true, path = "/")





proc checkLoggedIn*(c: var UserData) =

  var apiCall = false

  if c.req.headers.hasKey("Authorization") or c.req.params.hasKey("Authorization"):
    apiCall = true

    let auth =
      if c.req.headers.hasKey("Authorization"):
        c.req.headers["Authorization"].split(" ")
      else:
        c.req.params["Authorization"].split("-")

    if auth.len() != 2:
      return

    if not checkApikey(auth[1]):
      return

    # Inc api_keys.count with +1
    pg.withConnection conn:
      exec(conn, sqlUpdate(
        table = "api_keys",
        data  = ["count = count + 1"],
        where = ["key = ?"]
      ), auth[1])


  else:
    var cookieNaming: string # = $CookieSessionName.Default

    for cookieName in CookieSessionName:
      if c.req.cookies.hasKey($cookieName):
        cookieNaming = $cookieName
        break

    if cookieNaming == "": #not c.req.cookies.hasKey(cookieNaming):
      return

    c.sessionkey = c.req.cookies[cookieNaming]

    var userFoundInSessionTable: int64
    pg.withConnection conn:
      userFoundInSessionTable = execAffectedRows(conn, sqlUpdate(
            table = "sessions",
            data = ["updated_at = CURRENT_TIMESTAMP"],
            where = ["token = ? AND expires_at > CURRENT_TIMESTAMP - INTERVAL '7 days'"]
          ), c.sessionkey)

    if userFoundInSessionTable <= 0:
      return

  if not apiCall:
    pg.withConnection conn:
      c.userID = getValue(conn, sqlSelect(
        table = "sessions",
        select = ["user_id"],
        where = ["token = ?"],
      ), c.sessionkey)

  c.loggedIn = true
  c.loggedInTime = toInt(epochTime())
  pg.withConnection conn:
    c.rank = getValue(conn, sqlSelect(
      table = "users",
      select = ["rank"],
      where = ["id = ?"],
    ), c.userID)


func isLoggedIn*(c: UserData): bool =
  return c.loggedIn


template createTFD*() =
  var c {.inject.}: UserData
  new(c)
  c.loggedIn = false
  c.req = request

  if (
    cookies(request).len > 0 or
    c.req.headers.hasKey("Authorization") or
    c.req.params.hasKey("Authorization")
  ):
    checkLoggedIn(c)


template authorizeOrDeny*(c: UserData, redirect = false) =
  if not isLoggedIn(c):
    if redirect:
      redirect("/login")
    elif c.req.httpMethod == HttpPost:
      resp Http401
    elif c.req.httpMethod == HttpGet:
        resp Http401