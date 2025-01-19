


import
  std/[
    locks,
    mimetypes,
    os,
    strutils,
    tables
  ]


import
  mummy, mummy/routers,
  mummy_utils


var gFilecacheLock: Lock
initLock(gFilecacheLock)


proc embed(directory: string): Table[string, tuple[filedata: string, ext: string]] =
  echo "Embedding assets from " & directory
  for fd in walkDirRec(directory, checkDir = true):
    result["/" & fd] = (staticRead("../../" & fd), splitFile(fd).ext)
    echo fd
  return result

const assets = embed("assets")
let m = newMimetypes()


var assetRouter*: Router

assetRouter.get("/assets/**",
proc(request: Request) =
  let path = request.path

  acquire(gFilecacheLock)

  if not assets.hasKey(path):
    release(gFilecacheLock)
    resp Http404

  var headers: HttpHeaders
  {.gcsafe.}:
    headers["Content-Type"] = m.getMimetype(assets[path].ext)
    request.respond(200, headers, assets[path].filedata)

  release(gFilecacheLock)

  return
)


