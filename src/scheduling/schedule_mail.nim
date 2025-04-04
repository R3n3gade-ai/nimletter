
import
  std/[
    strutils,
    times
  ]

import
  sqlbuilder

import
  ../database/database_connection,
  ../database/database_queries



proc triggerScheduleEmail*(pendingEmail: PendingMail) =
  when defined(dev):
    echo "Triggering email with ID " & pendingEmail.id

  let scheduledFor = now().utc + (
    if pendingEmail.triggerDelay == 0:
      1.minutes
    else:
      pendingEmail.triggerDelay.minutes
    )

  pg.withConnection conn:
    exec(conn, sqlUpdate(
      table = "pending_emails",
      data  = [
        "scheduled_for",
        "updated_at"
      ],
      where = [
        "id = ?",
        "scheduled_for IS NULL",
        "status = 'pending'"
      ]),
        scheduledFor,
        $(now().utc).format("yyyy-MM-dd HH:mm:ss"),
        pendingEmail.id
    )


proc createPendingEmail*(
  userID, listID, flowID, flowStepID, mailID: string,
  triggerType: string = "delay",
  scheduledFor: DateTime = now().utc,
  status: string = "pending",
  manualSubject: string = "",
) =

  let scheduledFor = (
      if triggerType == "delay":
        $scheduledFor.format("yyyy-MM-dd HH:mm:ss")
      elif triggerType == "immediate":
        $(now().utc).format("yyyy-MM-dd HH:mm:ss")
      else:
        "NULL"
    )

  var args = @[userID]
  var data = @["user_id"]
  if listID != "":
    data.add("list_id")
    args.add(listID)
  if flowID != "":
    data.add("flow_id")
    args.add(flowID)
  if flowStepID != "":
    data.add("flow_step_id")
    args.add(flowStepID)
  if mailID != "":
    data.add("mail_id")
    args.add(mailID)
  if triggerType != "":
    data.add("trigger_type")
    args.add(triggerType)
  if status != "":
    data.add("status")
    args.add(status)
  if scheduledFor != "NULL":
    data.add("scheduled_for")
    args.add(scheduledFor)
  if manualSubject != "":
    data.add("manual_subject")
    args.add(manualSubject)

  pg.withConnection conn:
    exec(conn, sqlInsert(
      table = "pending_emails",
      data  = data,
    ), args)


proc createPendingEmailFromFlowstep*(userID, listID, flowID: string, stepNumber: int) =

  when defined(dev):
    echo "Creating pending email from flowID " & flowID & " and step " & $stepNumber

  var flowStep: seq[string]
  pg.withConnection conn:
    flowStep = getRow(conn, sqlSelect(
      table   = "flow_steps",
      select  = @[
        "id",
        "mail_id",
        "step_number",
        "trigger_type",
        "delay_minutes",
        "subject"
      ],
      where = [
        "flow_id = ?",
        "step_number = ?"
      ]
    ), flowID, stepNumber)

  if flowStep[0] == "":
    echo "Flow end reached"
    return

  createPendingEmail(
    userID = userID,
    listID = listID,
    flowID = flowID,
    flowStepID = flowStep[0],
    mailID = flowStep[1],
    triggerType = flowStep[3],
    scheduledFor = (now().utc + parseInt(flowStep[4]).minutes),
    status = "pending",
    manualSubject = flowStep[5]
  )


proc createPendingEmailToAllListContacts*(listID, mailID: string) =

  var contacts: seq[seq[string]]
  pg.withConnection conn:
    contacts = getAllRows(conn, sqlSelect(
      table = "subscriptions",
      select = ["user_id"],
      where = ["list_id = ?"]
    ), listID)

  for contact in contacts:
    createPendingEmail(
      userID = contact[0],
      listID = listID,
      flowID = "",
      flowStepID = "",
      mailID = mailID,
      triggerType = "immediate",
      status = "pending"
    )