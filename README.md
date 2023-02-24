# pgsnap

With pgsnap, you can easily create a snapshot of a PostgreSQL database and transfer it to a S3-compatible storage, all while ensuring that old files are automatically deleted.

## Features

- 🗄 Creates a snapshot from a PostgreSQL database.
- ☁ Sends the snapshot to a S3-compatible storage bucket ([S3](https://aws.amazon.com/de/s3/), [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces), [MinIO](https://min.io/), etc.)
- 🧹 Retention Policy: Removes old snapshots from the bucket.

## Configuration

The easiest way to run `pgsnap` is via our provided container image.

```sh
docker pull docker pull ghcr.io/openformation/pgsnap:latest
```

`pgsnap` gets configured via the following environment variables.

| **Name**          | **Description**                                                                                     | **Required** | **Default**      |
| ----------------- | --------------------------------------------------------------------------------------------------- | ------------ | ---------------- |
| DATABASE_NAME     | The name of the                                                                                     | Yes          |                  |
| DATABASE_URL      | The PostgreSQL DSN                                                                                  | Yes          |                  |
| S3_BUCKET_NAME    | The name of the storage bucket.                                                                     | Yes          |                  |
| S3_ACCESS_KEY     | The access key for accessing the storage bucket.                                                    | Yes          |                  |
| S3_SECRET_KEY     | The secret key for accessing the storage bucket.                                                    | Yes          |                  |
| S3_HOST           | The API host of the S3-compatible storage service.                                                  | No           | `s3.amazonaws.com` |
| S3_REGION         | The region of the S3-compatible storage engine.                                                     | No           | `eu-central-1`     |
| SENTRY_DSN        | Sentry DSN. Required when you want to use [Cron Monitoring](https://docs.sentry.io/product/crons/). | No           |                  |
| SENTRY_MONITOR_ID | The Sentry Cron Monitoring ID.                                                                                                    | No           |                  |
| SENTRY_ORGANIZATION | The name of your Sentry organization.                                                                                                    | No           |                  |

## Utilizing Kubernetes CronJob

`pgsnap` can be easily run as a [Kubernetes CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/). The following example runs `pgsnap` every night at 2am (timezone: `Europe/Berlin`). The environment variables are stored in a [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/):

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pgsnap
spec:
  schedule: 0 2 * * *
  timeZone: Europe/Berlin # Beta in Kubernetes 1.25
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: pgsnap
            image: ghcr.io/openformation/pgsnap:0.1.2
            envFrom:
            - secretRef:
                name: pgsnap-env-variables
```

## License
Copyright (c) 2023 [Open Formation GmbH](https://openformation.io)

Licensed under the [AGPL](https://www.gnu.org/licenses/agpl-3.0.en.html) license.