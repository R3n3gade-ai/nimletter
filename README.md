
# Nimletter

**Self-hosted newsletter, drip and transactional email system**.

Nimletter is built with the purpose to replace the simple functionalities found
in Mailchimp, Mailerlite, Sendgrid and others. Let users subscribe and
automatically start flows, or just send out your weekly newsletter.


![Nimletter Logo](assets/images/nimletter.png)

* BYOD SMTP server
* Drag and Drop email builder
* Variables / Attributes in mails
* Drip campaigns
* Transactional emails
* Bounce, complaint, open and click tracking
* Subscribe and double opt-in
* Webhook for Zapier, etc.
* API with simple endpoints
* Yubikey OTP security
* Customizable templates
* Customizable settings

## Dashboard

![dashboard](assets/screenshots/dashboard.png)

## Contacts

![contacts](assets/screenshots/contacts.png)

## Mail preview

![mail preview](assets/screenshots/mailpreview.png)

## Mail builder

![mailbuilder](assets/screenshots/mailbuilder.png)

## Flows / Drips

![flows](assets/screenshots/flows.png)

## Settings

![settings](assets/screenshots/settings.png)


**Reason for development**:

I needed a simple system to design and send out my newsletter, but also sending drip
campaigns with tips and tricks when new users signed up. Besides those two
core features I also needed to keep track of bounces and complaints to keep my
domain reputation.

That was doable with the big players, but I wanted to have full control over
the system and the user data (GDPR and syncing to my SaaS).
So I ended up with something like Mailerlite for campaigns and Google
templates for newsletters...


# Startup

## Start the database
Create the database for starters:
```
psql -U postgres -c "CREATE USER nimletter WITH PASSWORD 'nimletter';"
psql -U postgres -c "CREATE DATABASE nimletter_db OWNER nimletter;"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE nimletter_db TO nimletter;"
```

### Option A) Run the container
__(Only database setup is needed)__
```
podman run \
  --name nimletter \
  --network host \
  --rm \
  -e PG_HOST=localhost \
  -e PG_USER=nimletter \
  -e PG_PASSWORD=nimletter \
  -e PG_DATABASE=nimletter_db \
  -e PG_WORKERS=3 \
  -e SMTP_HOST=smtp_host \
  -e SMTP_PORT=465 \
  -e SMTP_USER=smtp_username \
  -e SMTP_PASSWORD=smtp_password \
  -e SMTP_FROMEMAIL=admin@nimletter.com \
  -e SMTP_FROMNAME=ADMIN \
  -e SMTP_MAILSPERSECOND=1 \
  -e SNS_WEBHOOK_SECRET=secret \
  ghcr.io/thomastjdev/nimletter:latest
```

### Option B) Compile and run
__(See environment setup below for configuration)__

```
$ git clone
$ cd nimletter
$ nim c -d:release nimletter
# First run creates the database and inserts test data
$ ./nimletter --DEV_RESET
$ ./nimletter
```

### Option C) Systemd service file
```
$ cp nimletter.service ~/.config/systemd/user/
$ podman pull ghcr.io/thomastjdev/nimletter:latest
$ systemctl --user daemon-reload
$ systemctl --user start nimletter
$ systemctl --user status nimletter
$ systemctl --user enable nimletter
```

### Option D) Docker / Podman compose
```
$ docker compose -f nimletter-compose.yaml up --detach
# or
$ podman compose -f nimletter-compose.yaml up --detach
```

## Default credentials

The admin credentials defaults to:
```
email: admin@nimletter.com
password: dripit
```

You can override these by using environment variables:
```
-e ADMIN_EMAIL=admin@nimletter.com
-e ADMIN_PASSWORD=dripit
```

And within the system you can customize the username and password. The
password is hashed using salt and bcrypt, and you can even enable Yubikey OTP.


# SMTP

Nimletter is optimized for AWS SES, but can be used with any SMTP server. The
core part for managing bounces, complaints and deliveries are done by the
webhook endpoint. The formats can be seen in the `tests` folder.

If you are using AWS just set up a SMTP Configuration, add relevant events,
attach to a SNS topic and point the webhook to the Nimletter endpoint.

__(The SNS_WEBHOOK_SECRET can also be set inside the settings page)__
```
/webhook/incoming/sns/" & getEnv("SNS_WEBHOOK_SECRET", "secret")
```


# Environment variables
The values are customizable within the system and will be saved to the database.

**Database**
```
export PG_HOST=localhost
export PG_USER=nimletter
export PG_PASSWORD=nimletter
export PG_DATABASE=nimletter_db
export PG_WORKERS=3
```

**SMTP**
```
export SMTP_HOST=smtp_host
export SMTP_PORT=465
export SMTP_USER=smtp_username
export SMTP_PASSWORD=smtp_password
export SMTP_FROMEMAIL=admin@nimletter.com
export SMTP_FROMNAME=
export SMTP_MAILSPERSECOND=1
```

**SNS SECRET**
```
export SNS_WEBHOOK_SECRET=secret
```

**GEO**
__(Only relevant for binary)__
```
export GEOIP_PATH=/usr/share/GeoIP/GeoIP.dat
```



# How to setup the postgres database
```
-- Step 1: Connect to PostgreSQL as a superuser
\c postgres;

-- Step 2: Create the user
CREATE USER nimletter WITH PASSWORD 'nimletter';

-- Step 3: Create the database
CREATE DATABASE nimletter_db OWNER nimletter;

-- Step 4: Grant privileges to the user on the database
GRANT ALL PRIVILEGES ON DATABASE nimletter_db TO nimletter;
```

or

```
psql -U postgres -c "CREATE USER nimletter WITH PASSWORD 'nimletter';"
psql -U postgres -c "CREATE DATABASE nimletter_db OWNER nimletter;"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE nimletter_db TO nimletter;"
```


# Icons

https://heroicons.com/


#  Libraries

* EmailbuilderJS by usewayfont
* Tabulator by olifolkerd


# Next

* Valkey (Redis) as caching
* Backup schedule checking
* SQLite support
