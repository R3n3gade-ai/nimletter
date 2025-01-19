
import
  std/[
    strutils,
    times
  ]


import
  sqlbuilder

import
  ../database/database_connection,
  ../database/database_queries,
  ../scheduling/schedule_mail


proc scheduleNextFlowStep(pendingEmail: PendingMail) =
  var nextStep: seq[string]

  pg.withConnection conn:
    nextStep = getRow(conn, sqlSelect(
      table   = "flow_steps",
      select  = [
        "id",
        "delay_minutes",
        "trigger_type"
      ],
      where   = [
        "flow_id = ?",
        "step_number = (SELECT step_number + 1 FROM flow_steps WHERE id = ?)"
      ],
    ), pendingEmail.flowID, pendingEmail.flowStepID)


  if nextStep.len > 0:
    let
      nextStepID    = nextStep[0].parseInt()
      delayMinutes  = nextStep[1].parseInt()
      triggerType   = nextStep[2]

    if triggerType == "delay":
      discard

    elif triggerType == "open":
      scheduleMailSetScheduledFor(pendingEmail)

    elif triggerType == "click":
      discard


# Example usage in email open handler
proc triggerEmailOpen*(pendingEmail: PendingMail) =

  if pendingEmail.hasTrigger:
    scheduleNextFlowStep(pendingEmail)