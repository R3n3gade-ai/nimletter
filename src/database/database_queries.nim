
import
  std/[
    strutils
  ]

import
  sqlbuilder

import
  ../database/database_connection


type
  PendingMail* = object
    id*: string
    userID*: string
    userName*: string
    userEmail*: string
    messageID*: string
    status*: string
    flowID*: string
    flowStepID*: string
    scheduledFor*: string
    triggerType*: string
    triggerDelay*: int
    stepNumber*: int


proc formatObj(data: seq[string]): PendingMail =
  result = PendingMail(
    id: "",
    userID: "",
    userName: "",
    userEmail: "",
    messageID: "",
    status: "",
    flowID: "",
    flowStepID: "",
    scheduledFor: "",
    triggerType: "",
    triggerDelay: 0,
    stepNumber: 0
  )
  if data[0] == "":
    return result

  return PendingMail(
    id:          data[0],
    userID:      data[1],
    userName:    data[11],
    userEmail:   data[10],
    messageID:   data[2],
    status:      data[3],
    flowID:      data[4],
    flowStepID:  data[5],
    scheduledFor: data[6],
    triggerType:  data[7],
    triggerDelay: (if data[8] != "": data[8].parseInt() else: 0),
    stepNumber:  (if data[9] != "": data[9].parseInt() else: 0),
  )

proc getDataFromPendingEmails*(conn: DbConn, messageID: string): PendingMail =
  let data = getRow(conn, sqlSelect(
      table   = "pending_emails",
      select  = [
        "pending_emails.id",
        "pending_emails.user_id",
        "pending_emails.message_id",
        "pending_emails.status",
        "pending_emails.flow_id",
        "pending_emails.flow_step_id",
        "pending_emails.scheduled_for",
        "flow_steps.trigger_type",
        "flow_steps.delay_minutes",
        "flow_steps.step_number",
        "contacts.email",
        "contacts.name",
      ],
      joinargs = [
        (table: "flow_steps", tableAs: "", on: @["flow_steps.id = pending_emails.flow_step_id"]),
        (table: "contacts", tableAs: "", on: @["contacts.id = pending_emails.user_id"]),
      ],
      where   = ["message_id = ?"]
    ), messageID)

  return formatObj(data)


proc getDataFromPendingEmailsTrigger*(conn: DbConn, flowID, stepNumber, userID: string): PendingMail =

  let data = getRow(conn, sqlSelect(
      table   = "pending_emails",
      select  = [
        "pending_emails.id",
        "pending_emails.user_id",
        "pending_emails.message_id",
        "pending_emails.status",
        "pending_emails.flow_id",
        "pending_emails.flow_step_id",
        "pending_emails.scheduled_for",
        "flow_steps.trigger_type",
        "flow_steps.delay_minutes",
        "flow_steps.step_number",
      ],
      joinargs = [
        (table: "flow_steps", tableAs: "", on: @["flow_steps.id = pending_emails.flow_step_id"]),
      ],
      where   = [
        "pending_emails.flow_id = ?",
        "pending_emails.user_id = ?",
        "pending_emails.status = 'pending'",
        "flow_steps.step_number = ?",
      ]
    ), flowID, userID, stepNumber)

  return formatObj(data)
