
import
  std/[
    strutils
  ]


import
  mummy,
  mummy_utils




proc routeCustom404*(request: Request) =
  ## This is a custom 404 handler

  var headers: httpheaders.HttpHeaders

  case request.reqMethod
  of HttpPost, HttpDelete, HttpHead:
    setHeader("Content-Type", $ContentType.Text)
    request.respond(404, headers)
  of HttpGet:
    setHeader("Content-Type", $ContentType.Html)
    request.respond(404, headers, "404")
  else:
    setHeader("Content-Type", $ContentType.Text)
    request.respond(404, headers)
  return


proc routeErrorHandler*(request: Request, e: ref Exception) =
  ## This is a custom 404 handler

  # createTFD()
  var data: seq[(string, string)]
  for v in request.queryParams:
    data.add((v[0], v[1]))

  for v in request.pathParams:
    data.add((v[0], v[1]))

  data.add(("remote_addr", request.ip))
  data.add(("http_referer", request.headers["referer"]))
  data.add(("request_uri", request.path))

  echo data

  #
  # Pretty page
  #
  if request.reqMethod == HttpGet and request.headers["Accept"].startsWith("text/html"):
    var headers: httpheaders.HttpHeaders
    setHeader("Content-Type", $ContentType.Html)
    request.respond(502, headers, "502")
    # request.respond(502, headers, gen502(c, "502"))
    return

  #
  # Text response
  #
  var headers: httpheaders.HttpHeaders
  setHeader("Content-Type", $ContentType.Text)
  request.respond(502, headers, "We hit a problem. An error ticket has been made and sent to the developers.")
  return

