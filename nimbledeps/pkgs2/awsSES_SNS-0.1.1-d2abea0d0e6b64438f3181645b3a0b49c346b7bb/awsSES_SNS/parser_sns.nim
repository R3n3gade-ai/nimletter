
import
  std/[
    json,
    strutils
  ]

from sequtils import mapIt

type
  EventType* {.pure.} = enum
    Bounce
    Complaint
    Delivery
    Send
    Open
    Click

    # Not used actively
    Reject            # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html#event-publishing-retrieving-sns-contents-reject-object
    RenderingFailure  # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html#event-publishing-retrieving-sns-contents-failure-object
    DeliveryDelay     # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html#event-publishing-retrieving-sns-contents-delivery-delay-object
    Subscription      # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html#event-publishing-retrieving-sns-contents-subscription-object

    # Not default
    SNSSubscriptionConfirmation
    Unknown

  BounceType* {.pure.} = enum
    Permanent
    Transient
    Undetermined
    Unknown

  BounceSubType* {.pure.} = enum
    General
    NoEmail
    Suppressed
    MailboxFull
    MessageTooLarge
    ContentRejected
    AttachmentRejected
    OnAccountSuppressionList
    Undetermined
    Unknown

  ComplaintFeedbackType* = enum
    abuse
    authFailure
    fraud
    notspam # not-spam
    other
    virus
    unknown

  MailBounce* = ref object
    messageID*: string
    bounceType*: BounceType
    bounceSubType*: BounceSubType
    email*: string
    status*: string
    diagnosticCode*: string

  MailComplaint* = ref object
    messageID*: string
    complaintFeedbackType*: ComplaintFeedbackType
    arrivalDate*: string
    email*: string

  MailDelivery* = ref object
    messageID*: string
    timestamp*: string
    email*: seq[string]
    smtpResponse*: string

  MailOpen* = ref object
    messageID*: string
    timestamp*: string
    ipAddress*: string
    userAgent*: string

  MailClick* = ref object
    messageID*: string
    timestamp*: string
    ipAddress*: string
    userAgent*: string
    link*: string


proc snsParseJson*(body: string): (bool, JsonNode) =
  try:
    let snsMsgRequest = parseJson(body)

    if snsMsgRequest["Type"].getStr() == "Notification":
      return (true, parseJson(snsMsgRequest["Message"].getStr()))

    elif snsMsgRequest["Type"].getStr() == "SubscriptionConfirmation":
      return (true, snsMsgRequest)

    return (false, nil)
  except:
    return (false, nil)


proc snsParseEventType*(jsonBody: JsonNode): EventType =
  ## The event type. Either a normal mail event, or the subscription confirmation
  ## call from SNS.
  if jsonBody.hasKey("eventType"):
    return parseEnum[EventType](jsonBody["eventType"].getStr(), EventType.Unknown)

  elif jsonBody.hasKey("Type") and jsonBody["Type"].getStr() == "SubscriptionConfirmation":
    return EventType.SNSSubscriptionConfirmation

  return EventType.Unknown


proc snsParseBounce*(jsonBody: JsonNode): seq[MailBounce] =

  let bounce = jsonBody["bounce"]
  let bouncedRecipients = bounce["bouncedRecipients"]

  for recipient in bouncedRecipients:
    result.add MailBounce(
      messageID: jsonBody["mail"]["messageId"].getStr(),
      bounceType: parseEnum[BounceType](bounce["bounceType"].getStr(), BounceType.Unknown),
      bounceSubType: parseEnum[BounceSubType](bounce["bounceSubType"].getStr(), BounceSubType.Unknown),
      email: recipient["emailAddress"].getStr(),
      status: recipient["status"].getStr(),
      diagnosticCode: recipient["diagnosticCode"].getStr()
    )


proc snsParseComplaint*(jsonBody: JsonNode): seq[MailComplaint] =

  let complaint = jsonBody["complaint"]
  let complainedRecipients = complaint["complainedRecipients"]

  for recipient in complainedRecipients:
    result.add MailComplaint(
      messageID: jsonBody["mail"]["messageId"].getStr(),
      complaintFeedbackType: parseEnum[ComplaintFeedbackType](complaint["complaintFeedbackType"].getStr(), unknown),
      arrivalDate: complaint["arrivalDate"].getStr(),
      email: recipient["emailAddress"].getStr()
    )


proc snsParseDelivery*(jsonBody: JsonNode): MailDelivery =
  let delivery = jsonBody["delivery"]
  return MailDelivery(
    messageID: jsonBody["mail"]["messageId"].getStr(),
    timestamp: delivery["timestamp"].getStr(),
    email: delivery["recipients"].getElems().mapIt(it.getStr()),
    smtpResponse: delivery["smtpResponse"].getStr()
  )


proc snsParseOpen*(jsonBody: JsonNode): MailOpen =
  let open = jsonBody["open"]
  return MailOpen(
    messageID: jsonBody["mail"]["messageId"].getStr(),
    timestamp: open["timestamp"].getStr(),
    ipAddress: open["ipAddress"].getStr(),
    userAgent: open["userAgent"].getStr()
  )


proc snsParseClick*(jsonBody: JsonNode): MailClick =
  let click = jsonBody["click"]
  return MailClick(
    messageID: jsonBody["mail"]["messageId"].getStr(),
    timestamp: click["timestamp"].getStr(),
    ipAddress: click["ipAddress"].getStr(),
    userAgent: click["userAgent"].getStr(),
    link: click["link"].getStr()
  )


proc snsSubscriptionConfirmation*(jsonBody: JsonNode): tuple[message: string, subscribeURL: string] =
  #if jsonBody.hasKey("Type") and jsonBody["Type"].getStr() == "SubscriptionConfirmation":
  return (
    jsonBody["Message"].getStr(),
    jsonBody["SubscribeURL"].getStr()
  )

