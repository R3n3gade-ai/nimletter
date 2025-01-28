import
  std/[
    re,
    strutils,
    times
  ]

import
  sqlbuilder

import
  ../database/database_connection

const htmlHeader = """<!DOCTYPE html><html lang="EN" style="background:#FAFAFA;min-height:100%;"><head><meta charset="UTF-8"><meta content="width=device-width, initial-scale=1.0" name="viewport"><title>$1</title></head><body>"""
const htmlFooter = "</body></html>"


proc insertUnsubscribeLink*(message, subjectChecked, userUUID, hostname: string): string =
  let unsubscribelink = hostname & "/unsubscribe?contactUUID=" & userUUID
  let htmlLink = "<div style=\"width: 100%; text-align: center;\"><a href='" & unsubscribelink & "'>Unsubscribe</a></div>"
  return htmlHeader.format(subjectChecked) & message & htmlLink & htmlFooter


proc emailVariableReplace*(contactID, message, subjectChecked: string, ignoreUnsubscribe = false): string =
  ## Replace variables in a message.
  ##
  ## Variables are defined by {{ and }}. It holds a variable name,
  ## and maybe a default value, like {{ name | default }}.
  ## If the variable is not found, it will be replaced by the default value.
  ## If the default value is not found, it will be replaced by an empty string.
  ##
  ## Internal fields can be overridden by using metadata. Internal fields are:
  ##  - firstname: Will use the first name of the user (split(" ")[0]).
  ##  - lastname: Will use the last name of the user (split(" ")[1]).
  ##  - name: Will use the full name of the user.
  ##  - email: Will use the email of the user.

  result = message

  let re = re("""{{\s*(\w+)\s*(?:\|\s*(\w+))?\s*}}""")
  let matches = findAll(message, re)


  const internalFields = @["firstname", "lastname", "name", "email", "pagename", "hostname", "uuid"]
  var
    fieldVariable: seq[string]
    fieldDefaults: seq[string]
    fieldArgs: seq[string]
    matchesChecked: seq[string]

  for match in matches:
    if match in matchesChecked:
      continue

    let
      matchSeq = match.strip(chars = {' ', '{', '}'}).split("|")

    let
      base    = (matchSeq[0]).strip()
      default = (if matchSeq.len() == 2: matchSeq[1] else: "").strip()

    if base in internalFields:
      case base
      of "firstname":
        fieldVariable.add("split_part(name, ' ', 1) AS first_name")
      of "lastname":
        fieldVariable.add("""split_part(regexp_replace(name, '.*\s', '', 'g'), ' ', 1) AS last_name""")
      of "name":
        fieldVariable.add("name")
      of "email":
        fieldVariable.add("email")
      of "contactUUID":
        fieldVariable.add("uuid")
      else:
        continue
    else:
      fieldVariable.add("contacts.meta->>?")
      fieldArgs.add(base)

    fieldDefaults.add(default)

    matchesChecked.add(match)

  fieldArgs.add(contactID)

  fieldVariable.add("uuid")

  var
    userData: seq[string]
    mainSettings: seq[string]
  pg.withConnection conn:
    userData = getRow(conn, sqlSelect(
      table = "contacts",
      select = fieldVariable,
      where = ["id = ?"]
    ), fieldArgs)

    mainSettings = getRow(conn, sqlSelect(
      table = "settings",
      select = ["hostname", "page_name"],
      where = ["id = 1"]
    ))

  let
    hostname = mainSettings[0]
    pageName = mainSettings[1]

  if matchesChecked.len == 0:
    if ignoreUnsubscribe:
      return message
    return insertUnsubscribeLink(message, subjectChecked, userData[userData.high], hostname)

  var multi: seq[(string, string)]
  multi.add(("{{ pagename }}", pageName))
  multi.add(("{{ hostname }}", hostname))
  multi.add(("{{ contactUUID }}", userData[userData.high]))

  for i in 0..matchesChecked.high:
    let
      match   = matchesChecked[i]
      field   = fieldVariable[i]
      default = fieldDefaults[i]
      dbvalue = userData[i]

    if dbvalue == "":
      multi.add((match, default))
    else:
      multi.add((match, dbvalue))

  result = message.multiReplace(multi)

  if ignoreUnsubscribe:
    return result
  return insertUnsubscribeLink(result, subjectChecked, userData[userData.high], hostname)

