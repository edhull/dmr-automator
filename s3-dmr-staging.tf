resource "aws_s3_bucket_notification" "dmr_clamav_bucket_notification" {
  bucket = aws_s3_bucket.dmr_staging_bucket.id

  lambda_function {
    id                  = "trigger-clamav-scan"   
    lambda_function_arn = aws_lambda_function.dmr_clamav_scanner.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.dmr_clamav_trigger_scan_event]
}

resource "aws_s3_bucket" "dmr_staging_bucket" {
  bucket = "${data.aws_caller_identity.current.account_id}-dmr-staging"
  acl    = "private"

  logging {
    target_bucket = aws_s3_bucket.dmr_bucket_logs.id
    target_prefix = "log/dmr-staging/"
  }

  lifecycle_rule {
    prefix  = "/"
    enabled = true

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_policy" "dmr_staging_bucket_policy" {
  bucket = aws_s3_bucket.dmr_staging_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "allow_dmr_initiator_write",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["s3:GetObject", "s3:PutObjectTagging"],
      "Principal": "*",
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*"],
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/dmr-av-status": "INFECTED"
        }
      }
    },
    {
      "Effect": "Deny",
      "Action": ["s3:GetObject", "s3:PutObjectTagging"],
      "Principal": "*",
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*"],
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/dmr-av-status": "INFECTED"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.dmr_initiator.id}"
      },
      "Action": [
          "s3:PutObject",
          "s3:PutObjectTagging"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.dmr_clamav_scanner.id}"
      },
      "Action": [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.dmr_clamav_scanner.id}"
      },
      "Action": [
          "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}"
    }
  ]
}
POLICY
}