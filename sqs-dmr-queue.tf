resource "aws_sqs_queue" "dmr_queue" {
  name                        = "dmr-queue"
  delay_seconds               = 10
  max_message_size            = 2048
  message_retention_seconds   = 86400
  visibility_timeout_seconds  = 600

  tags = {
    Name = "dmr-queue"
  }
}