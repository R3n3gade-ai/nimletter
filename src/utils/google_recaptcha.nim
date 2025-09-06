# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

import
  std/[
    httpclient,
    json,
    os
  ]


const
  VerifyUrl: string = "https://www.google.com/recaptcha/api/siteverify"

type
  ReCaptcha* = object
    secret: string
    siteKey: string
  CaptchaVerificationError* = object of Exception

proc initReCaptcha*(secret, siteKey: string): ReCaptcha =
  result = ReCaptcha(
    secret: secret,
    siteKey: siteKey
  )


proc checkVerification(mpd: MultipartData): bool =
  let
    client = newHttpClient()
    response = client.post(VerifyUrl, multipart=mpd)
    jsonContent = parseJson(response.body)
    success = jsonContent.getOrDefault("success")
    errors = jsonContent.getOrDefault("error-codes")

  if errors != nil:
    for err in errors.items():
      case err.getStr()
      of "missing-input-secret":
        raise newException(CaptchaVerificationError, "The secret parameter is missing.")
      of "invalid-input-secret":
        raise newException(CaptchaVerificationError, "The secret parameter is invalid or malformed.")
      of "missing-input-response":
        raise newException(CaptchaVerificationError, "The response parameter is missing.")
      of "invalid-input-response":
        raise newException(CaptchaVerificationError, "The response parameter is invalid or malformed.")
      else: discard

  result = if success != nil: success.getBool() else: false

proc verify*(rc: ReCaptcha, reCaptchaResponse, remoteIp: string): bool =
  let multiPart = newMultipartData({
    "secret": rc.secret,
    "response": reCaptchaResponse,
    "remoteip": remoteIp
  })
  result = checkVerification(multiPart)

proc verify*(rc: ReCaptcha, reCaptchaResponse: string): bool =
  let multiPart = newMultipartData({
    "secret": rc.secret,
    "response": reCaptchaResponse,
  })
  result = checkVerification(multiPart)


proc checkReCaptcha*(antibot, userIP: string): bool =
  let secret = getEnv("GOOGLE_RECAPTCHA_SECRET")
  let siteKey = getEnv("GOOGLE_RECAPTCHA_SITE_KEY")

  if secret == "" or siteKey == "":
    return true
  if secret == "NONE" or siteKey == "NONE":
    return true

  let captcha = initReCaptcha(secret, siteKey)


  var captchaValid: bool = false
  try:
    captchaValid = captcha.verify(antibot, userIP)
  except:
    echo("checkReCaptcha(): Error checking captcha. UserIP: " & userIP & " - ErrMsg: " & getCurrentExceptionMsg())
    return false

  return captchaValid


