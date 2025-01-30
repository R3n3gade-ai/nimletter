


import
  std/[
    algorithm,
    json,
    sequtils,
    strutils,
    tables,
    times
  ]

from std/os import getEnv

import
  mmgeoip,
  sqlbuilder


import
  ../database/database_connection,
  ../scheduling/schedule_mail


proc getCountryFromIP(ip: string): string =
  if ip == "":
    return ""

  try:
    let
      geoPath = (
        if getEnv("GEOIP_PATH") != "":
          getEnv("GEOIP_PATH")
        else:
          "/usr/share/GeoIP/GeoIP.dat"
        )

      geo     = GeoIP(geoPath)
    return $geo.country_name_by_addr(ip)

  except:
    return ""


proc createMetaWithCountry*(ip: string): string =
  let country = getCountryFromIP(ip)
  if country == "":
    return "{}"
  return $( %* { "country": country } )


proc moveFromPendingToSubscription*(userID: string) =
  # Get pending lists, and then loop and add to subscriptions
  pg.withConnection conn:
    let pendingListsData = getValue(conn, sqlSelect(
        table = "contacts",
        select = ["pending_lists"],
        where = ["id = ?"]
      ), userID)

    if pendingListsData != "":
      let lists = pendingListsData.strip(chars={'{', '}'}).split(",")
      if lists.len() == 0 or lists[0] == "":
        return

      for listID in lists:
        try:
          if execAffectedRows(conn, sqlInsert(
              table = "subscriptions",
              data  = [
                "user_id",
                "list_id",
              ]),
              userID, listID
          ) > 0:
            #
            # User subscribed to list, create pending email
            #
            let flowIDs = getValue(conn, sqlSelect(table = "lists", select = ["array_to_string(flow_ids, ',')"], where = ["id = ?"]), listID)
            for flowID in flowIDs.split(","):
              if flowID == "":
                continue
              createPendingEmailFromFlowstep(userID, listID, flowID, 1)
          else:
            echo "Error subscribing user to list: " & listID
        except:
          continue

    # Set pendling_list to NULL
    exec(conn, sqlUpdate(
        table = "contacts",
        data  = [
          "pending_lists = NULL",
          "updated_at = ?"
        ],
        where = ["id = ?"]
      ),
      $now().utc, userID
    )


proc addContactToPendinglist*(userID, listID: string): bool =
  pg.withConnection conn:
    exec(conn, sqlUpdate(
        table = "contacts",
        data  = [
          "pending_lists = array_append(pending_lists, ?)",
          "updated_at",
        ],
        where = ["id = ?"]
      ), listID, $now().utc, userID
    )
  return true


proc addContactToList*(userID, listID: string, flowStep = 1): bool =
  pg.withConnection conn:
    if execAffectedRows(conn, sqlInsert(
        table = "subscriptions",
        data  = [
          "user_id",
          "list_id",
        ]),
        userID, listID
    ) > 0:
      let flowIDs = getValue(conn, sqlSelect(table = "lists", select = ["array_to_string(flow_ids, ',')"], where = ["id = ?"]), listID)
      for flowID in flowIDs.split(","):
        if flowID == "":
          continue
        createPendingEmailFromFlowstep(userID, listID, flowID, flowStep)
      result = true
    else:
      result = false

  return result


proc createContact*(email, name: string, requiresDoubleOptIn: bool, listIDs: seq[string], ip: string = ""): (bool, string) =

  var
    userID: string
    success: bool
  pg.withConnection conn:
    if getValue(conn, sqlSelect(
        table = "contacts",
        select = ["id"],
        where = ["email = ?"]
    ), email) != "":
      return (false, "Contact already exists")

    success = true
    userID = $insertID(conn, sqlInsert(
        table = "contacts",
        data  = [
          "email",
          "name",
          "requires_double_opt_in",
          "meta",
          "pending_lists" & (if requiresDoubleOptIn and listIDs.len() > 0: "" else: " = NULL"),
        ]),
        email,
        name,
        $requiresDoubleOptIn,
        createMetaWithCountry(ip),
        (
          if requiresDoubleOptIn and listIDs.len() > 0:
            "{" & listIDs.join(",") & "}"
          else:
            ""
        )
      )

  return (success, userID)