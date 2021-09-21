resource "aws_sqs_queue" "dmr_queue" {
  name                        = "dmr-queue"
  delay_seconds               = 1
  max_message_size            = 2048
  message_retention_seconds   = 600
  visibility_timeout_seconds  = 900

  tags = {
    Name = "dmr-queue"
  }
}