

import
  std/[
    strutils
  ]

import
  sqlbuilder

import
  ../database/database_connection

import
  ./email_connection,
  ./email_variables

proc emailOptinSend*(email, name, contactID: string) =

  var
    hostname:string
    body: string
    subject: string

  pg.withConnection conn:
    exec(conn, sqlInsert(
      table = "pending_emails",
      data  = [
        "user_id",
        "trigger_type",
        /"status",
      ],
    ), contactID, "optin", "sent")

    let optMail = getRow(conn, sqlSelect(
      table = "mails",
      select = ["subject", "contentHTML"],
      where = ["identifier = 'double-opt-in'"]
    ))

    subject = optMail[0]
    body = optMail[1]

    hostname = getValue(conn, sqlSelect(
      table = "settings",
      select = ["hostname"],
      where = ["id = 1"]
    ))

  let message = emailVariableReplace(contactID, body, subject, ignoreUnsubscribe = true)

  let data = sendMailMimeNow(
    contactID,
    subject, message, email,
    replyTo = "",
    ignoreUnsubscribe = true
  )

  if not data.success:
    echo "Error sending email"