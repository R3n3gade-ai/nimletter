
import
  std/[
    json,
    strutils,
    random,
    wordwrap
  ]

from std/base64 import encode
from std/os import getEnv

import
  awsSES_SNS,
  mime,
  sqlbuilder


import
  ../database/database_connection

import
  ./email_variables


randomize()


proc sendMail(
    client: Smtp,
    smtpFrom, recipient: string,
    multi: MimeMessage
  ): (bool, string) =
  # Send email
  try:
    let messageID = client.sendMailGetReply(smtpFrom, @[recipient], $multi.finalize())
    return (true, messageID)
  except:
    return (false, getCurrentExceptionMsg())


proc smtpAuth(client: var Smtp, smtpHost, smtpPort, smtpUser, smtpPass: string) =
  client.connect(smtpHost, Port(smtpPort.parseInt()))
  client.auth(smtpUser, smtpPass)

proc smtpData(): tuple[
    smtpHost: string,
    smtpPort: string,
    smtpUser: string,
    smtpPass: string,
    smtpFromEmail: string,
    smtpFromName: string,
    smtpMailspersecond: int
  ] =

  if getEnv("SMTP_HOST") != "":
    let maxMails = getEnv("SMTP_MAILSPERSECOND")
    return (
      smtpHost: getEnv("SMTP_HOST"),
      smtpPort:  getEnv("SMTP_PORT"),
      smtpUser: getEnv("SMTP_USER"),
      smtpPass: getEnv("SMTP_PASSWORD"),
      smtpFromEmail: getEnv("SMTP_FROMEMAIL"),
      smtpFromName: getEnv("SMTP_FROMNAME"),
      smtpMailspersecond: if maxMails != "": maxMails.parseInt() else: 1
    )

  else:
    pg.withConnection conn:
      let smtpDB = getRow(conn, sqlSelect(
        table = "smtp_settings",
        select = [
          "smtp_host",
          "smtp_port",
          "smtp_user",
          "smtp_password",
          "smtp_fromemail",
          "smtp_fromname",
          "smtp_mailspersecond"
        ]
      ))

      result = (
        smtpHost: smtpDB[0],
        smtpPort: smtpDB[1],
        smtpUser: smtpDB[2],
        smtpPass: smtpDB[3],
        smtpFromEmail: smtpDB[4],
        smtpFromName: smtpDB[5],
        smtpMailspersecond: smtpDB[6].parseInt()
      )
    return result



proc sendMailMimeNow*(
      # pendingEmailID: string,
      contactID: string,
      subject, message, recipient: string,
      replyTo: string = "",
  ): tuple[success: bool, messageID: string, mailsPerSecond: int] =

  let smtpData = smtpData()

  # Header
  let subjectChecked =
      if subject.len() <= 75:
        subject.replace("\n", " ")
      else:
        subject.substr(0, 73).replace("\n", " ") & ".."

  var multi = newMimeMessage()
  multi.header["From"]    = smtpData.smtpFromName & " <" & smtpData.smtpFromEmail & ">"
  multi.header["To"]      = @[recipient].mimeList
  multi.header["Subject"] = "=?UTF-8?B?" & base64.encode(subjectChecked) & "?="
  if replyTo != "":
    multi.header["Reply-To"] = replyTo

  let message = emailVariableReplace(contactID, message, subjectChecked).wrapWords(maxLineWidth=250, splitLongWords=false)

  var first = newMimeMessage()
  first.header["Content-Type"]  = "text/html; charset=\"UTF-8\""
  first.body                    = message

  # Add first part to message
  multi.parts.add(first)

  when defined(dev) and not defined(forcemail):
    echo "\n"
    echo "##################"
    echo "Email to: " & recipient
    echo "Subject:  " & subject
    echo "Message:  " & message
    echo "##################"
    echo "\n"
    return (true, "dev" & $rand(100000), 1)

  if smtpData.smtpHost == "smtp_host":
    return (false, "SMTP_not_configured_" & $rand(100000), 1)

  # Make SMTP connection
  var
    client = newSmtp(useSsl = true)
    success: bool
    messageID: string

  try:
    smtpAuth(client, smtpData.smtpHost, smtpData.smtpPort, smtpData.smtpUser, smtpData.smtpPass)
    (success, messageID) = sendMail(client, smtpData.smtpFromEmail, recipient, multi)
  except:
    echo getCurrentExceptionMsg()
    success = false
    messageID = "email_failed_" & $rand(100000)

  return (success, messageID, smtpData.smtpMailspersecond)

