import
  std/[
    json,
    strutils,
    times
  ]

import
  mummy, mummy/routers,
  mummy_utils

import
  sqlbuilder

import
  ../database/database_connection,
  ../utils/auth,
  ../utils/validate_data


var analyticsRouter*: Router

analyticsRouter.get("/api/analytics/mails",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401

  var data: seq[seq[string]]
  var dataPending: seq[seq[string]]
  var openData: seq[seq[string]]
  var clickData: seq[seq[string]]
  pg.withConnection conn:
    data = getAllRows(conn, sqlSelect(
        table = "pending_emails",
        select = [
          "to_char(date_trunc('day', scheduled_for), 'YYYY-MM-DD') AS day",
          "COUNT(*) FILTER (WHERE status = 'pending') AS pending",
          "COUNT(*) FILTER (WHERE status = 'sent') AS sent",
          "COUNT(*) FILTER (WHERE status = 'bounced') AS bounced",
          "COUNT(*) FILTER (WHERE status = 'complained') AS complained"
        ],
        customSQL = """
          WHERE scheduled_for >= current_date - interval '20 days'
          AND scheduled_for <= current_date + interval '7 days'
          GROUP BY day
          ORDER BY day
        """
      ))

    dataPending = getAllRows(conn, sqlSelect(
        table = "pending_emails",
        select = [
          "to_char(date_trunc('day', scheduled_for), 'YYYY-MM-DD') AS day",
          "COUNT(*) FILTER (WHERE status = 'pending') AS pending"
        ],
        customSQL = """
          WHERE scheduled_for >= current_date - interval '20 days'
          AND scheduled_for <= current_date + interval '7 days'
          GROUP BY day
          ORDER BY day
        """
      ))

    openData = getAllRows(conn, sqlSelect(
        table = "email_opens",
        select = [
          "to_char(date_trunc('day', opened_at), 'YYYY-MM-DD') AS day",
          "COUNT(DISTINCT pending_email_id) AS opened"
        ],
        customSQL = """
          WHERE opened_at >= current_date - interval '20 days'
          AND opened_at <= current_date + interval '7 days'
          GROUP BY day
          ORDER BY day
        """
      ))

    clickData = getAllRows(conn, sqlSelect(
        table = "email_clicks",
        select = [
          "to_char(date_trunc('day', clicked_at), 'YYYY-MM-DD') AS day",
          "COUNT(DISTINCT pending_email_id) AS clicked"
        ],
        customSQL = """
          WHERE clicked_at >= current_date - interval '20 days'
          AND clicked_at <= current_date + interval '7 days'
          GROUP BY day
          ORDER BY day
        """
      ))

  var
    pending: seq[int] = @[]
    sent: seq[int] = @[]
    bounced: seq[int] = @[]
    complained: seq[int] = @[]
    opened: seq[int] = @[]
    clicked: seq[int] = @[]
    days: seq[string] = @[]

  var startDate = (now() - 20.days()).format("YYYY-MM-dd")
  var endDate = (now() + 7.days()).format("YYYY-MM-dd")
  var currentDate = startDate.parse("YYYY-MM-dd")

  while currentDate <= endDate.parse("YYYY-MM-dd"):
    let dayStr = currentDate.format("YYYY-MM-dd")
    days.add(dayStr)
    pending.add(0)
    sent.add(0)
    bounced.add(0)
    complained.add(0)
    opened.add(0)
    clicked.add(0)
    currentDate = currentDate + 1.days()

  for row in data:
    let idx = days.find(row[0])
    if idx >= 0:
      #pending[idx] = row[1].parseInt
      sent[idx] = row[2].parseInt
      bounced[idx] = row[3].parseInt
      complained[idx] = row[4].parseInt

  for row in dataPending:
    let idx = days.find(row[0])
    if idx >= 0:
      pending[idx] = row[1].parseInt

  for row in openData:
    let idx = days.find(row[0])
    if idx >= 0:
      opened[idx] = row[1].parseInt

  for row in clickData:
    let idx = days.find(row[0])
    if idx >= 0:
      clicked[idx] = row[1].parseInt

  resp Http200, %*{
    "days": days,
    "pending": pending,
    "sent": sent,
    "bounced": bounced,
    "complained": complained,
    "opened": opened,
    "clicked": clicked
  }
)




analyticsRouter.get("/api/analytics/stats",
proc(request: Request) =
  createTFD()
  if not c.loggedIn: resp Http401
  var data: seq[seq[string]]
  var openData: seq[seq[string]]
  var clickData: seq[seq[string]]
  pg.withConnection conn:
    data = getAllRows(conn, sqlSelect(
        table = "pending_emails",
        select = [
          "COUNT(*) FILTER (WHERE status = 'sent') AS total_sent",
          "COUNT(*) FILTER (WHERE status = 'complained') AS total_complained",
          "COUNT(*) FILTER (WHERE status = 'bounced') AS total_bounced"
        ],
        customSQL = """
          WHERE created_at >= current_date - interval '30 days'
        """
      ))

    openData = getAllRows(conn, sqlSelect(
        table = "email_opens",
        select = [
          "COUNT(DISTINCT pending_email_id) AS total_opened"
        ],
        customSQL = """
          WHERE opened_at >= current_date - interval '30 days'
        """
      ))

    clickData = getAllRows(conn, sqlSelect(
        table = "email_clicks",
        select = [
          "COUNT(DISTINCT pending_email_id) AS total_clicked"
        ],
        customSQL = """
          WHERE clicked_at >= current_date - interval '30 days'
        """
      ))

  if data.len == 0:
    resp Http200, %*{
      "total_sent": 0,
      "total_complained": 0,
      "total_bounced": 0,
      "total_opened": 0,
      "total_clicked": 0
    }

  let row = data[0]
  let totalSent = row[0].parseInt
  let totalComplained = row[1].parseInt
  let totalBounced = row[2].parseInt
  let totalOpened = if openData.len > 0: openData[0][0].parseInt else: 0
  let totalClicked = if clickData.len > 0: clickData[0][0].parseInt else: 0

  let rateBounced = if totalSent > 0: (totalBounced.float / totalSent.float) * 100 else: 0.0
  let rateComplained = if totalSent > 0: (totalComplained.float / totalSent.float) * 100 else: 0.0
  let rateOpened = if totalSent > 0: (totalOpened.float / totalSent.float) * 100 else: 0.0
  let rateClicked = if totalSent > 0: (totalClicked.float / totalSent.float) * 100 else: 0.0

  resp Http200, %*{
    "total_sent": totalSent,
    "total_complained": totalComplained,
    "total_bounced": totalBounced,
    "total_opened": totalOpened,
    "total_clicked": totalClicked,
    "rate_bounced": rateBounced,
    "rate_complained": rateComplained,
    "rate_opened": rateOpened,
    "rate_clicked": rateClicked
  }
)