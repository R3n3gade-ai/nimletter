


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


var subscriptionsRouter*: Router

subscriptionsRouter.post("/api/subscriptions/create",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    userID = @"userID"
    listID = @"listID"

  if not userID.isValidInt() or not listID.isValidInt():
    resp Http400, "Invalid user ID or list ID"

  pg.withConnection conn:
    exec(conn, sqlInsert(
        table = "subscriptions",
        data  = [
          "user_id",
          "list_id",
        ]),
        userID, listID
      )

  resp Http200
)


subscriptionsRouter.post("/api/subscriptions/delete",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  let
    userID = @"userID"
    listID = @"listID"

  if not userID.isValidInt() or not listID.isValidInt():
    resp Http400, "Invalid user ID or list ID"

  pg.withConnection conn:
    exec(conn, sqlDelete(
        table = "subscriptions",
        where = ["user_id = ? AND list_id = ?"]),
      userID, listID)

  resp Http200
)
