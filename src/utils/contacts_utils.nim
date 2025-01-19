


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
          let flowIDs = getValue(conn, sqlSelect(table = "lists", select = ["STRING_AGG(flow_ids, ',')"], where = ["id = ?"]), listID)
          for flowID in flowIDs.split(","):
            createPendingEmailFromFlowstep(userID, listID, flowID, 1)
        else:
          echo "Error subscribing user to list: " & listID

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
      let flowIDs = getValue(conn, sqlSelect(table = "lists", select = ["STRING_AGG(flow_ids, ',')"], where = ["id = ?"]), listID)
      for flowID in flowIDs.split(","):
        createPendingEmailFromFlowstep(userID, listID, flowID, flowStep)
      result = true
    else:
      result = false

  return result


proc createContact*(email, name: string, requiresDoubleOptIn: bool, listIDs: seq[string]): string =
  pg.withConnection conn:
    result = $insertID(conn, sqlInsert(
        table = "contacts",
        data  = [
          "email",
          "name",
          "requires_double_opt_in",
          "pending_lists" & (if listIDs.len() > 0: "" else: " = NULL")
        ]),
        email,
        name,
        $requiresDoubleOptIn,
        (
          if listIDs.len() > 0:
            "{" & listIDs.join(",") & "}"
          else:
            ""
        )
      )