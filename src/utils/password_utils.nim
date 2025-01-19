import
  bcrypt,
  md5,
  random

randomize()


#
# SALT
#

proc randomSalt*(): string =
  ## Generate a random salt
  ## Seconf priority salting

  result = ""
  for i in 0..127:
    var r = rand(225)
    if r >= 32 and r <= 126:
      result.add(chr(rand(225)))


proc devRandomSalt*(): string =
  ## Generate random salt
  ## First priority salting

  result = ""
  var f = open("/dev/urandom")
  var randomBytes: array[0..127, char]
  discard f.readBuffer(addr(randomBytes), 128)
  for i in 0..127:
    if ord(randomBytes[i]) >= 32 and ord(randomBytes[i]) <= 126:
      result.add(randomBytes[i])
  f.close()


proc makeSalt*(): string =
  ## Creates a salt using a cryptographically secure random number generator.
  ##
  ## Ensures that the resulting salt contains no ``\0``.

  try:
    result = devRandomSalt()
  except IOError:
    result = randomSalt()

  var newResult = ""
  for i in 0..<result.len:
    if result[i] != '\0':
      newResult.add result[i]
  return newResult


proc makeSessionKey*(): string =
  ## Creates a random key to be used to authorize a session.

  return bcrypt.hash(makeSalt(), genSalt(8))


#
# PASS
#
proc makePassword*(password, salt: string, comparingTo = ""): string =
  ## Creates an MD5 hash by combining password and salt

  when defined(windows):
    result = getMD5(salt & getMD5(password))
  else:
    let bcryptSalt = if comparingTo != "": comparingTo else: makeSessionKey()
    result = hash(getMD5(salt & getMD5(password)), bcryptSalt)


