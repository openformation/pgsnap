FROM alpine:3.17.2

LABEL org.opencontainers.image.source "https://github.com/openformation/pgsnap"
LABEL org.opencontainers.image.description "pgsnap creates PostgreSQL snapshot and transfers it to a S3-compatible storage bucket"
LABEL org.opencontainers.image.authors="Open Formation GmbH"

RUN apk add --no-cache postgresql-client s3cmd jq curl coreutils
RUN adduser -D pgsnap

USER pgsnap

ADD --chown=pgsnap:pgsnap pgsnap.sh /app/pgsnap.sh

WORKDIR /app

ENTRYPOINT ["./pgsnap.sh"]
