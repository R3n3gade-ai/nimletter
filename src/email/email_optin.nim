

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
    mailUUID: string

  pg.withConnection conn:
    let mailID = $insertID(conn, sqlInsert(
      table = "pending_emails",
      data  = [
        "user_id",
        "trigger_type",
        "status",
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

    mailUUID = getValue(conn, sqlSelect(
      table = "pending_emails",
      select = ["uuid"],
      where = ["id"]
    ), mailID)

  let data = sendMailMimeNow(
    contactID,
    subject, body, email,
    replyTo = "",
    mailUUID = mailUUID,
    ignoreUnsubscribe = true
  )

  if not data.success:
    echo "Error sending email"