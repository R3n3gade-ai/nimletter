


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
  ../utils/password_utils,
  ../utils/validate_data


include
  "../html/sidebar.nimf",
  "../html/profile.nimf"

var usersRouter*: Router


usersRouter.get("/api/settings/users",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: redirect("/")
  if c.rank != "admin":
    resp Http403, "You are not authorized to view users"

  var data: seq[seq[string]]
  pg.withConnection conn:
    data = getAllRows(conn, sqlSelect(
      table = "users",
      select = ["id", "email", "created_at"]
    ))

  var jsonData: seq[JsonNode]
  for row in data:
    jsonData.add(%* {
      "id": row[0],
      "email": row[1],
      "created_at": row[2]
    })

  resp Http200, %* {
    "success": true,
    "data": jsonData
  }
)

usersRouter.post("/api/users/create",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: redirect("/")
  if c.rank != "admin":
    resp Http403, "You are not authorized to create users"

  let email = @"email"
  let password = @"password"

  if not isValidEmail(email):
    resp Http400, "Invalid email: " & email
  elif password.len() < 6:
    resp Http400, "Password too short"

  let
    salt = makeSalt()
    passwordCreated = makePassword(password, salt)

  pg.withConnection conn:
    exec(conn, sqlInsert(
      table = "users",
      data = [
        "email",
        "password",
        "salt"
      ]
    ), email, passwordCreated, salt)

  resp Http200, (
    %* {
      "success": true,
      "message": "User created successfully"
    }
  )
)

usersRouter.delete("/api/users/delete",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: redirect("/")
  if c.rank != "admin":
    resp Http403, "You are not authorized to delete users"

  let userID = @"userID"

  var success = false
  pg.withConnection conn:
    # Check if the user has the lowest ID
    let lowestId = getValue(conn, sqlSelect(
      table = "users",
      select = ["MIN(id) as min_id"]
    ))

    let rank = getValue(conn, sqlSelect(
      table = "users",
      select = ["rank"],
      where = ["id = ?"]
    ), userID)

    # Only delete if the user is not the one with the lowest ID
    if userID != lowestId and rank != "admin":
      exec(conn, sqlDelete(
        table = "users",
        where = ["id = ?"]
      ), userID)
      success = true
    else:
      success = false

  if success:
    resp Http200, "User deleted successfully"
  else:
    resp Http400, "Cannot delete this user"
)