
import
  std/[
    json,
    httpclient,
    rdstdin,
    strutils
  ]


import
  ./sns_data


let
  snsContainer = snsExampleContainer.parseJson()



var messageID: string
let inputOK = readLineFromStdin("Insert messageID: ", messageID)
if not inputOK:
  quit(1)


let
  snsClickString = snsSesExampleClickJson.replace("<REPLACE_WITH_MESSAGEID>", messageID)
  snsClick = snsClickString.parseJson()

snsContainer["Message"] = ($snsClick).newJString()



let client = newHttpClient()
client.headers = newHttpHeaders({ "Content-Type": "application/json" })
let body = snsContainer
let response = client.request("http://127.0.0.1:5555/webhook/incoming/sns/secret", httpMethod = HttpPost, body = $body)
echo response.status