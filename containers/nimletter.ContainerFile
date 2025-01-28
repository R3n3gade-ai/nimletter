FROM docker.io/library/ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive

RUN groupadd nimgroup \
    && useradd -m nimmer -d /home/nimmer -s /bin/bash \
    && usermod -a -G nimgroup,sudo nimmer \
    && mkdir -p /home/nimmer/config \
    && mkdir -p /home/nimmer/public-dist \
    && mkdir -p /home/nimmer/storage \
    && chown -R nimmer:nimgroup /home/nimmer \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      libpq-dev \
      libpcre3-dev \
      libgeoip1 geoip-bin geoip-database

WORKDIR /home/nimmer

COPY src/database/db_schema.sql /home/nimmer/db_schema.sql

COPY nimletter /home/nimmer/nimletter

CMD ["/home/nimmer/nimletter", "--CREATE_DATABASE_AND_INSERT_TESTDATA"]

#podman build -f containers/nimletter.ContainerFile . -t nimletter
#podman tag nimletter <repo>/nimletter:latest
#podman push <repo>/nimletter:latest
