
import
  std/[
    strutils
  ]

from std/os import getEnv

import
  sqlbuilder

import
  ../database/database_connection,
  ../utils/password_utils

proc insertTestData*() =
  pg.withConnection conn:
    if getAllRows(conn, sql("SELECT * FROM users")).len > 0:
      return

    exec(conn, sql("""
      INSERT INTO contacts (name, email, created_at, updated_at, requires_double_opt_in, double_opt_in, double_opt_in_data, pending_lists)
      VALUES
      ('Nim Letter', 'test@nimletter.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, FALSE, TRUE, NULL, ARRAY[]::integer[]),
      ('Success User', 'success@simulator.amazonses.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, TRUE, TRUE, NULL, ARRAY[1]),
      ('Bounce User', 'bounce@simulator.amazonses.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, TRUE, TRUE, NULL, ARRAY[1]),
      ('OOTO User', 'ooto@simulator.amazonses.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, TRUE, TRUE, NULL, ARRAY[1]),
      ('Complaint User', 'complaint@simulator.amazonses.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, TRUE, TRUE, NULL, ARRAY[1]),
      ('Suppression List User', 'suppressionlist@simulator.amazonses.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, TRUE, TRUE, NULL, ARRAY[1]);
        """))

    exec(conn, sql("""
      INSERT INTO mails (name, contentHTML, tags, category, editorType, identifier)
      VALUES
      ('Welcome Email', 'Hey {{ firstname }}, Welcome to our service!', ARRAY['welcome', 'intro'], 'informational', 'html', 'welcome-email'),
      ('Follow-up Email', 'Here is some {{ interest | important }} more information.', ARRAY['followup', 'info'], 'informational', 'html', 'followup-email'),
      ('Anything else', 'Anything else you want', ARRAY['followup', 'info'], 'informational', 'html', 'anything-else'),
      ('Like it, then click', 'Like it, then click', ARRAY['marketing', 'info'], 'drip', 'html', 'like-it-then-click'),
      ('Wee see you (EmailBuilder)', 'Wee see you', ARRAY['marketing', 'info'], 'drip', 'emailbuilder', 'wee-see-you');
    """))

    exec(conn, sql("""
      INSERT INTO flows (name)
      VALUES
      ('Welcome Flow'),
      ('Click Open Flow');
    """))

    exec(conn, sql("""
      INSERT INTO flow_steps (flow_id, mail_id, step_number, trigger_type, delay_minutes, name, subject, created_at)
      VALUES
      ((SELECT id FROM flows WHERE name = 'Welcome Flow'), (SELECT id FROM mails WHERE name = 'Welcome Email'), 1, 'delay', 1, 'Step 1', 'Welcome to our service!', CURRENT_TIMESTAMP),
      ((SELECT id FROM flows WHERE name = 'Welcome Flow'), (SELECT id FROM mails WHERE name = 'Follow-up Email'), 2, 'delay', 1, 'Step 2', 'Follow-up Information', CURRENT_TIMESTAMP),
      ((SELECT id FROM flows WHERE name = 'Welcome Flow'), (SELECT id FROM mails WHERE name = 'Anything else'), 3, 'delay', 1, 'Step 3', 'Anything else subject', CURRENT_TIMESTAMP),
      ((SELECT id FROM flows WHERE name = 'Click Open Flow'), (SELECT id FROM mails WHERE name = 'Like it, then click'), 1, 'delay', 0, 'Step 1', 'Like it, then click', CURRENT_TIMESTAMP),
      ((SELECT id FROM flows WHERE name = 'Click Open Flow'), (SELECT id FROM mails WHERE name = 'Wee see you (EmailBuilder)'), 2, 'click', 0, 'Step 2', 'Wee see you', CURRENT_TIMESTAMP);
        """))

    exec(conn, sql("""
      INSERT INTO lists (name, identifier, flow_ids, description, created_at, updated_at, uuid)
      VALUES
      ('Test List', 'test-list', ARRAY[(SELECT id FROM flows WHERE name = 'Welcome Flow')], 'A test list', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, uuid_generate_v4()),
      ('Click Open List', 'click-list', ARRAY[(SELECT id FROM flows WHERE name = 'Click Open Flow')], 'A click list', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, uuid_generate_v4());
    """))

    exec(conn, sql("""
      INSERT INTO subscriptions (user_id, list_id, subscribed_at)
      VALUES
      ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM lists WHERE name = 'Test List'), CURRENT_TIMESTAMP),
      ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM lists WHERE name = 'Click Open List'), CURRENT_TIMESTAMP)
    """))

    exec(conn, sql("""
      INSERT INTO pending_emails (user_id, list_id, flow_id, flow_step_id, trigger_type, scheduled_for, status, message_id, created_at, updated_at)
      VALUES
      (
        (SELECT id FROM contacts WHERE email = 'test@nimletter.com'),
        (SELECT id FROM lists WHERE name = 'Test List'),
        (SELECT id FROM flows WHERE name = 'Welcome Flow'),
        (SELECT id FROM flow_steps WHERE step_number = 1 AND flow_id = (SELECT id FROM flows WHERE name = 'Welcome Flow')),
        'delay',
        CURRENT_TIMESTAMP,
        'pending',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      ),
      (
        (SELECT id FROM contacts WHERE email = 'test@nimletter.com'),
        (SELECT id FROM lists WHERE name = 'Click Open List'),
        (SELECT id FROM flows WHERE name = 'Click Open Flow'),
        (SELECT id FROM flow_steps WHERE step_number = 1 AND flow_id = (SELECT id FROM flows WHERE name = 'Click Open Flow')),
        'delay',
        CURRENT_TIMESTAMP,
        'pending',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      );
    """))


  var
    adminEmail = getEnv("ADMIN_EMAIL")
    adminPassword = getEnv("ADMIN_PASSWORD")

  if adminEmail == "":
    echo "ADMIN_EMAIL not set, setting to 'admin@nimletter.com'. Remember to change it!"
    adminEmail = "admin@nimletter.com"

  if adminPassword == "":
    echo "ADMIN_PASSWORD not set, setting to 'dripit'. Remember to change it!"
    adminPassword = "dripit"
    echo "\n#########"
    echo "Admin email: " & adminEmail
    echo "Admin password: " & adminPassword
    echo "#########\n"


  let
    salt = makeSalt()
    passwordCreated = makePassword(adminPassword, salt)

  pg.withConnection conn:
    exec(conn, sqlInsert(
      table = "users",
      data = [
        "email",
        "password",
        "salt",
        "rank"
      ]
    ), adminEmail, passwordCreated, salt, "admin")



# proc insertTestDataOpen_1Clicks*() =
#   pg.withConnection conn:
#     exec(conn, sql("""
#       INSERT INTO email_opens (user_id, mail_id, opened_at)
#       VALUES
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Welcome Email'), CURRENT_TIMESTAMP),
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Follow-up Email'), CURRENT_TIMESTAMP);
#     """))

#     exec(conn, sql("""
#       INSERT INTO email_clicks (user_id, mail_id, clicked_at, url)
#       VALUES
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Welcome Email'), CURRENT_TIMESTAMP, 'https://example.com/welcome'),
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Follow-up Email'), CURRENT_TIMESTAMP, 'https://example.com/followup');
#     """))

# proc insertTestDataClick_1*() =
#   pg.withConnection conn:
#     exec(conn, sql("""
#       INSERT INTO email_opens (user_id, mail_id, opened_at)
#       VALUES
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Welcome Email'), CURRENT_TIMESTAMP),
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Follow-up Email'), CURRENT_TIMESTAMP);
#     """))

#     exec(conn, sql("""
#       INSERT INTO email_clicks (user_id, mail_id, clicked_at, url)
#       VALUES
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Welcome Email'), CURRENT_TIMESTAMP, 'https://example.com/welcome'),
#       ((SELECT id FROM contacts WHERE email = 'test@nimletter.com'), (SELECT id FROM mails WHERE name = 'Follow-up Email'), CURRENT_TIMESTAMP, 'https://example.com/followup');
#     """))
