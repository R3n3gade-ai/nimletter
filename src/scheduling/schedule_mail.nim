
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

  let scheduledFor = now() + (
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
  scheduledFor: DateTime = now(),
  status: string = "pending",
) =

  let scheduledFor = (
      if triggerType == "delay":
        $scheduledFor.format("yyyy-MM-dd HH:mm:ss")
      elif triggerType == "immediate":
        $(now().utc).format("yyyy-MM-dd HH:mm:ss")
      else:
        "NULL"
    )

  let argsData = @[
        userID,
        listID,
        flowID,
        flowStepID,
        mailID,
        triggerType,
        status,
        scheduledFor
      ]

  var args  = @[
        userID,
        listID,
        flowID,
        flowStepID,
        mailID,
        triggerType,
        status
      ]
  if scheduledFor != "NULL":
    args.add(scheduledFor)

  pg.withConnection conn:

    exec(conn, sqlInsert(
      table = "pending_emails",
      data  = [
        "user_id",
        "list_id",
        "flow_id",
        "flow_step_id",
        "mail_id",
        "trigger_type",
        "status",
        "scheduled_for",
      ],
      args = argsData
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
        "delay_minutes"
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
    scheduledFor = (now() + parseInt(flowStep[4]).minutes),
    status = "pending"
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