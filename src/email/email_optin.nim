

import
  std/[
    strutils,
    times
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
    mailID: string

  pg.withConnection conn:

    let optMail = getRow(conn, sqlSelect(
      table = "mails",
      select = ["subject", "contentHTML", "id"],
      where = ["identifier = 'double-opt-in'"]
    ))

    if optMail[2] == "":
      echo "No double opt-in mail found"
      return

    subject = optMail[0]
    body = optMail[1]

    mailID = $insertID(conn, sqlInsert(
      table = "pending_emails",
      data  = [
        "user_id",
        "trigger_type",
        "status",
        "mail_id"
      ],
    ), contactID, "optin", "sent", optMail[2])

    hostname = getValue(conn, sqlSelect(
      table = "settings",
      select = ["hostname"],
      where = ["id = 1"]
    ))

    mailUUID = getValue(conn, sqlSelect(
      table = "pending_emails",
      select = ["uuid"],
      where = ["id = ?"]
    ), mailID)

  let sendData = sendMailMimeNow(
    contactID,
    subject, body, email,
    replyTo = "",
    mailUUID = mailUUID,
    ignoreUnsubscribe = true
  )

  if not sendData.success:
    echo "Error sending email"

  # Update the status of the pending email
  pg.withConnection conn:
    exec(conn, sqlUpdate(
      table = "pending_emails",
      data  = [
        "status",
        "message_id",
        "sent_at",
        "updated_at"
      ],
      where = [
        "id = ?"
      ]),
      "sent",
      sendData.messageID,
      $(now().utc).format("yyyy-MM-dd HH:mm:ss"),
      $(now().utc).format("yyyy-MM-dd HH:mm:ss"),
      mailID
    )