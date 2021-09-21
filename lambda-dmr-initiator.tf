variable dmr_initiator {
  description = "Name for the DMR Initiator. This will be used to name the Lambda and IAM Role"
  default = "dmr-initiator"
}

# Generate a placeholder VirusTotal API key to be updated manually
resource "aws_ssm_parameter" "virustotal_apikey" {
  name              = "/dmr/virustotal"
  type              = "SecureString"
  key_id            = CHANGEME
  value             = "PLACEHOLDER_REPLACEBYHAND"
  overwrite         = false
  lifecycle {
    ignore_changes = [value, key_id]
  }
}

# Lookup value post creation
data "aws_ssm_parameter" "virustotal_apikey" {
  name              = "/dmr/virustotal"
  depends_on        = [aws_ssm_parameter.virustotal_apikey]
}

resource "aws_lambda_alias" "dmr_initiator" {
  name              = var.dmr_initiator
  description       = "Handle DMR requests"
  function_name     = aws_lambda_function.dmr_initiator.function_name
  function_version  = "$LATEST"
}

resource "aws_lambda_function" "dmr_initiator" {
  filename          = "functions/dmr-initiator.zip"
  function_name     = var.dmr_initiator
  role              = aws_iam_role.dmr_initiator.arn
  handler           = "dmr_initiator.handler"
  runtime           = "python3.7"
  source_code_hash  = filebase64sha256("functions/dmr-initiator.zip")
  timeout           = "900"
  memory_size       = "1024"
  environment {
    variables      = {
      LOG_LEVEL           = var.lambda_loglevel
      VT_API_KEY          = data.aws_ssm_parameter.virustotal_apikey.value
      S3_STAGING_BUCKET   = aws_s3_bucket.dmr_staging_bucket.id
      SEND_JIRA_COMMENT   = var.create_jira
      DMR_JIRA_ARN        = var.create_jira ? aws_lambda_function.dmr_jira[0].arn : ""
    }
  }
}

resource "aws_lambda_event_source_mapping" "dmr_initiator" {
  batch_size       = 1
  enabled          = true
  event_source_arn = aws_sqs_queue.dmr_queue.arn
  function_name    = aws_lambda_function.dmr_initiator.arn
  depends_on = [
    aws_lambda_function.dmr_initiator,
    aws_iam_policy.iam_dmr_initiator,
    aws_sqs_queue.dmr_queue
  ]
}

resource "aws_cloudwatch_log_group" "dmr_initiator" {
  name              = "/aws/lambda/${aws_lambda_function.dmr_initiator.function_name}"
  retention_in_days = "14"
}

resource "aws_iam_role" "dmr_initiator" {
  name              = var.dmr_initiator

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": 
        ["lambda.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name          = var.dmr_initiator
  }
}

resource "aws_iam_policy" "iam_dmr_initiator" {
  name            = "iam-${var.dmr_initiator}"
  path            = "/"
  description     = ""

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:PutObject",
            "s3:PutObjectTagging"
        ],
        "Resource": "arn:aws:s3:::${aws_s3_bucket.dmr_staging_bucket.id}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dmr_initiator" {
  role              = aws_iam_role.dmr_initiator.name
  policy_arn        = aws_iam_policy.iam_dmr_initiator.arn
}

resource "aws_iam_policy" "iam_dmr_initiator_invoke_jira" {
  count           = var.create_jira ? 1 : 0
  name            = "iam-${var.dmr_initiator}-invoke-dmr-jira"
  path            = "/"
  description     = ""

  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"InvokeDMRJira",
         "Effect":"Allow",
         "Action":[
            "lambda:InvokeFunction",
            "lambda:InvokeAsync"
         ],
         "Resource":"${aws_lambda_function.dmr_jira[0].arn}"
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dmr_initiator_invoke_jira" {
  count                 = var.create_jira ? 1 : 0
  role                  = aws_iam_role.dmr_initiator.name
  policy_arn            = aws_iam_policy.iam_dmr_initiator_invoke_jira[0].arn
}
