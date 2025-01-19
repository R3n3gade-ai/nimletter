

import
  std/[
    strutils
  ]


proc isValidUUID*(s: string): bool =
  ## Validte UUID string
  ##
  ## deca1d87-ba21-457b-928d-53b71c11d6eb
  ## 0) deca1d87 = 8
  ## 1) ba21 = 4
  ## 2) 457b = 4
  ## 3) 928d = 4
  ## 4) 53b71c11d6eb = 12
  ##
  let u = s.split("-")
  if u.len() != 5:
    return false
  if u[0].len() != 8:
    return false
  if u[1].len() != 4:
    return false
  if u[2].len() != 4:
    return false
  if u[3].len() != 4:
    return false
  if u[4].len() != 12:
    return false
  return true



proc isValidInt*(str: string): bool =
  if str.len() == 0:
    return false
  for i in str:
    if not isDigit(i):
      return false
  return true



proc isValidEmail*(email: string): bool =
  ## Check the emails formatting
  if not ('@' in email and '.' in email) or email.len() < 5 or email.len() > 254:
    return false

  let r = split(email, "@")
  if r[0].len() == 0 or r.len() != 2:
    return false

  let s = r[1].split(".")
  if s.len() < 2 or s[0].len() == 0 or s[1].len() == 0:
    return false

  return true