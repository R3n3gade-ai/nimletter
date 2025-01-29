## This file is called every 5 minutes to check if there are any new scheduled
## emails that need to be sent.
## It will send the email, if there's new email to be sent (from the flow) they
## will be added to the pending_emails table.

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
  PendingMailObj = object
    id: string
    uuid: string
    userID: string
    listID: string
    flowID: string
    flowStepID: string
    triggerType: string
    scheduledFor: string
    status: string
    messageID: string
    createdAt: string
    updatedAt: string


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



proc getMailData(flowStepID: string): seq[string] =
  pg.withConnection conn:
    return getRow(conn, sqlSelect(
      table = "flow_steps",
      select = [
        "flow_steps.subject",
        "flow_steps.step_number",
        "mails.contentHTML",
      ],
      joinargs = [
        (table: "mails", tableAs: "", on: @["mails.id = flow_steps.mail_id"])
      ],
      where = [
        "flow_steps.id = ?"
      ]
    ), flowStepID)



proc sendPendingEmail(pendingEmail: PendingMailObj) =
  # Fetch user and email details
  let
    userData = getUserData(pendingEmail.userID)

  let
    mailData = getMailData(pendingEmail.flowStepID)


  # Send the email
  let sendData = sendMailMimeNow(
    # pendingEmailID = pendingEmail.id,
    contactID = pendingEmail.userID,
    subject = mailData[0],
    message = mailData[2],
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
  scheduleNextFlowStep(pendingEmail, mailData[1])

  sleep((1000 / sendData.mailsPerSecond).toInt())


proc checkAndSendScheduledEmails*(minutesBack = 5) =
  var pendingEmails: seq[seq[string]]

  pg.withConnection conn:
    let timeThreshold = (now() - initDuration(minutes = minutesBack)).format("yyyy-MM-dd HH:mm:ss")
    when defined(dev):
      echo "Scheduling duration: " & $timeThreshold & " < > " & $now().format("yyyy-MM-dd HH:mm:ss")

    pendingEmails = getAllRows(conn, sqlSelect(
        table = "pending_emails",
        select = [
          "pending_emails.id",
          "pending_emails.user_id",
          "pending_emails.list_id",
          "pending_emails.flow_id",
          "pending_emails.flow_step_id",
          "pending_emails.trigger_type",
          "pending_emails.scheduled_for",
          "pending_emails.status",
          "pending_emails.message_id",
          "pending_emails.created_at",
          "pending_emails.updated_at",
          "pending_emails.uuid"
        ],
        where = [
          "pending_emails.scheduled_for <= NOW()",
          "pending_emails.scheduled_for >= ?",
          "pending_emails.status = 'pending'"
        ]
      ),
      timeThreshold
    )

  for pendingEmail in pendingEmails:
    echo "Sending email: " & pendingEmail[0]
    sendPendingEmail(PendingMailObj(
      id: pendingEmail[0],
      userID: pendingEmail[1],
      listID: pendingEmail[2],
      flowID: pendingEmail[3],
      flowStepID: pendingEmail[4],
      triggerType: pendingEmail[5],
      scheduledFor: pendingEmail[6],
      status: pendingEmail[7],
      messageID: pendingEmail[8],
      createdAt: pendingEmail[9],
      updatedAt: pendingEmail[10],
      uuid: pendingEmail[11]
    ))
