resource "aws_s3_bucket" "dmr_bucket_logs" {
  bucket = "${data.aws_caller_identity.current.account_id}-dmr-bucket-logs"
  acl    = "log-delivery-write"
}