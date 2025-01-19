# https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html
# https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-examples.html

import
  std/[
    json
  ]

let snsExampleContainer* = """{
  "Type": "Notification",
  "MessageId": "5f5eaaac-174f-525a-beb8-f66ea0e86043",
  "TopicArn": "arn:aws:sns:eu-west-1:123456789012:ses-sender",
  "Subject": "Amazon SES Email Event Notification",
  "Message": "<REPLACE_WITH_STRINGIFY_JSON>",
  "Timestamp": "2025-01-04T06:29:59.318Z",
  "SignatureVersion": "1",
  "Signature": "KPtnEVhRPoP/lFaFQ5eh9jK+s8542cO03YMdK4T5CEqpShigq6NG0X0xNYrXnyjx9iogTJ28+OKieoim32popofmfslkelk2ewewe/ny9SQptYQvNxCJ1yRHBxS15Go/d32KOYnpEL9nXqu7GKoC6B4K/zwd7fgwkMbjI+5bhocd+CF27I2WBfIoOfFqsFp/mIt4nemnzvpwnoaJCh2/+ua3AGCR5pxLbB7EwdlBxAvWAZGN6E3gNKc97oFnDqLuj/rRNoJfc1SmNcjaeSwwNwNLzcFSoN2eMwml51nj52HiDHMhOvzKCiNQ/7NT/zFogg==",
  "SigningCertURL": "https://sns.eu-west-1.amazonaws.com/SimpleNotificationService-9c6465fa4f42fs233fs2113014631ec1136.pem",
  "UnsubscribeURL": "https://sns.eu-west-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-1:123456789012:ses-sender:2355533-6a21-42e3-af64-533454563"
}"""

let snsExampleSubscribe* = """{
  "Type" : "SubscriptionConfirmation",
  "MessageId" : "43814462-5ba3-4146-bc42-9ce188ac9ab8",
  "Token" : "2336412f37fb687f5d51e6e2425a8a5871498bc4e0a49fc225b734a7390044f72865af5fbc8794dae5c7433232aba223defcde699b35a01e3732eb2a91702cc415d7118237a7e55b53e35e377b7a64df026de8ad19b3b584304799b429ac6924350f6e1c23c90003cdb09f4a7d8421509b",
  "TopicArn" : "arn:aws:sns:eu-west-1:123456789012:ses-sender",
  "Message" : "You have chosen to subscribe to the topic arn:aws:sns:eu-west-1:123456789012:ses-sender.\nTo confirm the subscription, visit the SubscribeURL included in this message.",
  "SubscribeURL" : "https://sns.eu-west-1.amazonaws.com/?Action=ConfirmSubscription&TopicArn=arn:aws:sns:eu-west-1:123456789012:ses-sender&Token=2336423f37fb687f5d51e6e2425a8a5871498bc4e0a49fc225b734a7390044f72865af5fbc8794dae5c7433232aba223defcde699b35a01e3732eb2a91702cc415d7118237a7e55b53e35e377b7a64df026de8ad19b3b584304799b429ac6924350f6e1c23c90003cdb09f4a7d8421509b",
  "Timestamp" : "2025-01-03T09:33:57.522Z",
  "SignatureVersion" : "1",
  "Signature" : "KPtnEVhRPoP/lFaFQ5eh9jK+s8542cO03YMdK4T5CEqpShigq6NG0X0xNYrXnyjx9iogTJ28+OKieo2popofmfslkelk2ewewe/ny9SQptYQvNxCJ1yRHBxS15Go/d32KOYnpEL9nXqu7GKoC6B4K/zwd7fgwkMbjI+5bhocd+CF27I2WBfIoOfFqsFp/mIt4nemnzvpwnoaJCh2/+ua3AGCR5pxLbB7EwdlBxAvWAZGN6E3gNKc97oFnDqLuj/rRNoJfc1SmNcjaeSwwNwNLzcFSoN2eMwml51nj52HiDHMhOvzKCiNQ/7NT/zFogg==",
  "SigningCertURL" : "https://sns.eu-west-1.amazonaws.com/SimpleNotificationService-9c6465fa7f48fw2k3w223014631ec1136.pem"
}"""

let snsSesExampleBounceJson* = """{
  "eventType":"Bounce",
  "bounce":{
    "bounceType":"Permanent",
    "bounceSubType":"General",
    "bouncedRecipients":[
      {
        "emailAddress":"recipient@example.com",
        "action":"failed",
        "status":"5.1.1",
        "diagnosticCode":"smtp; 550 5.1.1 user unknown"
      }
    ],
    "timestamp":"2017-08-05T00:41:02.669Z",
    "feedbackId":"01000157c44f053b-61b59c11-9236-11e6-8f96-7be8aexample-000000",
    "reportingMTA":"dsn; mta.example.com"
  },
  "mail":{
    "timestamp":"2017-08-05T00:40:02.012Z",
    "source":"Sender Name <sender@example.com>",
    "sourceArn":"arn:aws:ses:us-east-1:123456789012:identity/sender@example.com",
    "sendingAccountId":"123456789012",
    "messageId":"<REPLACE_WITH_MESSAGEID>",
    "destination":[
      "recipient@example.com"
    ],
    "headersTruncated":false,
    "headers":[
      {
        "name":"From",
        "value":"Sender Name <sender@example.com>"
      },
      {
        "name":"To",
        "value":"recipient@example.com"
      },
      {
        "name":"Subject",
        "value":"Message sent from Amazon SES"
      },
      {
        "name":"MIME-Version",
        "value":"1.0"
      },
      {
        "name":"Content-Type",
        "value":"multipart/alternative; boundary=\"----=_Part_7307378_1629847660.1516840721503\""
      }
    ],
    "commonHeaders":{
      "from":[
        "Sender Name <sender@example.com>"
      ],
      "to":[
        "recipient@example.com"
      ],
      "messageId":"<REPLACE_WITH_MESSAGEID>",
      "subject":"Message sent from Amazon SES"
    },
    "tags":{
      "ses:configuration-set":[
        "ConfigSet"
      ],
      "ses:source-ip":[
        "192.0.2.0"
      ],
      "ses:from-domain":[
        "example.com"
      ],
      "ses:caller-identity":[
        "ses_user"
      ]
    }
  }
}"""


let snsSesExampleComplaintJson* = """{
  "eventType":"Complaint",
  "complaint": {
    "complainedRecipients":[
      {
        "emailAddress":"recipient@example.com"
      }
    ],
    "timestamp":"2017-08-05T00:41:02.669Z",
    "feedbackId":"01000157c44f053b-61b59c11-9236-11e6-8f96-7be8aexample-000000",
    "userAgent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36",
    "complaintFeedbackType":"abuse",
    "arrivalDate":"2017-08-05T00:41:02.669Z"
  },
  "mail":{
    "timestamp":"2017-08-05T00:40:01.123Z",
    "source":"Sender Name <sender@example.com>",
    "sourceArn":"arn:aws:ses:us-east-1:123456789012:identity/sender@example.com",
    "sendingAccountId":"123456789012",
    "messageId":"<REPLACE_WITH_MESSAGEID>",
    "destination":[
      "recipient@example.com"
    ],
    "headersTruncated":false,
    "headers":[
      {
        "name":"From",
        "value":"Sender Name <sender@example.com>"
      },
      {
        "name":"To",
        "value":"recipient@example.com"
      },
      {
        "name":"Subject",
        "value":"Message sent from Amazon SES"
      },
      {
        "name":"MIME-Version","value":"1.0"
      },
      {
        "name":"Content-Type",
        "value":"multipart/alternative; boundary=\"----=_Part_7298998_679725522.1516840859643\""
      }
    ],
    "commonHeaders":{
      "from":[
        "Sender Name <sender@example.com>"
      ],
      "to":[
        "recipient@example.com"
      ],
      "messageId":"<REPLACE_WITH_MESSAGEID>",
      "subject":"Message sent from Amazon SES"
    },
    "tags":{
      "ses:configuration-set":[
        "ConfigSet"
      ],
      "ses:source-ip":[
        "192.0.2.0"
      ],
      "ses:from-domain":[
        "example.com"
      ],
      "ses:caller-identity":[
        "ses_user"
      ]
    }
  }
}"""


let snsSesExampleDeliveryJson* = """{
  "eventType": "Delivery",
  "mail": {
    "timestamp": "2016-10-19T23:20:52.240Z",
    "source": "sender@example.com",
    "sourceArn": "arn:aws:ses:us-east-1:123456789012:identity/sender@example.com",
    "sendingAccountId": "123456789012",
    "messageId":"<REPLACE_WITH_MESSAGEID>",
    "destination": [
      "recipient@example.com"
    ],
    "headersTruncated": false,
    "headers": [
      {
        "name": "From",
        "value": "sender@example.com"
      },
      {
        "name": "To",
        "value": "recipient@example.com"
      },
      {
        "name": "Subject",
        "value": "Message sent from Amazon SES"
      },
      {
        "name": "MIME-Version",
        "value": "1.0"
      },
      {
        "name": "Content-Type",
        "value": "text/html; charset=UTF-8"
      },
      {
        "name": "Content-Transfer-Encoding",
        "value": "7bit"
      }
    ],
    "commonHeaders": {
      "from": [
        "sender@example.com"
      ],
      "to": [
        "recipient@example.com"
      ],
      "messageId":"<REPLACE_WITH_MESSAGEID>",
      "subject": "Message sent from Amazon SES"
    },
    "tags": {
      "ses:configuration-set": [
        "ConfigSet"
      ],
      "ses:source-ip": [
        "192.0.2.0"
      ],
      "ses:from-domain": [
        "example.com"
      ],
      "ses:caller-identity": [
        "ses_user"
      ],
      "ses:outgoing-ip": [
        "192.0.2.0"
      ],
      "myCustomTag1": [
        "myCustomTagValue1"
      ],
      "myCustomTag2": [
        "myCustomTagValue2"
      ]      
    }
  },
  "delivery": {
    "timestamp": "2016-10-19T23:21:04.133Z",
    "processingTimeMillis": 11893,
    "recipients": [
      "recipient@example.com"
    ],
    "smtpResponse": "250 2.6.0 Message received",
    "reportingMTA": "mta.example.com"
  }
}"""

let snsSesExampleOpenJson* = """{
  "eventType": "Open",
  "mail": {
    "commonHeaders": {
      "from": [
        "sender@example.com"
      ],
      "messageId":"<REPLACE_WITH_MESSAGEID>",
      "subject": "Message sent from Amazon SES",
      "to": [
        "recipient@example.com"
      ]
    },
    "destination": [
      "recipient@example.com"
    ],
    "headers": [
      {
        "name": "X-SES-CONFIGURATION-SET",
        "value": "ConfigSet"
      },
      {
        "name":"X-SES-MESSAGE-TAGS",
        "value":"myCustomTag1=myCustomValue1, myCustomTag2=myCustomValue2"
      },
      {
        "name": "From",
        "value": "sender@example.com"
      },
      {
        "name": "To",
        "value": "recipient@example.com"
      },
      {
        "name": "Subject",
        "value": "Message sent from Amazon SES"
      },
      {
        "name": "MIME-Version",
        "value": "1.0"
      },
      {
        "name": "Content-Type",
        "value": "multipart/alternative; boundary=\"XBoundary\""
      }
    ],
    "headersTruncated": false,
    "messageId":"<REPLACE_WITH_MESSAGEID>",
    "sendingAccountId": "123456789012",
    "source": "sender@example.com",
    "tags": {
      "myCustomTag1":[
        "myCustomValue1"
      ],
      "myCustomTag2":[
        "myCustomValue2"
      ],
      "ses:caller-identity": [
        "IAM_user_or_role_name"
      ],
      "ses:configuration-set": [
        "ConfigSet"
      ],
      "ses:from-domain": [
        "example.com"
      ],
      "ses:source-ip": [
        "192.0.2.0"
      ]
    },
    "timestamp": "2017-08-09T21:59:49.927Z"
  },
  "open": {
    "ipAddress": "192.0.2.1",
    "timestamp": "2017-08-09T22:00:19.652Z",
    "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_3 like Mac OS X) AppleWebKit/603.3.8 (KHTML, like Gecko) Mobile/14G60"
  }
}"""

let snsSesExampleClickJson* = """{
  "eventType": "Click",
  "click": {
    "ipAddress": "192.0.2.1",
    "link": "http://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-smtp.html",
    "linkTags": {
      "samplekey0": [
        "samplevalue0"
      ],
      "samplekey1": [
        "samplevalue1"
      ]
    },
    "timestamp": "2017-08-09T23:51:25.570Z",
    "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36"
  },
  "mail": {
    "commonHeaders": {
      "from": [
        "sender@example.com"
      ],
      "messageId":"<REPLACE_WITH_MESSAGEID>",
      "subject": "Message sent from Amazon SES",
      "to": [
        "recipient@example.com"
      ]
    },
    "destination": [
      "recipient@example.com"
    ],
    "headers": [
      {
        "name": "X-SES-CONFIGURATION-SET",
        "value": "ConfigSet"
      },
      {
        "name":"X-SES-MESSAGE-TAGS",
        "value":"myCustomTag1=myCustomValue1, myCustomTag2=myCustomValue2"
      },
      {
        "name": "From",
        "value": "sender@example.com"
      },
      {
        "name": "To",
        "value": "recipient@example.com"
      },
      {
        "name": "Subject",
        "value": "Message sent from Amazon SES"
      },
      {
        "name": "MIME-Version",
        "value": "1.0"
      },
      {
        "name": "Content-Type",
        "value": "multipart/alternative; boundary=\"XBoundary\""
      },
      {
        "name": "Message-ID",
        "value": "EXAMPLE7c191be45-e9aedb9a-02f9-4d12-a87d-dd0099a07f8a-000000"
      }
    ],
    "headersTruncated": false,
    "messageId":"<REPLACE_WITH_MESSAGEID>",
    "sendingAccountId": "123456789012",
    "source": "sender@example.com",
    "tags": {
      "myCustomTag1":[
        "myCustomValue1"
      ],
      "myCustomTag2":[
        "myCustomValue2"
      ],
      "ses:caller-identity": [
        "ses_user"
      ],
      "ses:configuration-set": [
        "ConfigSet"
      ],
      "ses:from-domain": [
        "example.com"
      ],
      "ses:source-ip": [
        "192.0.2.0"
      ]
    },
    "timestamp": "2017-08-09T23:50:05.795Z"
  }
}"""


