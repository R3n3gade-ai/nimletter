
import
  std/[
    json,
    strutils
  ]

from std/os import getEnv


import
  mummy, mummy/routers,
  mummy_utils


import
  awsSES_SNS,
  sqlbuilder


import
  ../database/database_connection,
  ../database/database_queries,
  ../scheduling/schedule_mail,
  ../utils/auth,
  ../webhook/webhook_events



proc updateUserBounce(mail: MailBounce) =

  var mailData: PendingMail
  pg.withConnection conn:
    mailData = getDataFromPendingEmails(conn, mail.messageID)

    exec(conn, sqlUpdate(
      table = "contacts",
      data  = [
        "bounced_at = CURRENT_TIMESTAMP",
      ],
      where = "id = ?"
    ), mailData.userID)

    exec(conn, sqlUpdate(
      table = "pending_emails",
      data  = [
        "status = 'bounced'",
        "updated_at = CURRENT_TIMESTAMP",
      ],
      where = "id = ?"
    ), mailData.id)

    exec(conn, sqlInsert(
      table = "email_bounces",
      data  = [
        "pending_email_id",
        "user_id",
        "bounces_at = CURRENT_TIMESTAMP",
        "bounce_type",
        "bounce_sub_type",
        "diagnostic_code",
        "status",
        "message_id",
      ]),
      mailData.id, mailData.userID, mail.bounceType, mail.bounceSubType, mail.diagnosticCode, mail.status, mail.messageID
    )

  let data = %* {
      "success": true,
      "bounceType": mail.bounceType,
      "bounceSubType": mail.bounceSubType,
      "email": mailData.userEmail,
      "username": mailData.userName,
      "status": mail.status,
      "diagnosticCode": mail.diagnosticCode,
      "messageID": mail.messageID,
      "event": "email_bounced"
    }

  parseWebhookEvent(email_bounced, data)


proc updateUserComplaint(mail: MailComplaint) =

  var mailData: PendingMail
  pg.withConnection conn:
    mailData = getDataFromPendingEmails(conn, mail.messageID)

    exec(conn, sqlUpdate(
      table = "contacts",
      data  = [
        "complained_at = CURRENT_TIMESTAMP",
      ],
      where = "id = ?"
    ), mailData.userID)

    exec(conn, sqlUpdate(
      table = "pending_emails",
      data  = [
        "status = 'complained'",
        "updated_at = CURRENT_TIMESTAMP",
      ],
      where = "id = ?"
    ), mailData.id)

    exec(conn, sqlInsert(
      table = "email_complaints",
      data  = [
        "pending_email_id",
        "user_id",
        "complained_at = CURRENT_TIMESTAMP",
        "complaint_feedback_type",
        "message_id",
      ]),
      mailData.id, mailData.userID, mail.complaintFeedbackType, mail.messageID
    )

  let data = %* {
      "success": true,
      "complaintFeedbackType": mail.complaintFeedbackType,
      "arrivalDate": mail.arrivalDate,
      "email": mailData.userEmail,
      "username": mailData.userName,
      "messageID": mail.messageID,
      "event": "email_complained"
    }

  parseWebhookEvent(email_complained, data)


proc updateUserOpen(mail: MailOpen) =

  var
    match: bool
    triggerData: PendingMail
    mailData: PendingMail

  pg.withConnection conn:
    mailData = getDataFromPendingEmails(conn, mail.messageID)
    if mailData.id == "":
      echo "No pending email found"
    else:
      match = true

    if match:
      exec(conn, sqlInsert(
        table = "email_opens",
        data  = [
          "pending_email_id",
          "user_id",
          "device_info",
          "ip_address",
          "message_id",
        ]),
        mailData.id,
        mailData.userID,
        mail.userAgent,
        mail.ipAddress,
        mail.messageID
      )

      #
      # Do we have a trigger for this click?
      #
      triggerData = getDataFromPendingEmailsTrigger(
                  conn, mailData.flowID, $(mailData.stepNumber + 1), mailData.userID)

  if match and triggerData.triggerType == "open" and triggerData.status == "pending":
    triggerScheduleEmail(triggerData)


  let data = %* {
      "success": true,
      "userAgent": mail.userAgent,
      "email": mailData.userEmail,
      "username": mailData.userName,
      "messageID": mail.messageID,
      "event": "email_opened"
    }

  parseWebhookEvent(email_opened, data)


proc updateUserClick(mail: MailClick) =

  var
    match: bool
    triggerData: PendingMail

  pg.withConnection conn:
    let mailData = getDataFromPendingEmails(conn, mail.messageID)
    if mailData.id == "":
      echo "No pending email found"
    else:
      match = true

    if match:
      exec(conn, sqlInsert(
        table = "email_clicks",
        data  = [
          "pending_email_id",
          "user_id",
          "device_info",
          "ip_address",
          "link_url",
          "message_id",
        ]),
        mailData.id,
        mailData.userID,
        mail.userAgent,
        mail.ipAddress,
        mail.link,
        mail.messageID
      )

      #
      # Do we have a trigger for this click?
      #
      triggerData = getDataFromPendingEmailsTrigger(
                  conn, mailData.flowID, $(mailData.stepNumber + 1), mailData.userID)

  if match and triggerData.triggerType == "click" and triggerData.status == "pending":
    triggerScheduleEmail(triggerData)


var webhooksSnsRouter*: Router

webhooksSnsRouter.post("/webhook/incoming/sns/@key",
proc(request: Request) =
  when defined(dev):
    echo "Received SNS webhook"

  if @"key" != getEnv("SNS_WEBHOOK_SECRET", "secret"):
    resp Http400

  let (snsSuccess, snsMsg) = snsParseJson(request.body)
  if not snsSuccess:
    echo "Error parsing SNS JSON"
    echo request.body
    resp Http400


  # Case through the different types of events
  case snsParseEventType(snsMsg)
  of SNSSubscriptionConfirmation:
    let sub = snsSubscriptionConfirmation(snsMsg)
    echo sub.message
    echo sub.subscribeURL


  of Bounce:
    let mailBounce = snsParseBounce(snsMsg)
    for mail in mailBounce:
      updateUserBounce(mail)


  of Complaint:
    let mailComplaint = snsParseComplaint(snsMsg)
    for mail in mailComplaint:
      updateUserComplaint(mail)


  of Delivery:
    let mailDelivery = snsParseDelivery(snsMsg)
    echo $mailDelivery.email & " - " & mailDelivery.messageID


  of Open:
    let mailOpen = snsParseOpen(snsMsg)
    updateUserOpen(mailOpen)


  of Click:
    let mailClick = snsParseClick(snsMsg)
    updateUserClick(mailClick)


  else:
    echo "Unknown event type"

  resp Http200

)