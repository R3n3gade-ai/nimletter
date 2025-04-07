
import
  std/[
    os,
    strutils,
    times
  ]

import
  sqlbuilder

import
  ../database/database_connection,
  ../database/database_queries,
  ../email/email_connection,
  ../scheduling/schedule_mail


type
  PendingMailObj* = object
    id*: string
    uuid*: string
    userID*: string
    listID*: string
    flowID*: string
    flowStepID*: string
    triggerType*: string
    scheduledFor*: string
    status*: string
    messageID*: string
    createdAt*: string
    updatedAt*: string
    mailID*: string
    manualHTML*: string
    manualSubject*: string

var
  mailChannel*: Channel[PendingMailObj]
  mailThread*: Thread[void]

proc scheduleNextFlowStep(pendingEmail: PendingMailObj, stepNumber: string) =
  createPendingEmailFromFlowstep(
    pendingEmail.userID, pendingEmail.listID, pendingEmail.flowID,
    (parseInt(stepNumber) + 1)
  )


proc getUserData(userID: string): seq[string] =
  pg.withConnection conn:
    return getRow(conn, sqlSelect(
      table = "contacts",
      select = [
        "id",
        "email",
        "name"
      ],
      where = [
        "id = ?"
      ]
    ), userID)



proc getMailData(flowStepID: string): string =
  pg.withConnection conn:
    return getValue(conn, sqlSelect(
      table = "flow_steps",
      select = [
        "flow_steps.step_number",
      ],
      where = [
        "flow_steps.id = ?"
      ]
    ), flowStepID)



proc sendPendingEmail(pendingEmail: PendingMailObj) =
  # Fetch user and email details
  let userData = getUserData(pendingEmail.userID)

  var mailData: seq[string]
  if pendingEmail.manualHTML != "":
    mailData = @[pendingEmail.manualSubject, pendingEmail.manualHTML]

  else:
    pg.withConnection conn:
      mailData = getRow(conn, sqlSelect(
        table = "mails",
        select = [
          "subject",
          "contentHTML",
        ],
        where = [
          "id = ?"
        ]
      ), pendingEmail.mailID)


  # Send the email
  let sendData = sendMailMimeNow(
    contactID = pendingEmail.userID,
    subject = (if pendingEmail.manualSubject.len > 0: pendingEmail.manualSubject else: mailData[0]),
    message = mailData[1],
    recipient = userData[1],
    mailUUID = pendingEmail.uuid
  )

  if not sendData.success:
    echo "Failed to send email: mailID = " & pendingEmail.id & " - Err = " & sendData.messageID
    return

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
      pendingEmail.id
    )

  # Schedule the next flow step if applicable
  if pendingEmail.flowStepID != "":
    scheduleNextFlowStep(pendingEmail, getMailData(pendingEmail.flowStepID))

  sleep((1000 / sendData.mailsPerSecond).toInt())



proc mailPendingEmails*() {.thread.} =
  echo "Starting thread: mail"
  while true:
    let msg = mailChannel.recv()
    sendPendingEmail(msg)
