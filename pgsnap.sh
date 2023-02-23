#!/usr/bin/env sh

set -e

#
# Script for creating snapshots from a PostgreSQL database.
#
# The script performs a `pg_dump` and creates a whole database
# snapshot. Afterwards, this snapshot gets uploaded to a
# S3-compatible storage bucket (e.g. S3, Digital Ocean Spaces, etc.)
#
# When done, the script makes sure to delete oldest snapshot (which is 14 days old).
#
#
# Author:
#   André König <andre.koenig@openformation.io>
#

if [ -n "$SENTRY_DSN" ]; then
  if [ -z "$SENTRY_MONITOR_ID" ]; then
    echo "The environment variable SENTRY_MONITOR_ID is not defined. Please make sure to add it in order to monitor this script."

    exit 1
  fi

  if [ -z "$SENTRY_ORGANIZATION" ]; then
    echo "The environment variable SENTRY_ORGANIZATION is not defined. Please make sure to add it in order to monitor this script."

    exit 1
  fi
fi

if [ -z "$DATABASE_NAME" ]; then
  echo "The environment variable DATABASE_NAME is not defined."

  exit 1
fi

if [ -z "$DATABASE_URL" ]; then
  echo "The environment variable DATABASE_URL is not defined."

  exit 1
fi

if [ -z "$S3_BUCKET_NAME" ]; then
  echo "The environment variable S3_S3_BUCKET_NAME is not defined."

  exit 1
fi

if [ -z "$S3_ACCESS_KEY" ]; then
  echo "The environment variable S3_ACCESS_KEY is not defined."

  exit 1
fi


if [ -z "$S3_SECRET_KEY" ]; then
  echo "The environment variable S3_SECRET_KEY is not defined."

  exit 1
fi

S3_BUCKET_HOST="${S3_HOST:-s3.amazonaws.com}"
S3_HOST_REGION="${S3_REGION:-eu-central-1}"

# Sentry Check-In
start=$(date +%s%3N)

if [ -n "$SENTRY_MONITOR_ID" ]; then
  sentry_checkin_id=$(curl -s -X POST \
    "https://sentry.io/api/0/organizations/$SENTRY_ORGANIZATION/monitors/$SENTRY_MONITOR_ID/checkins/" \
    --header "Authorization: DSN $SENTRY_DSN" \
    --header "Content-Type: application/json" \
    --data-raw '{"status": "in_progress"}' | jq --raw-output '.id')
fi

timestamp=$(date +%Y-%m-%d)

echo "About to create a snapshot of the database '$DATABASE_NAME'"

pg_dump -d "$DATABASE_URL" -F p > $timestamp.sql

echo "Transferring snapshot $timestamp.sql to bucket '$S3_BUCKET_NAME'"

s3cmd put \
  --access_key=$S3_ACCESS_KEY \
  --secret_key=$S3_SECRET_KEY \
  --host $S3_BUCKET_HOST \
  --host-bucket="%(bucket)s.$S3_BUCKET_HOST" \
  --check-hostname \
  --check-certificate \
  --region=$S3_HOST_REGION \
  $timestamp.sql s3://$S3_BUCKET_NAME/databases/$DATABASE_NAME/$timestamp.sql

rm $timestamp.sql
echo "Deleting snapshot from 14 days ago"

s3cmd del \
  --access_key=$S3_ACCESS_KEY \
  --secret_key=$S3_SECRET_KEY \
  --host $S3_BUCKET_HOST \
  --host-bucket="%(bucket)s.$S3_BUCKET_HOST" \
  --check-hostname \
  --check-certificate \
  --region=$S3_HOST_REGION \
  s3://$S3_BUCKET_NAME/databases/$DATABASE_NAME/ --recursive --exclude="" --include="$(date -d "14 days ago" "+%Y-%m-%d").sql"

echo "Done"

end=$(date +%s%3N)
duration=$((end-start))

# Sentry Check-Out
if [ -n "$SENTRY_MONITOR_ID" ]; then
  curl -s -o /dev/null -X PUT \
      "https://sentry.io/api/0/organizations/$SENTRY_ORGANIZATION/monitors/$SENTRY_MONITOR_ID/checkins/$sentry_checkin_id/" \
      --header "Authorization: DSN $SENTRY_DSN" \
      --header "Content-Type: application/json" \
      --data-raw "{\"status\": \"ok\", \"duration\": $duration}"
fi
