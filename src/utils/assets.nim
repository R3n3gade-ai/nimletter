
import
  std/[
    locks,
    mimetypes,
    os,
    tables
  ]


var gFilecacheLock*: Lock
initLock(gFilecacheLock)


proc embed(directory: string): Table[string, tuple[filedata: string, ext: string]] =
  echo "Embedding assets from " & directory
  for fd in walkDirRec(directory, checkDir = true):
    result["/" & fd] = (staticRead("../../" & fd), splitFile(fd).ext)
    echo fd
  return result

const assets* = embed("assets")
let m* = newMimetypes()
