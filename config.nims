
when NimMajor >= 2:
  switch("nimblePath", "nimbledeps/pkgs2")
else:
  switch("nimblePath", "nimbledeps/pkgs")


switch("d", "ssl")
switch("mm", "orc")
switch("threads", "on")