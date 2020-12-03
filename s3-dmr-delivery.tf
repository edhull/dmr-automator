resource "aws_s3_bucket" "dmr_delivery_bucket" {
  bucket = "${data.aws_caller_identity.current.account_id}-dmr-delivery"
  acl    = "private"

  logging {
    target_bucket = aws_s3_bucket.dmr_bucket_logs.id
    target_prefix = "log/dmr-delivery/"
  }

}

resource "aws_s3_bucket_policy" "dmr_delivery_bucket_policy" {
  bucket = aws_s3_bucket.dmr_delivery_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "allow_dmr_initiator_write",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.dmr_clamav_scanner.id}"
        ]
      },
      "Action": [
          "s3:PutObject",
          "s3:PutObjectTagging"
      ],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.dmr_delivery_bucket.id}/*"]
    },
    {
      "Effect": "Allow",
      "Principal": {
          "AWS": [
             "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
      },
      "Action": [
          "s3:GetObject",
          "s3:GetObjectTagging"
      ],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.dmr_delivery_bucket.id}/*"],
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/dmr-av-status": "CLEAN"
        }
      }
    }
  ]
}
POLICY
}