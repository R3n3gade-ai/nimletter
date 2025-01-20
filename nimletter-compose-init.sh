#!/bin/bash
set -e

# Use environment variables directly
DB_NAME=${PG_DATABASE:-nimletter_db}
DB_USER=${PG_USER:-nimletter}
DB_PASSWORD=${PG_PASSWORD:-nimletter}

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create the application user if it doesn't exist
    CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

    -- Create the database if it doesn't exist
    CREATE DATABASE $DB_NAME OWNER $DB_USER;

    -- Grant all privileges on the database to the application user
    GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOSQL
