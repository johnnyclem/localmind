# S3 Cloud Sync

LocalMind encrypts sync state and attachments on the device before uploading
them. The passphrase is never uploaded. The bucket operator can still observe
object sizes, access times, and the configured object prefix.

The configured credentials need `GetObject`, `PutObject`, and `DeleteObject`
for the selected prefix. A minimal AWS policy is:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::YOUR_BUCKET/YOUR_PREFIX/*"
    }
  ]
}
```

Use path-style addressing for MinIO and providers that do not support bucket
subdomains. HTTPS is recommended. HTTP is available only as an explicit opt-in
for trusted local-network servers. The server must return ETags and support
conditional `If-Match` and `If-None-Match` writes.

Sync runs while LocalMind is in the foreground: on launch, on resume, and
shortly after local data changes. Disconnecting clears credentials and key
material from the device but does not delete remote objects. There is no
passphrase recovery; use a new prefix if the passphrase is lost.
