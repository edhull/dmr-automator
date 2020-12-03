resource "aws_s3_bucket" "dmr_clamav_bucket" {
  bucket = "${data.aws_caller_identity.current.account_id}-dmr-clamav"
  acl    = "private"
}

resource "aws_s3_bucket_policy" "dmr_clamav_bucket_policy" {
  bucket = aws_s3_bucket.dmr_clamav_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "AllowClamAVUpdates",
  "Statement": [
      {
          "Effect": "Allow",
          "Principal": {
            "AWS": [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.dmr_clamav_scanner.name}"
            ]
          },
          "Action": [
              "s3:GetObject",
              "s3:GetObjectTagging"
          ],
          "Resource": ["arn:aws:s3:::${aws_s3_bucket.dmr_clamav_bucket.id}/*"]
      },
      {
          "Effect": "Allow",
          "Principal": {
            "AWS": [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.dmr_clamav_updater.name}"
            ]
          },
          "Action": [
              "s3:PutObject",
              "s3:PutObjectTagging"
          ],
          "Resource": ["arn:aws:s3:::${aws_s3_bucket.dmr_clamav_bucket.id}/*"]
      }
   ]
}
POLICY
}