SET TIME ZONE 'UTC';

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS mails (
  id                  SERIAL PRIMARY KEY,
  name                TEXT NOT NULL,
  identifier          TEXT NOT NULL UNIQUE,  -- Unique identifier for the mail, e.g. first-login
  send_once           BOOLEAN DEFAULT TRUE, -- Send only once to each user
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  contentHTML         TEXT,           -- Content of the mail
  contentEditor       TEXT,           -- The content from the editor, emailbuilder = JSON, maily.to = Markdown
  editorType          TEXT DEFAULT 'emailbuilder', -- html, emailbuilder, etc.
  subject             TEXT,           -- Subject of the mail
  tags                TEXT[],         -- Array of tags associated with the mail
  category            TEXT,           -- Category of the mail (e.g., promotional, informational)
  uuid                UUID NOT NULL DEFAULT uuid_generate_v4()  -- Unique identifier
);
INSERT INTO mails (name, identifier, category, contentHTML, contentEditor, subject) VALUES ('Double Opt-In', 'double-opt-in', 'template', '<div style="background-color:#F5F5F5;color:#262626;font-family:&quot;Helvetica Neue&quot;, &quot;Arial Nova&quot;, &quot;Nimbus Sans&quot;, Arial, sans-serif;font-size:16px;font-weight:400;letter-spacing:0.15008px;line-height:1.5;margin:0;padding:32px 0;min-height:100%;width:100%"><table align="center" width="100%" style="margin:0 auto;max-width:600px;background-color:#FFFFFF" role="presentation" cellSpacing="0" cellPadding="0" border="0"><tbody><tr style="width:100%"><td><div style="padding:24px 32px 24px 32px"><h2 style="font-weight:bold;margin:0;font-size:24px;padding:16px 24px 16px 24px">Hi {{ firstname | there }}</h2><div style="font-weight:normal;padding:16px 24px 16px 24px">We’re glad to have you with us at {{ pagename }}!</div><div style="font-weight:normal;padding:16px 24px 16px 24px">To finish subscribing to our emails, just click the button below. You can unsubscribe anytime if you change your mind.</div><div style="text-align:center;padding:16px 24px 16px 24px"><a href="{{ hostname }}/subscribe/optin" style="color:#FFFFFF;font-size:16px;font-weight:bold;background-color:#4F46E5;border-radius:4px;display:block;padding:12px 20px;text-decoration:none" target="_blank"><span><!--[if mso]><i style="letter-spacing: 20px;mso-font-width:-100%;mso-text-raise:30" hidden>&nbsp;</i><![endif]--></span><span>Subscribe!</span><span><!--[if mso]><i style="letter-spacing: 20px;mso-font-width:-100%" hidden>&nbsp;</i><![endif]--></span></a></div></div></td></tr></tbody></table></div>', '{ "root": { "type": "EmailLayout", "data": { "backdropColor": "#F5F5F5", "canvasColor": "#FFFFFF", "textColor": "#262626", "fontFamily": "MODERN_SANS", "childrenIds": [ "block-1737229372503" ] } }, "block-1737229372503": { "type": "Container", "data": { "style": { "padding": { "top": 24, "bottom": 24, "right": 32, "left": 32 } }, "props": { "childrenIds": [ "block-1737229386674", "block-1737229395871", "block-1737229536738", "block-1737229551815" ] } } }, "block-1737229386674": { "type": "Heading", "data": { "props": { "text": "Hi {{ firstname | there }}" }, "style": { "padding": { "top": 16, "bottom": 16, "right": 24, "left": 24 } } } }, "block-1737229395871": { "type": "Text", "data": { "style": { "fontWeight": "normal", "padding": { "top": 16, "bottom": 16, "right": 24, "left": 24 } }, "props": { "text": "We’re glad to have you with us at {{ pagename }}!" } } }, "block-1737229536738": { "type": "Text", "data": { "style": { "fontWeight": "normal", "padding": { "top": 16, "bottom": 16, "right": 24, "left": 24 } }, "props": { "text": "To finish subscribing to our emails, just click the button below. You can unsubscribe anytime if you change your mind." } } }, "block-1737229551815": { "type": "Button", "data": { "style": { "fontWeight": "bold", "textAlign": "center", "padding": { "top": 16, "bottom": 16, "right": 24, "left": 24 } }, "props": { "buttonBackgroundColor": "#4F46E5", "fullWidth": true, "text": "Subscribe!", "url": "{{ hostname }}/subscribe/optin" } } } }', 'Confirm your email address') ON CONFLICT DO NOTHING;

-- Table for flows (campaigns or automated sequences)
CREATE TABLE IF NOT EXISTS flows (
  id                  SERIAL PRIMARY KEY,
  name                TEXT NOT NULL,  -- Name of the flow
  description         TEXT,           -- Description of the flow
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for flow steps (sequence and details for each step in the flow)
CREATE TABLE IF NOT EXISTS flow_steps (
  id                  SERIAL PRIMARY KEY,
  flow_id             INT NOT NULL REFERENCES flows(id) ON DELETE CASCADE,
  mail_id             INT NOT NULL REFERENCES mails(id) ON DELETE CASCADE,
  step_number         INT NOT NULL,  -- Sequence of steps in the flow
  trigger_type        TEXT DEFAULT 'delay', -- open, linkclick, delay, etc.
  delay_minutes       INT NOT NULL DEFAULT 0, -- Delay from the previous step
  name                TEXT NOT NULL, -- Name of the step
  subject             TEXT NOT NULL, -- Email subject for this step
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for lists (grouping contacts for sending emails)
CREATE TABLE IF NOT EXISTS lists (
  id                  SERIAL PRIMARY KEY,
  name                TEXT NOT NULL,    -- Name of the list
  identifier          TEXT NOT NULL UNIQUE,  -- Unique identifier, e.g. welcome-list
  flow_ids            INT[],            -- Flows associated with the list
  description         TEXT,             -- Description of the list
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  uuid                UUID NOT NULL DEFAULT uuid_generate_v4()  -- Unique identifier
);
-- Default list
INSERT INTO lists (name, identifier, description) VALUES ('Default List', 'default', 'Default list for new users') ON CONFLICT DO NOTHING;

-- Table for contacts
CREATE TABLE IF NOT EXISTS contacts (
  id                  SERIAL PRIMARY KEY,
  name                VARCHAR(255),
  email               VARCHAR(255) UNIQUE NOT NULL,
  status              TEXT DEFAULT 'enabled',  -- enabled, disabled, etc.
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  requires_double_opt_in BOOLEAN DEFAULT TRUE,  -- Flag for double opt-in status
  double_opt_in_sent  BOOLEAN DEFAULT FALSE,  -- Has initial double opt-in email been sent?
  double_opt_in       BOOLEAN DEFAULT FALSE,  -- Flag for double opt-in status
  double_opt_in_data  TEXT, -- IP address, timestamp, etc.
  pending_lists       INT[], -- Pending lists to be signed up to until double_opt_in is complete
  bounced_at          TIMESTAMP, -- Timestamp when the email bounced
  complained_at       TIMESTAMP, -- Timestamp when the email was marked as spam
  meta                JSONB,          -- Additional metadata for the user
  uuid                UUID NOT NULL DEFAULT uuid_generate_v4()
);

-- Table for subscriptions (contacts signing up for lists)
CREATE TABLE IF NOT EXISTS subscriptions (
  id                  SERIAL PRIMARY KEY,
  user_id             INT NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  list_id             INT NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
  subscribed_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, list_id)
);

-- Table for pending emails (emails to be sent)
CREATE TABLE IF NOT EXISTS pending_emails (
  id                  SERIAL PRIMARY KEY,
  user_id             INT NOT NULL REFERENCES contacts(id),
  list_id             INT NULL REFERENCES lists(id),
  flow_id             INT NULL REFERENCES flows(id), -- NULL for manual sends
  flow_step_id        INT NULL REFERENCES flow_steps(id), -- Tied to a specific flow step
  mail_id             INT NULL REFERENCES mails(id),
  trigger_type        TEXT,
  scheduled_for       TIMESTAMP, -- NULL if send_immediately is TRUE, or NULL if we have another trigger
  status              TEXT DEFAULT 'pending', -- E.g., 'pending', 'scheduled', 'sent', 'failed'
  message_id          TEXT,  -- Store the message ID here
  sent_at             TIMESTAMP,
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for email opens (tracking opens for analytics)
CREATE TABLE IF NOT EXISTS email_opens (
  id                  SERIAL PRIMARY KEY,
  pending_email_id    INT NOT NULL REFERENCES pending_emails(id),
  user_id             INT NOT NULL REFERENCES contacts(id),
  opened_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  device_info         TEXT,
  ip_address          TEXT,
  message_id          TEXT
);

-- Table for email clicks (tracking clicks for analytics)
CREATE TABLE IF NOT EXISTS email_clicks (
  id                  SERIAL PRIMARY KEY,
  pending_email_id    INT NOT NULL REFERENCES pending_emails(id),
  user_id             INT NOT NULL REFERENCES contacts(id),
  clicked_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  device_info         TEXT,
  ip_address          TEXT,
  link_url            TEXT NOT NULL,
  message_id          TEXT
);

CREATE TABLE IF NOT EXISTS email_bounces (
  id                  SERIAL PRIMARY KEY,
  pending_email_id    INT NOT NULL REFERENCES pending_emails(id),
  user_id             INT NOT NULL REFERENCES contacts(id),
  bounced_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  bounce_type         TEXT,
  bounce_subtype      TEXT,
  diagnostic_code     TEXT,
  status              TEXT,
  message_id          TEXT
);

CREATE TABLE IF NOT EXISTS email_complaints (
  id                  SERIAL PRIMARY KEY,
  pending_email_id    INT NOT NULL REFERENCES pending_emails(id),
  user_id             INT NOT NULL REFERENCES contacts(id),
  complained_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  complaint_feedback  TEXT,
  message_id          TEXT
);


-- General settings
CREATE TABLE IF NOT EXISTS settings (
  id                  SERIAL PRIMARY KEY,
  page_name           TEXT NOT NULL,
  hostname            TEXT NOT NULL,
  optin_email         INT NOT NULL REFERENCES mails(id),
  logo_url            TEXT
);
INSERT INTO settings (page_name, hostname, optin_email) VALUES ('Nimsletter', 'https://nimsletter.com', 1) ON CONFLICT DO NOTHING;

-- Table for smtp
CREATE TABLE IF NOT EXISTS smtp_settings (
  id                  SERIAL PRIMARY KEY,
  smtp_host           TEXT NOT NULL,
  smtp_port           INT NOT NULL,
  smtp_user           TEXT NOT NULL,
  smtp_password       TEXT NOT NULL,
  smtp_fromemail      TEXT NOT NULL,
  smtp_fromname       TEXT NOT NULL,
  smtp_mailspersecond INT DEFAULT 1,
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO smtp_settings (smtp_host, smtp_port, smtp_user, smtp_password, smtp_fromemail, smtp_fromname) VALUES ('email-smtp.eu-west-1.amazonaws.com', 465, 'AKIA', 'EXAMPLE', '', '') ON CONFLICT DO NOTHING;

-- Table for API keys
CREATE TABLE IF NOT EXISTS api_keys (
  id                  SERIAL PRIMARY KEY,
  key                 UUID NOT NULL DEFAULT uuid_generate_v4(),
  ident               UUID NOT NULL DEFAULT uuid_generate_v4(),
  name                TEXT,
  count               INT DEFAULT 0,
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for webhooks
CREATE TABLE IF NOT EXISTS webhooks (
  id                  SERIAL PRIMARY KEY,
  name                TEXT,
  url                 TEXT NOT NULL,
  headers             JSON,
  event               TEXT NOT NULL,  -- Event type (e.g., email_opened, email_clicked)
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User table for authentication
CREATE TABLE IF NOT EXISTS users (
  id                  SERIAL PRIMARY KEY,
  email               TEXT NOT NULL UNIQUE,
  password            TEXT NOT NULL,
  salt                TEXT NOT NULL,
  yubikey_public      TEXT,
  yubikey_clientid    TEXT,
  twofa_app_secret    TEXT,
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (email, password, salt) VALUES ('admin@nimsletter.com', 'admin', 'salt') ON CONFLICT DO NOTHING;

-- Session table for storing user sessions
CREATE TABLE IF NOT EXISTS sessions (
  id                  SERIAL PRIMARY KEY,
  user_id             INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token               TEXT NOT NULL,
  expires_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- - INTERVAL '7 days',
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_pending_emails_scheduled_for ON pending_emails (scheduled_for);
CREATE INDEX IF NOT EXISTS idx_email_opens_user_id ON email_opens (user_id);
CREATE INDEX IF NOT EXISTS idx_email_clicks_user_id ON email_clicks (user_id);
